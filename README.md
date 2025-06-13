# dotfiles

management dotfiles

## Usage

### Add new key

```bash
$ mkdir -p ~/.config/sops/age

$ nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
```

### Update dependencies

```bash
# update flake.lock and _sources by nvfetcher
$ nix run .#update

$ sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
```
