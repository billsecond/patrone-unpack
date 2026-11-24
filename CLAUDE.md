# Patrone Unpack (patrone-unpack)

Patrone's app for archives, .deb packages and Flatpak files: it opens zip, tar, 7z, rar and single compressed files as folders, and installs .deb packages and Flatpak apps. It's in its own repository since 2026-11-24 (before, it was in
[billsecond/patroneos](https://github.com/billsecond/patroneos), whose
`CLAUDE.md` and `docs/` hold the wider picture). It installs on PatroneOS,
and on its own on Ubuntu 26.04 and systems built on it.

## Rules

- **Never credit Claude.** No `Co-Authored-By: Claude`, no "Generated with Claude
  Code", no AI attribution in commits, PRs, tags, release notes or code comments.
- Commit as `William Daugherty (billsecond) <31995458+billsecond@users.noreply.github.com>`.
- **This repo is public.** Nothing private goes in it.
- Installed on its own, the package must change nothing else on the system
  beyond what it's for: what makes it PatroneOS's choice belongs in
  PatroneOS's own packages (`patrone-desktop`, `patrone-default-apps`).

## Releasing

1. Bump the version in `debian/changelog` (and `Cargo.toml`'s, if it has one).
2. Merge to `main`, then tag it: `git tag vVERSION && git push origin vVERSION`.
   `release.yml` builds the `.deb` in a clean Ubuntu 26.04 and makes the
   release, with the source tarball and `SHA256SUMS`.
3. In billsecond/patroneos, point `packaging/patrone-unpack/release.txt` at the new
   tarball (its URL and SHA-256) and merge: that publishes it to Patrone's
   apt repository within a day.
