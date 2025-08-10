# dotfiles

management dotfiles

## Documentation

- [SOPS Manual](docs/SOPS.md) - Comprehensive guide for secrets management with SOPS

## Usage

### Update dependencies

```bash
# update flake.lock and _sources by nvfetcher
$ nix run .#update

$ sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
```
