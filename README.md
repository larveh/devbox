# devbox

Two always-on dev containers on a Linux server, managed over SSH from your
workstation:

| container | tool                                                   | home volume   | workspace          |
|-----------|--------------------------------------------------------|---------------|--------------------|
| `claude`  | [Claude Code](https://docs.anthropic.com/claude-code)  | `claude-home` | `~/work` → `/work` |
| `omp`     | [oh-my-pi](https://www.npmjs.com/package/@oh-my-pi/pi-coding-agent) | `omp-home` | `~/work` → `/work` |

Both run rootless under your user via Quadlet and start at boot (linger). Logins
and settings live in the home volumes and survive image rebuilds. The tools
themselves are baked into the images, which `devbox-refresh.timer` rebuilds
once a week. Running containers switch to the new image on the next restart
or reboot, so open sessions are never killed underneath you.

## Requirements

On the server:

- systemd, and [Podman](https://podman.io) 4.4 or newer (for Quadlet).
  Fedora, Fedora CoreOS, Ubuntu 24.04 and Arch qualify; Debian 12 ships 4.3.
- Subordinate UID/GID ranges for your user in `/etc/subuid` and
  `/etc/subgid`, as rootless Podman needs (most distros add them with the user).
- `sudo`, once, for `loginctl enable-linger` (so the containers start at
  boot, not at your first login).
- GNU tar, and outbound HTTPS to Fedora's registry, GitHub, claude.ai,
  bun.sh and npm while images build.

`devbox deploy` checks Podman and systemd before changing anything.

## Use

The host must be reachable as `ssh devbox` (an alias in `~/.ssh/config`), or
set `DEVBOX_HOST` (see "Local overrides").

```bash
ln -s "$PWD/devbox" ~/.local/bin/devbox   # once, from this repo

devbox deploy        # push to the running host, build, start
devbox claude        # persistent shell in the claude container, then run `claude`
devbox omp           # same for oh-my-pi, then run `omp`
devbox claude docs   # a second, named session
devbox ls            # list sessions
```

First time in each container: log in (`claude` / `omp`) and `gh auth login` if
you want GitHub access.

## Sessions and scrolling

Sessions run under [shpool](https://github.com/shell-pool/shpool), not tmux.
shpool only keeps the shell alive across disconnects. It doesn't draw its own
screen, so mouse-wheel scrolling, scrollback search and text selection are
your terminal's own. Detach with `Ctrl-Space Ctrl-q` or by closing the
terminal. `devbox claude` reattaches, and it takes the session over from
another terminal if it's still attached somewhere else.

## Changing things

Edit the files under `home/` (they mirror your home directory on the server), then
`devbox deploy && devbox restart`.

## Local overrides

Keep anything specific to your setup out of this repo, in an overlay
directory that mirrors your home on the server the same way `home/` does.
`devbox deploy` lays its files over `home/`. Point `devbox` at it, and at
your host, in `~/.config/devbox/config`:

```bash
DEVBOX_HOST=my-server
DEVBOX_OVERLAY=~/my-infra/devbox
```

The main use is oh-my-pi's custom model providers: `home/devbox/omp/models.yml`
defines none, and `<overlay>/devbox/omp/models.yml` replaces it (the example
in the default file shows the format).

## License

[MIT](LICENSE)
