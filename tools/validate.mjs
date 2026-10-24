// Development-only validation. No JavaScript ships or runs inside Roblox.
import { LuauState } from 'luau-web';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
const files = fs.readdirSync(path.join(root, 'src')).filter(name => name.endsWith('.luau')).map(name => 'src/' + name);
files.push('Faithful Exploit', 'tests/StudioSmoke.client.luau');
const compiler = await LuauState.createAsync();
try {
  for (const file of files) {
    compiler.loadstring(read(file), file, true);
    console.log('PASS compile:', file);
  }
} finally { compiler.destroy(); }
const bundle = read('Faithful Exploit');
const program = read('tests/roblox_mock.luau') + '\nlocal function start()\n' + bundle + '\nend\n' +
  'local function startShowcase()\n' + bundle.replace('ShowcaseControls = false', 'ShowcaseControls = true') + '\nend\n' +
  'local function startConfigured()\n' + bundle.replaceAll('"BACKGROUND_ASSET_ID"', '"123"') + '\nend\n' + read('tests/lifecycle.spec.luau');
const state = await LuauState.createAsync({ print: (...x) => console.log(...x), warn: (...x) => console.warn(...x) });
try { await state.loadstring(program, 'FaithfulLifecycleTests', true)(); }
finally { state.destroy(); }
