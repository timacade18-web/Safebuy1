#!/usr/bin/env python3
import sys
path = '.android/app/build.gradle'
try:
    with open(path, 'r') as f:
        content = f.read()
except FileNotFoundError:
    print('Not found')
    sys.exit(0)
src = """
    sourceSets {
        main {
            res.srcDirs = [
                "src/main/res",
                "../android/app/src/main/res"
            ]
        }
    }
"""
idx = content.find("flutter {")
if idx != -1:
    content = content[:idx] + src + content[idx:]
    with open(path, 'w') as f:
        f.write(content)
    print('sourceSets added')
else:
    print('flutter block not found')
