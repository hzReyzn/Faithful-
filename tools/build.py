#!/usr/bin/env python3
"""Bundle native Luau modules without runtime loadstring or external requires."""
from pathlib import Path
import argparse
import hashlib

ROOT = Path(__file__).resolve().parents[1]
MODULES = ['FaithfulTheme', 'FaithfulAssets', 'FaithfulUI', 'FaithfulVFX']


def bundle():
    sections = [
        '-- FAITHFUL | Native Roblox UI + Crimson Mist | 1.0.0\n',
        '-- Generated from src/ by tools/build.py. Edit the source modules, then rebuild.\n',
        '-- Paste this entire file into ONE LocalScript in StarterPlayerScripts.\n',
        '-- Roblox image IDs are optional when the executor provides local custom assets.\n',
        '-- UI only: no gameplay modifications, dynamic Lua execution or external modules.\n\n',
    ]
    for name in MODULES:
        source = (ROOT / 'src' / f'{name}.luau').read_text()
        sections.append(f'local {name} = (function()\n{source}\nend)()\n\n')
    main = (ROOT / 'src' / 'FaithfulMain.client.luau').read_text()
    # Replace only the four exact module imports; source is never interpreted in Roblox.
    for name in MODULES:
        local_name = {'FaithfulTheme': 'Theme', 'FaithfulAssets': 'Assets'}.get(name, name)
        line = f'local {local_name} = require(script.Parent:WaitForChild("{name}"))'
        assert line in main, f'Missing import: {name}'
        replacement = f'local {local_name} = {name}' if local_name != name else ''
        main = main.replace(line, replacement, 1)
    sections.append(main)
    return ''.join(sections)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text = bundle()
    target = ROOT / 'Faithful Exploit'
    if args.check:
        assert target.read_text() == text, 'Bundle differs from source; run tools/build.py'
        print('PASS: bundle matches all four source modules and the initializer')
    else:
        target.write_text(text)
        print(f'Built Faithful Exploit: {len(text.encode())} bytes; SHA256 {hashlib.sha256(text.encode()).hexdigest()}')


if __name__ == '__main__':
    main()
