//! Throwaway spikes for OPN-1 and OPN-21. Each public function is one browser-callable
//! experiment; nothing here persists, derives, or journals anything.

use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
fn start() {
    console_error_panic_hook::set_once();
}

/// A WebSocket to the bridge, as a tokio byte stream (`ws_stream_wasm` + `tokio_io`).
async fn bridge(ws_url: String) -> Result<impl tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin, String> {
    let (_meta, ws) = ws_stream_wasm::WsMeta::connect(&ws_url, None)
        .await
        .map_err(|e| format!("websocket: {e}"))?;
    Ok(ws.into_io())
}

fn js(e: impl std::fmt::Display) -> JsValue {
    JsValue::from_str(&e.to_string())
}

// ---------------------------------------------------------------------------------------------
// OPN-1 — SSH with host-key pinning
// ---------------------------------------------------------------------------------------------
#[cfg(feature = "ssh")]
mod ssh {
    use russh::client;
    use russh::keys::ssh_key::private::{Ed25519Keypair, KeypairData};
    use russh::keys::{HashAlg, PrivateKey, PrivateKeyWithHashAlg, PublicKeyOrCertificate};
    use russh::ChannelMsg;
    use std::sync::{Arc, Mutex};

    /// The pin. `presented` is filled by the SSH layer so a refusal can be reported as
    /// `Changed { old, new }` rather than a bare boolean (SEC-11, CHN-R4).
    pub struct Pin {
        expected: String,
        presented: Arc<Mutex<Option<String>>>,
    }

    impl client::Handler for Pin {
        type Error = russh::Error;

        async fn check_server_key(&mut self, key: &PublicKeyOrCertificate) -> Result<bool, Self::Error> {
            let fp = match key {
                PublicKeyOrCertificate::PublicKey { key, .. } => key.fingerprint(HashAlg::Sha256).to_string(),
                PublicKeyOrCertificate::Certificate(c) => c.public_key().fingerprint(HashAlg::Sha256).to_string(),
            };
            *self.presented.lock().unwrap() = Some(fp.clone());
            // This return value is the halt: `false` makes russh abort the key exchange with
            // `Error::UnknownKey` before authentication. No UI code is consulted.
            Ok(fp == self.expected)
        }
    }

    /// ed25519 from a 32-byte secret — the shape a BIP-32 derivation (STA-22) will hand us later.
    pub fn key_from_seed(seed_hex: &str) -> Result<PrivateKey, String> {
        let bytes = hex::decode(seed_hex).map_err(|e| format!("seed hex: {e}"))?;
        let seed: [u8; 32] = bytes.try_into().map_err(|_| "seed must be 32 bytes".to_string())?;
        PrivateKey::new(KeypairData::Ed25519(Ed25519Keypair::from_seed(&seed)), "tau-web-spike")
            .map_err(|e| format!("key: {e}"))
    }

    pub async fn run(ws_url: &str, user: &str, seed_hex: &str, pinned_fp: &str, command: &str) -> Result<String, String> {
        let key = key_from_seed(seed_hex)?;
        let stream = super::bridge(ws_url.to_string()).await?;
        let presented = Arc::new(Mutex::new(None));
        let handler = Pin { expected: pinned_fp.to_string(), presented: presented.clone() };
        // Default config: no keepalive / inactivity timeout, so russh never touches tokio timers
        // (there is no tokio runtime in the browser; russh_util spawns onto wasm-bindgen-futures).
        let config = Arc::new(client::Config::default());

        let mut handle = match client::connect_stream(config, stream, handler).await {
            Ok(h) => h,
            Err(e) => {
                let got = presented.lock().unwrap().clone();
                return Err(match got {
                    Some(new) if new != pinned_fp => format!(
                        "REFUSED by SSH layer ({e}): host key changed\n  pinned:    {pinned_fp}\n  presented: {new}"
                    ),
                    _ => format!("connect: {e}"),
                });
            }
        };
        let got = presented.lock().unwrap().clone().unwrap_or_default();

        let auth = handle
            .authenticate_publickey(user, PrivateKeyWithHashAlg::new(Arc::new(key), None))
            .await
            .map_err(|e| format!("auth: {e}"))?;
        if !auth.success() {
            return Err(format!("auth refused: {auth:?}"));
        }

        let mut ch = handle.channel_open_session().await.map_err(|e| format!("channel: {e}"))?;
        ch.exec(true, command).await.map_err(|e| format!("exec: {e}"))?;
        let mut out = Vec::new();
        let mut status = None;
        while let Some(msg) = ch.wait().await {
            match msg {
                ChannelMsg::Data { data } => out.extend_from_slice(&data),
                ChannelMsg::ExitStatus { exit_status } => status = Some(exit_status),
                ChannelMsg::Eof | ChannelMsg::Close => break,
                _ => {}
            }
        }
        Ok(format!(
            "host key matched pin {got}\nauthenticated as {user} with in-page ed25519 key\n$ {command}\n{}\n[exit {status:?}]",
            String::from_utf8_lossy(&out).trim_end()
        ))
    }
}

