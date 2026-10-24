#!/usr/bin/env python3
"""Package sources/assets and a native Roblox XML model, without touching GitHub."""
from pathlib import Path
import hashlib
import json
import xml.etree.ElementTree as ET
import zipfile
from build import ROOT, MODULES, bundle


def package():
    assert (ROOT / 'Faithful Exploit').read_text() == bundle(), 'Rebuild first'
    output = ROOT / 'dist'
    output.mkdir(exist_ok=True)
    standalone = output / 'Faithful-Standalone.client.luau'
    standalone.write_text(bundle())
    model = ET.Element('roblox', {'version': '4'})
    ET.SubElement(model, 'External').text = 'null'
    ET.SubElement(model, 'External').text = 'nil'
    folder = ET.SubElement(model, 'Item', {'class': 'Folder', 'referent': 'RBXFAITHFUL'})
    props = ET.SubElement(folder, 'Properties')
    ET.SubElement(props, 'string', {'name': 'Name'}).text = 'Faithful'
    for name in MODULES + ['FaithfulMain']:
        is_main = name == 'FaithfulMain'
        item = ET.SubElement(folder, 'Item', {'class': 'LocalScript' if is_main else 'ModuleScript', 'referent': 'RBX' + name.upper()})
        props = ET.SubElement(item, 'Properties')
        ET.SubElement(props, 'string', {'name': 'Name'}).text = name
        filename = name + ('.client.luau' if is_main else '.luau')
        ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = (ROOT / 'src' / filename).read_text()
    model_path = output / 'Faithful.rbxmx'
    ET.ElementTree(model).write(model_path, encoding='utf-8', xml_declaration=True)
    # Round-trip XML/source verification; this is not a Studio import test.
    parsed = ET.parse(model_path)
    scripts = parsed.findall('.//Item/Properties/ProtectedString')
    assert len(scripts) == 5
    expected = [(ROOT / 'src' / (name + ('.client.luau' if name == 'FaithfulMain' else '.luau'))).read_text() for name in MODULES + ['FaithfulMain']]
    assert [element.text for element in scripts] == expected
    files = []
    for file in sorted(ROOT.rglob('*')):
        if not file.is_file():
            continue
        relative = file.relative_to(ROOT)
        if any(part in {'.git', 'node_modules', 'dist', '__pycache__'} for part in relative.parts):
            continue
        if file.suffix == '.pyc':
            continue
        files.append((file, relative.as_posix()))
    files += [(standalone, standalone.name), (model_path, model_path.name)]
    manifest = {name: hashlib.sha256(file.read_bytes()).hexdigest() for file, name in files}
    archive = output / 'Faithful-Complete.zip'
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for file, name in files:
            zf.write(file, 'Faithful/' + name)
        zf.writestr('Faithful/SHA256.json', json.dumps(manifest, indent=2) + '\n')
    with zipfile.ZipFile(archive) as zf:
        assert zf.testzip() is None
        for name, digest in manifest.items():
            assert hashlib.sha256(zf.read('Faithful/' + name)).hexdigest() == digest
    for file in [standalone, model_path, archive]:
        print(f'{file.name}: {file.stat().st_size} bytes')
    print(f'PASS: XML sources and {len(manifest)} archive members verified')


if __name__ == '__main__':
    package()
