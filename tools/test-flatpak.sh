#!/bin/bash
# Runs the installed Flatpak in its sandbox (.github/workflows/flatpak.yml):
# libarchive from the runtime reads an archive in the home folder.
set -euo pipefail
id=org.patrone.Unpack
flatpak run "$id" --version
folder=$(mktemp -d "$HOME/unpack-test.XXXXXX")
printf 'hello\n' > "$folder/hello.txt"
(cd "$folder" && tar -czf test.tar.gz hello.txt)
listing=$(flatpak run "$id" --list "$folder/test.tar.gz")
echo "$listing"
grep -q hello.txt <<< "$listing"
flatpak run --command=ls "$id" /app/share/doc/patrone-unpack/third-party-licenses.txt.gz \
    /app/share/metainfo/org.patrone.Unpack.metainfo.xml
echo "The Flatpak runs, and reads archives."