/// OpenSSH-format public key for the seed, so the operator can register it before connecting.
#[cfg(feature = "ssh")]
#[wasm_bindgen]
pub fn ssh_pubkey(seed_hex: &str) -> Result<String, JsValue> {
    let key = ssh::key_from_seed(seed_hex).map_err(js)?;
    key.public_key().to_openssh().map_err(js)
}

#[cfg(feature = "ssh")]
#[wasm_bindgen]
pub async fn ssh_run(ws_url: &str, user: &str, seed_hex: &str, pinned_fp: &str, command: &str) -> Result<String, JsValue> {
    ssh::run(ws_url, user, seed_hex, pinned_fp, command).await.map_err(js)
}

// ---------------------------------------------------------------------------------------------
// OPN-21 — pinned TLS through the bridge
// ---------------------------------------------------------------------------------------------
#[cfg(feature = "tls")]
mod tls {
    use rustls::pki_types::{ServerName, UnixTime};
    use rustls::time_provider::TimeProvider;
    use rustls::{CertificateError, ClientConfig, RootCertStore};
    use std::sync::Arc;
    use std::time::Duration;
    use tokio::io::{AsyncReadExt, AsyncWriteExt};

    /// The pin: Robot's issuing authority, captured 2026-09-07 from robot-ws.your-server.de.
    /// Thawte TLS RSA CA G1 (DigiCert), valid to 2027-11-02. Rotation = this file changes.
    pub const ROBOT_ISSUER_PEM: &str = include_str!("robot-issuer.pem");

    /// `SystemTime::now()` panics on wasm32-unknown-unknown, so rustls gets the JS clock.
    #[derive(Debug)]
    struct JsClock;
    impl TimeProvider for JsClock {
        fn current_time(&self) -> Option<UnixTime> {
            Some(UnixTime::since_unix_epoch(Duration::from_millis(js_sys::Date::now() as u64)))
        }
    }

    fn config(pin_pem: &str) -> Result<Arc<ClientConfig>, String> {
        // The whole pin: a trust store holding exactly one certificate — the issuing CA — and
        // nothing else. webpki then does full chain, name and validity checks against it.
        let mut roots = RootCertStore::empty();
        for cert in rustls_pemfile::certs(&mut pin_pem.as_bytes()) {
            roots.add(cert.map_err(|e| format!("pin pem: {e}"))?).map_err(|e| format!("pin: {e}"))?;
        }
        if roots.is_empty() {
            return Err("pin pem holds no certificate".into());
        }
        let provider = Arc::new(rustls::crypto::ring::default_provider());
        let cfg = ClientConfig::builder_with_details(provider, Arc::new(JsClock))
            .with_safe_default_protocol_versions()
            .map_err(|e| format!("versions: {e}"))?
            .with_root_certificates(roots)
            .with_no_client_auth();
        Ok(Arc::new(cfg))
    }

    pub async fn get(ws_url: &str, host: &str, path: &str, basic_b64: &str, pin_pem: &str) -> Result<String, String> {
        let cfg = config(pin_pem)?;
        let tcp = super::bridge(ws_url.to_string()).await?;
        let name = ServerName::try_from(host.to_string()).map_err(|e| format!("server name: {e}"))?;
        let mut tls = tokio_rustls::TlsConnector::from(cfg).connect(name, tcp).await.map_err(|e| {
            // CNF-64: a pin that no longer matches is named as such, not as a network error.
            match e.get_ref().and_then(|i| i.downcast_ref::<rustls::Error>()) {
                Some(rustls::Error::InvalidCertificate(CertificateError::UnknownIssuer)) => format!(
                    "REFUSED by TLS layer before any bytes were sent: certificate is not issued by the pinned authority (rotation, or the wrong host) — {e}"
                ),
                _ => format!("tls handshake: {e}"),
            }
        })?;
        let (_, conn) = tls.get_ref();
        let proto = conn.protocol_version().map(|v| format!("{v:?}")).unwrap_or_default();
        let suite = conn.negotiated_cipher_suite().map(|s| format!("{:?}", s.suite())).unwrap_or_default();

        let auth = if basic_b64.is_empty() { String::new() } else { format!("Authorization: Basic {basic_b64}\r\n") };
        let req = format!("GET {path} HTTP/1.1\r\nHost: {host}\r\nUser-Agent: tau-web-spike\r\nAccept: application/json\r\n{auth}Connection: close\r\n\r\n");
        tls.write_all(req.as_bytes()).await.map_err(|e| format!("write: {e}"))?;
        let mut body = Vec::new();
        // Some servers close without close_notify; keep what arrived before the EOF error.
        let _ = tls.read_to_end(&mut body).await;
        Ok(format!("pinned issuer accepted; {proto} {suite}\n\n{}", String::from_utf8_lossy(&body)))
    }
}

#[cfg(feature = "tls")]
#[wasm_bindgen]
pub fn robot_issuer_pem() -> String {
    tls::ROBOT_ISSUER_PEM.to_string()
}

#[cfg(feature = "tls")]
#[wasm_bindgen]
pub async fn tls_get(ws_url: &str, host: &str, path: &str, basic_b64: &str) -> Result<String, JsValue> {
    tls::get(ws_url, host, path, basic_b64, tls::ROBOT_ISSUER_PEM).await.map_err(js)
}
