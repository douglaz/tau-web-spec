# /// script
# requires-python = ">=3.11"
# dependencies = ["bip-utils==2.9.3", "cryptography==46.0.3"]
# ///
"""Check public v1 fixtures with stdlib/OpenSSL and an independent BIP implementation.

Run: uv run docs/design/check-credential-vectors.py
--write intentionally regenerates the public fixture after a reviewed format change.
"""
import hashlib
import hmac
import json
import sys
from pathlib import Path

from bip_utils import Bip32Secp256k1, Bip39SeedGenerator, Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec, ed25519

ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
MNEMONIC = "abandon " * 11 + "about"


def derive(seed, path):
    material = hmac.digest(b"Bitcoin seed", seed, "sha512")
    scalar, chain = int.from_bytes(material[:32], "big"), material[32:]
    assert 0 < scalar < ORDER
    for index in path:
        assert 0 <= index < 2**31
        data = b"\0" + scalar.to_bytes(32, "big") + (index + 2**31).to_bytes(4, "big")
        material = hmac.digest(chain, data, "sha512")
        offset = int.from_bytes(material[:32], "big")
        assert offset < ORDER
        scalar, chain = (scalar + offset) % ORDER, material[32:]
        assert scalar != 0
    return scalar.to_bytes(32, "big")


def expected():
    seed = hashlib.pbkdf2_hmac("sha512", MNEMONIC.encode(), b"mnemonic", 2048, 64)
    assert seed == Bip39SeedGenerator(MNEMONIC).Generate("")
    # Upstream BIP-32 test-vector 1: independent library comparison at m/0'.
    primitive_seed = bytes(range(16))
    assert derive(primitive_seed, [0]) == Bip32Secp256k1.FromSeed(
        primitive_seed
    ).DerivePath("m/0'").PrivateKey().Raw().ToBytes()
    rows = []
    for role in range(5):
        for index in range(2):
            path = f"m/707285'/1'/{role}'/{index}'"
            private = derive(seed, [707285, 1, role, index])
            independent = Bip32Secp256k1.FromSeed(seed).DerivePath(path)
            assert private == independent.PrivateKey().Raw().ToBytes()
            if role in (0, 4):
                public = ed25519.Ed25519PrivateKey.from_private_bytes(private).public_key()
                raw = public.public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
                assert raw == Ed25519PrivateKey.FromBytes(private).PublicKey().RawCompressed().ToBytes()[-32:]
                encoding = "ed25519"
            else:
                public = ec.derive_private_key(int.from_bytes(private, "big"), ec.SECP256K1()).public_key()
                raw = public.public_numbers().x.to_bytes(32, "big")
                assert raw == independent.PublicKey().RawCompressed().ToBytes()[1:]
                encoding = "secp256k1-xonly"
            rows.append(dict(role=role, index=index, path=path, private_hex=private.hex(),
                             public_encoding=encoding, public_hex=raw.hex()))
    assert len({row["private_hex"] for row in rows}) == len(rows)
    return dict(version=1, warning="PUBLIC TEST SECRETS; NEVER USE FOR REAL MACHINES",
                mnemonic=MNEMONIC, bip39_passphrase="", bip39_seed_hex=seed.hex(),
                seed_id=hashlib.sha256(b"tau-web seed id v1\0" + seed).hexdigest(), vectors=rows)


def check(actual, wanted):
    if actual != wanted:
        raise ValueError("credential v1 fixture mismatch")


if __name__ == "__main__":
    fixture = Path(__file__).with_name("credential-vectors-v1.json")
    wanted = expected()
    if sys.argv[1:] == ["--write"]:
        fixture.write_text(json.dumps(wanted, indent=2) + "\n")
    elif sys.argv[1:]:
        raise SystemExit("usage: check-credential-vectors.py [--write]")
    check(json.loads(fixture.read_text()), wanted)
    print("PASS: 10 v1 key vectors agree across independent implementations")
