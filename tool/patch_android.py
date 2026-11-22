#!/usr/bin/env python3
"""Patch the generated Android platform files for Jelly Pop!

- App label -> "Jelly Pop!"
- Lock the main activity to portrait
Run after `flutter create`:  python3 tool/patch_android.py
"""
import os
import re

MANIFEST = os.path.join(
    os.path.dirname(__file__), "..", "android", "app", "src", "main", "AndroidManifest.xml"
)


def main():
    with open(MANIFEST, "r", encoding="utf-8") as f:
        xml = f.read()

    xml = xml.replace('android:label="jelly_pop"', 'android:label="Jelly Pop!"')

    if "android:screenOrientation" not in xml:
        xml = re.sub(
            r'(<activity\s[^>]*?android:name="\.MainActivity")',
            r'\1\n            android:screenOrientation="portrait"',
            xml,
            count=1,
        )

    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(xml)
    print("AndroidManifest patched: label + portrait lock")


if __name__ == "__main__":
    main()
