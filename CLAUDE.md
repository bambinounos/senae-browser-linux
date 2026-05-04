# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Docker image that packages a legacy browser stack (Firefox 41.0.2 + Oracle JRE 7u80 + Flash Player 25 NPAPI) so users on modern Ubuntu 24.04 can still access **Ecuapass** (Ecuadorian customs / Aduana del Ecuador), which depends on a Java applet and a Flex/Flash UI that no current browser supports. The repo is small (one Dockerfile + two shell wrappers) — most of the value is in getting the plugin wiring correct.

User-facing docs are in Spanish (`README.md`, `ESPECIFICACIONES.md`); preserve that language when editing them.

## Build and run

Two binaries cannot be redistributed and must be downloaded manually into the repo root before `./build.sh` will succeed:

- `jre-7u80-linux-x64.tar.gz` — from Oracle's Java SE 7 archive (requires free Oracle account)
- `libflashplayer.so` — extracted from `fp_25.0.0.171_archive.zip` on archive.org, specifically `25_0_r0_171/flashplayer25_0r0_171_linux.x86_64.tar.gz` inside it

`build.sh` checks for both and exits with an error message pointing to the download URLs if missing. Firefox itself is fetched at image build time from `ftp.mozilla.org`.

```bash
chmod +x build.sh run.sh
./build.sh                    # builds senae-browser:latest
./run.sh                      # opens Ecuapass
./run.sh https://other.url    # ENTRYPOINT forwards args to Firefox
./run.sh about:plugins        # verify Java + Flash are loaded
```

`run.sh` runs `xhost +local:docker` (best-effort) and starts the container with `--network host`, the host X11 socket bind-mounted, and a named volume `senae-profile` for the Firefox profile. There is no test suite and no lint config — verification is manual via `about:plugins` and loading the Ecuapass Flex app.

## Architecture notes for editing the Dockerfile

The image is single-stage `ubuntu:24.04`. A few wiring details that aren't obvious from a casual read:

- **Plugins are linked into two locations.** `/usr/lib/mozilla/plugins/` (system-wide) AND `/home/senae/.mozilla/plugins/` (user-level, also pointed at by `MOZ_PLUGIN_PATH`). Firefox 41 needs both for plugin discovery to be reliable; don't drop one when refactoring.
- **Firefox profile is baked in at `/home/senae/.senae-profile`** and the same path is mounted as a Docker volume by `run.sh`. The first run uses the baked-in `prefs.js` (forces Java/Flash plugins to "Always Activate", disables mixed-content blocking for the Ecuapass HTTP/HTTPS mix); subsequent runs use whatever the user accumulated in the volume.
- **Java security is intentionally weakened** in `~/.java/deployment/deployment.properties` (`deployment.security.level=MEDIUM`, OCSP/CRL off, `deployment.insecure.jres=ALWAYS`, expired-cert tolerance on) because the Ecuapass applet is signed with long-expired certs. The exception sites list pins `ecuapass.aduana.gob.ec` and `portal.aduana.gob.ec`. Don't tighten these without a replacement plan — the applet will refuse to launch.
- **Flash `mms.cfg`** disables RSL signature verification and auto-update / EOL-uninstall behavior. Without `EOLUninstallDisable=1` and `RSLVerifyDigitalSignatures=0`, Flash 25 will either refuse to run or throw Error #2046 in the Flex app.
- **Locale is `es_EC.UTF-8`** because the Ecuapass UI assumes Spanish; changing it can affect form rendering.
- **`ENTRYPOINT` is the Firefox binary** with `-no-remote -profile <path>` baked in, and `CMD` is the default URL — that's why `./run.sh <url>` works as an override.

## Things to watch out for

- Don't "modernize" Firefox, Java, or Flash versions. The whole point is bug-for-bug compatibility with what Ecuapass expects; newer Firefox dropped NPAPI in 52, newer Java has no browser plugin at all.
- Don't add `--no-install-recommends` exceptions casually; the GTK2 / libxt / libasound stack is the minimum to run Firefox 41 GUI inside the container, and Firefox 41 silently fails to start if any of these are missing.
- WSL2 is listed as "partial" support — GUI requires WSLg. If a user reports the browser window not appearing, the first thing to check is `DISPLAY` and whether they're on Wayland without XWayland installed.

## Hard-won gotchas (lessons from real debugging)

These are subtleties not obvious from reading the code — easy to regress if you don't know:

### 1. Flash 25 NPAPI requires `libgl1`, `libnss3`, `libnspr4`

The Dockerfile installs these three explicitly. **Don't drop them when refactoring** — Flash uses Mozilla's NSS for crypto and Mesa's libGL for rendering. Without them, the dynamic linker fails to load `libflashplayer.so` and Firefox **silently** omits Flash from `about:plugins` with no error visible to the user. To verify after any image change:

```bash
docker run --rm --entrypoint /bin/bash senae-browser:latest -c \
  'ldd /opt/flash/libflashplayer.so | grep "not found"'
# Must return nothing
```

### 2. The X11 socket GID is NOT the directory GID

`run.sh` derives the GID for `--group-add` so the container user `senae` (UID 1001) can access the host's X11 socket. The trap: **`/tmp/.X11-unix` itself is `root:root` (GID 0)**, but the actual socket file `/tmp/.X11-unix/Xn` inside is owned by the user that started X (typically GID 1000). If you `stat -c '%g' /tmp/.X11-unix` you get `0`, which makes `--group-add 0` and the container can't connect — failure mode is generic "cannot open display :0". You have to `stat` the socket file specifically (`X${DISPLAY_NUM}`).

### 3. `RESET=1` is not just for `prefs.js` iteration

The original purpose was: Docker only copies the image's baked-in profile to the volume on first creation. So edits to `prefs.js` don't apply unless you wipe the volume. **But there's a second reason**: Firefox caches the result of plugin discovery inside the profile. If you previously built an image with broken plugin dependencies (Flash didn't load), then fix the deps and rebuild, Firefox still shows Flash as missing because it trusts its cache. `RESET=1` invalidates both at once. Document this whenever the `RESET=1` flag comes up — users hit this surprisingly often.

### 4. Snap-confined `gh` cannot operate in paths with spaces

If the repo lives at a path containing a space (e.g. `Antigravity Google/...`), `gh` from snap fails with "current directory is not a git repository" even when `git status` works fine. Workaround: use the GitHub REST API directly with `curl` (token via `gh auth token`), or move the repo to a space-free path.
