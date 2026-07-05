#!/usr/bin/env python3
"""Generates lib/src/params_2026_data.dart from lib/params/params_2026.json.

Run from the package root:  python3 tool/embed_params.py
"""

import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "lib", "params", "params_2026.json")
DST = os.path.join(ROOT, "lib", "src", "params_2026_data.dart")

content = open(SRC, encoding="utf-8").read()
assert "'''" not in content, "the JSON must not contain ''' (raw string)"

with open(DST, "w", encoding="utf-8") as f:
    f.write("/// Embedded copy of `lib/params/params_2026.json`.\n")
    f.write("///\n")
    f.write("/// GENERATED from the JSON file - do not edit by hand; edit\n")
    f.write("/// `lib/params/params_2026.json` and regenerate this file\n")
    f.write("/// (`tool/embed_params.py`). The test `params_sync_test.dart`\n")
    f.write("/// ensures both copies stay identical.\n")
    f.write("library;\n\n")
    f.write("const String params2026Json = r'''\n")
    f.write(content)
    f.write("''';\n")

print(f"written: {DST} ({len(content)} bytes of JSON)")
