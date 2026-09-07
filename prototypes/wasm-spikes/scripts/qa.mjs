#!/usr/bin/env node
// Drives the page in headless Chrome over CDP with mobile emulation and runs the four cases:
// SSH match, SSH mismatch, pinned TLS read from Robot, pinned TLS refusal of another issuer.
// Needs scripts/serve.sh running. Screenshots and a JSON summary land in run/qa/.
//   ROBOT_BASIC=$(printf 'user:pass' | base64 -w0) node scripts/qa.mjs   # authenticated GET
import { spawn, execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync, appendFileSync, readFileSync } from 'node:fs';
import { setTimeout as sleep } from 'node:timers/promises';

const root = new URL('..', import.meta.url).pathname;
const run = `${root}run`, out = `${run}/qa`;
mkdirSync(out, { recursive: true });
const chrome = process.env.CHROME || 'google-chrome';
const port = 9222 + Math.floor(Math.random() * 100);
const proc = spawn(chrome, ['--headless=new', '--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader',
  '--enable-unsafe-swiftshader', `--remote-debugging-port=${port}`, `--user-data-dir=${run}/chrome-profile`,
  '--enable-precise-memory-info', 'about:blank'], { stdio: 'ignore' });
let target;
for (let i = 0; i < 50 && !target; i++) {
  await sleep(200);
  target = await fetch(`http://127.0.0.1:${port}/json`).then(r => r.json()).then(l => l.find(t => t.type === 'page')).catch(() => null);
}
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r => ws.onopen = r);
let id = 0; const pending = new Map();
ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } };
const cdp = (method, params = {}) => new Promise(r => { ws.send(JSON.stringify({ id: ++id, method, params })); pending.set(id, r); });
const evaluate = async (expression) => {
  const r = await cdp('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
  if (r.result.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails));
  return r.result.result.value;
};
await cdp('Page.enable');
await cdp('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true });
await cdp('Emulation.setTouchEmulationEnabled', { enabled: true });
await cdp('Emulation.setUserAgentOverride', { userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36' });
await cdp('Page.navigate', { url: `http://127.0.0.1:8000/?user=${process.env.USER}` });
for (let i = 0; i < 100 && !(await evaluate('!!window.spike')); i++) await sleep(100);

const shot = async name => writeFileSync(`${out}/${name}.png`, Buffer.from((await cdp('Page.captureScreenshot', { captureBeyondViewport: true })).result.data, 'base64'));
const text = sel => evaluate(`document.querySelector('${sel}').textContent`);
const cls = sel => evaluate(`document.querySelector('${sel}').className`);
const summary = {};

// Register the in-page key on the machine, as the real flow does before first contact.
const pub = (await text('#ssh_pub')).split('\n').pop();
appendFileSync(`${run}/authorized_keys`, pub + '\n');
const pin = execFileSync('ssh-keygen', ['-lf', `${run}/hk.pub`]).toString().split(' ')[1];
await evaluate(`document.getElementById('ssh_pin').value = ${JSON.stringify(pin)}`);

await evaluate(`window.spike.ssh(${JSON.stringify(pin)})`);
summary.ssh_match = { cls: await cls('#ssh_out'), text: await text('#ssh_out') };
await shot('1-ssh-match');

await evaluate(`window.spike.ssh('SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')`);
summary.ssh_mismatch = { cls: await cls('#ssh_out'), text: await text('#ssh_out') };
await shot('2-ssh-mismatch');

const basic = process.env.ROBOT_BASIC || '';
await evaluate(`document.getElementById('tls_auth').value = ${JSON.stringify(basic)}; document.getElementById('tls_go').click(); new Promise(r => setTimeout(r, 0))`);
for (let i = 0; i < 300 && !(await cls('#tls_out')); i++) await sleep(100);
summary.tls_robot = { cls: await cls('#tls_out'), text: (await text('#tls_out')).replace(/Authorization: Basic \S+/g, 'Authorization: Basic <redacted>') };
await shot('3-tls-robot');

await evaluate(`document.getElementById('tls_out').className=''; document.getElementById('tls_other').click(); new Promise(r => setTimeout(r, 0))`);
for (let i = 0; i < 300 && !(await cls('#tls_out')); i++) await sleep(100);
summary.tls_other_issuer = { cls: await cls('#tls_out'), text: await text('#tls_out') };
await shot('4-tls-other-issuer');

summary.memory = await evaluate('({ wasmLinearMemoryMiB: +(window.spike.wasmMemory()/1048576).toFixed(1), jsHeapMB: performance.memory ? +(performance.memory.usedJSHeapSize/1e6).toFixed(1) : null })');
writeFileSync(`${out}/summary.json`, JSON.stringify(summary, null, 2));
console.log(JSON.stringify(summary, null, 2));
ws.close(); proc.kill();
const ok = summary.ssh_match.cls === 'ok' && summary.ssh_mismatch.cls === 'bad' && summary.ssh_mismatch.text.includes('REFUSED by SSH layer')
  && summary.tls_robot.cls === 'ok' && summary.tls_other_issuer.cls === 'bad' && summary.tls_other_issuer.text.includes('REFUSED by TLS layer');
console.log(ok ? 'QA PASS' : 'QA FAIL');
process.exit(ok ? 0 : 1);
