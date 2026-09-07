# Cyniva Linux

Personal [bootc](https://bootc-dev.github.io/bootc/) images built with
[BlueBuild](https://blue-build.org), in GNOME and KDE Plasma variants. Based on
Universal Blue's `silverblue-main` and `kinoite-main`, which are Fedora Atomic
plus codecs, RPM Fusion, and hardware-acceleration support.

| Image | Desktop | Pull |
|---|---|---|
| `cyniva-linux-gnome` | GNOME | `ghcr.io/bojofil/cyniva-linux-gnome:gnome` |
| `cyniva-linux-kde` | KDE Plasma | `ghcr.io/bojofil/cyniva-linux-kde:kde` |

## Installation

Install stock Fedora Silverblue or Kinoite, then rebase. Two steps, because the
cosign public key and trust policy live *inside* the image — the first pull has
nothing to verify against.

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/bojofil/cyniva-linux-gnome:gnome
systemctl reboot

sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bojofil/cyniva-linux-gnome:gnome
systemctl reboot
```

Substitute the KDE image as needed. Updates after that are automatic; force one
with `bootc upgrade`.

## Domain join

`sssd.conf` is deliberately **not** in this repo or the image. It is applied
per-machine, along with a generated hostname and the AD join:

```bash
ujust ad-setup corp.example.com /path/to/sssd.conf jsmith
```

This uses `adcli join` rather than `realm join`, because `realm` rewrites
`/etc/sssd/sssd.conf` and would clobber the supplied config. Consequence: the
procedure is identical on GNOME and KDE, and GNOME's "Set Up Enterprise Login"
flow is not used.

A local admin account is required at install time — the join runs from a root
shell before the machine knows anything about AD. Keep it afterwards as a
break-glass login for when the domain is unreachable.

## What's included

- Firefox, VS Code, MEGA (RPM); Betterbird, Bitwarden, Spotify, Discord,
  GitHub Desktop Plus, Gear Lever (Flatpak)
- Adwaita Mono Nerd Font, Papirus icons
- Active Directory tooling (realmd, sssd, adcli, oddjob)
- Custom branding: login screen, Plymouth boot splash, Settings/About
- GNOME only: Dash to Dock, Blur My Shell, Extension Manager, GNOME Tweaks,
  adw-gtk3 theme extensions for Flatpaks

## Layout

```
recipes/
  common.yml      shared modules — apps, AD tooling, fonts, branding, initramfs
  gnome.yml       GNOME image  → common + gnome.d + signing
  gnome.d.yml     GNOME-only modules
  kde.yml         KDE image    → common + kde.d + signing
  kde.d.yml       KDE-only modules

files/
  scripts/        build-time only, never shipped in the image
  system/         shared, copied to / in BOTH images
  gnome/          copied to / in the GNOME image only
  kde/            copied to / in the KDE image only
```

A file goes in `system/` if both desktops need it, otherwise in the
per-desktop tree.

## Gotchas

Documented at length in [HANDOFF.md](HANDOFF.md). The short version:

- The `files` module **must** run before `dnf`, or third-party repos are not in
  `/etc/yum.repos.d` yet and packages fail to resolve.
- `megasync` is installed separately with scriptlets disabled — its `%post`
  calls `rpm --import` from inside a running rpm transaction and deadlocks.
- Listing a package the base already provides is a **build failure** on dnf5,
  not a no-op.
- Uses the `dnf` module, not `rpm-ostree`. The Kinoite/Aurora bases no longer
  support rpm-ostree in container builds.
- `default-flatpaks` is pinned to `@v2`. Multiple configurations append; on
  `@v1` they override.
- Each desktop reads its logo from a *different* place: `os-release`'s `LOGO`
  key (fastfetch), `/usr/share/pixmaps/fedora-logo*.png` (GNOME Settings),
  `/usr/share/pixmaps/system-logo-white.png` (KDE About).

## Local development

```bash
bluebuild build recipes/gnome.yml     # build locally
bluebuild switch recipes/gnome.yml    # build and rebase in one step
```

Faster than waiting on CI when iterating.

## Building

GitHub Actions builds both images on push, on a daily cron, and on manual
dispatch. Images are signed with cosign and published to GHCR.