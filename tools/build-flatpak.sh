#!/bin/bash
# Builds this app's Flatpak (flatpak/APP-ID.yml) into out/:
#
#   PACKAGE-VERSION-linux-x86_64.flatpak  the bundle, to install with
#                                         flatpak install
#   PACKAGE-VERSION-linux-x86_64.tar.gz   the same app's files, which
#                                         Patrone's app index has Flatpak
#                                         download
#
# Needs flatpak, flatpak-builder, bsdunzip (libarchive-tools) and cargo. The GNOME runtime, its SDK and
# the Rust extension come from Flathub, for this account.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
manifest=$(ls "$root"/flatpak/*.yml)
id=$(sed -n 's/^id: //p' "$manifest")
package=$(sed -n '1s/^\([^ ]*\) .*/\1/p' "$root/debian/changelog")
version=$(sed -n '1s/^[^ ]* (\([^)]*\)).*/\1/p' "$root/debian/changelog")
name=$package-$version-linux-x86_64
work=$root/out/flatpak
flathub=https://dl.flathub.org/repo/flathub.flatpakrepo

rm -rf "${work:?}"
mkdir -p "$work/src"
tar -C "$root" --exclude=./target --exclude=./out --exclude=./.git -cf - . | tar -C "$work/src" -xf -
(cd "$work/src" && cargo vendor --locked --quiet vendor)
mkdir -p "$work/src/.cargo"
cat > "$work/src/.cargo/config.toml" << 'EOC'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOC
bash "$root/tools/third-party-licenses.sh" "$work/src/vendor" > "$work/src/third-party-licenses.txt"

# PatroneOS's fonts, for an app that has them in it (fonts-release.txt)
fonts_url= fonts_sum=
if [[ -f $root/fonts-release.txt ]]; then
    fonts_url=$(sed -n 's/^url=//p' "$root/fonts-release.txt")
    fonts_sum=$(sed -n 's/^sha256=//p' "$root/fonts-release.txt")
fi
sed -e "s|@FONTS_URL@|$fonts_url|" -e "s|@FONTS_SHA256@|$fonts_sum|" "$manifest" > "$work/$id.yml"

flatpak remote-add --user --if-not-exists flathub "$flathub"
# --disable-rofiles-fuse: no FUSE in containers and CI runners
flatpak-builder --user --install-deps-from=flathub --disable-rofiles-fuse --force-clean \
    --default-branch=stable --repo="$work/repo" --state-dir="$work/state" \
    "$work/build" "$work/$id.yml"
flatpak build-bundle --runtime-repo="$flathub" "$work/repo" "$root/out/$name.flatpak" "$id" stable
tar -C "$work/build/files" --exclude=./manifest.json --owner=0 --group=0 \
    --transform="s,^\\.,$name," -czf "$root/out/$name.tar.gz" .
ls -l "$root/out/$name.flatpak" "$root/out/$name.tar.gz"
