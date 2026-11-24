#!/bin/bash
# Builds this app's Debian package into out/, the way PatroneOS builds it:
# the crates vendored (so dpkg-buildpackage runs offline), each crate's
# licence and notices in third-party-licenses.txt (installed beside the
# package's copyright file), and a binary-only build.
#
#   tools/build-deb.sh [DPKG-BUILDPACKAGE OPTION...]   e.g. -d to skip the
#                                                       Build-Depends check
#
# PatroneOS's own packaging/build.sh builds the same source, from the
# release tarball its release.txt pins, the same way.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
package=$(dpkg-parsechangelog -l "$root/debian/changelog" -S Source)
version=$(dpkg-parsechangelog -l "$root/debian/changelog" -S Version)

# debhelper replaces its placeholder wherever it appears in a maintainer
# script, comments included, so it must stand on a line of its own.
for script in "$root"/debian/{preinst,postinst,prerm,postrm}; do
    [[ -f $script ]] || continue
    if grep -n '#DEBHELPER#' "$script" | grep -v '^[0-9]*:#DEBHELPER#$'; then
        echo "$script: put #DEBHELPER# only on a line of its own (above)" >&2
        exit 1
    fi
done

build="$root/out/build"
work="$build/$package-$version"
rm -rf "$work"
mkdir -p "$work"
tar -C "$root" --exclude=./target --exclude=./out --exclude=./.git -cf - . | tar -C "$work" -xf -

if [[ -f $work/Cargo.toml ]]; then
    (cd "$work" && cargo vendor --locked --quiet vendor)
    mkdir -p "$work/.cargo"
    cat > "$work/.cargo/config.toml" << 'EOC'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOC
    # The crates' licences and notices go with the program, as their
    # licences ask: /usr/share/doc/$package/third-party-licenses.txt.gz
    bash "$root/tools/third-party-licenses.sh" "$work/vendor" > "$work/third-party-licenses.txt"
    echo third-party-licenses.txt >> "$work/debian/docs"
fi

(cd "$work" && dpkg-buildpackage -us -uc -b "$@")

mv "$build"/"$package"*_"$version"_*.deb "$root/out/"
ls -l "$root/out/$package"*_"$version"_*.deb
