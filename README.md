# devbox

Two always-on dev containers on a [Fedora CoreOS](https://fedoraproject.org/coreos/)
host, managed over SSH from your workstation:

| container | tool                                                   | home volume   | workspace          |
|-----------|--------------------------------------------------------|---------------|--------------------|
| `claude`  | [Claude Code](https://docs.anthropic.com/claude-code)  | `claude-home` | `~/work` → `/work` |
| `omp`     | [oh-my-pi](https://www.npmjs.com/package/@oh-my-pi/pi-coding-agent) | `omp-home` | `~/work` → `/work` |

Both run rootless under `core` via Quadlet and start at boot (linger). Logins
and settings live in the home volumes and survive image rebuilds. The tools
themselves are baked into the images, which `devbox-refresh.timer` rebuilds
once a week. Running containers switch to the new image on the next restart
or reboot, so open sessions are never killed underneath you.

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

## Installing a fresh host

`devbox.bu` is the same setup as a Butane config. `devbox ignition > devbox.ign`
renders it using your SSH agent's public keys for `core`. Then
`coreos-installer install /dev/… --ignition-file devbox.ign`. The images build on
first boot (a few minutes), then the containers start.

## Changing things

Edit the files under `home/` (they mirror `/var/home/core` on the host), then
`devbox deploy && devbox restart`.

## Local overrides

Keep anything specific to your setup out of this repo, in an overlay
directory that mirrors `/var/home/core` the same way `home/` does. `devbox
deploy` and `devbox ignition` lay its files over `home/`. Point `devbox` at
it, and at your host, in `~/.config/devbox/config`:

```bash
DEVBOX_HOST=my-server
DEVBOX_OVERLAY=~/my-infra/devbox
```

The main use is oh-my-pi's custom model providers: `home/devbox/omp/models.yml`
defines none, and `<overlay>/devbox/omp/models.yml` replaces it (the example
in the default file shows the format). For `devbox ignition`, the overlay
can only replace files that `devbox.bu` already installs.

## License

[MIT](LICENSE)
