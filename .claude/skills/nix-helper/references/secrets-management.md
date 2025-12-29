# Secrets Management with SOPS

## Overview

This repository uses SOPS (Secrets OPerationS) with age encryption for managing secrets. Secrets are stored encrypted in `secrets/default.yaml` and decrypted at activation time.

## Initial Setup

### Generate Age Key

```bash
mkdir -p ~/.config/sops/age
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
```

### Get Public Key

```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

Add the public key to `.sops.yaml`:

```yaml
keys:
  - &kohei-m4-mac-mini age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &SC-N-843 age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *kohei-m4-mac-mini
          - *SC-N-843
```

## Working with Secrets

### Edit Secrets

```bash
sops secrets/default.yaml
```

This opens the decrypted file in your editor. Changes are automatically re-encrypted on save.

### Secret File Structure

```yaml
# secrets/default.yaml
github_token: ghp_xxxxxxxxxxxxx
openai_api_key: sk-xxxxxxxxxxxxx
aws:
  access_key_id: AKIAXXXXXXXXXX
  secret_access_key: xxxxxxxxxxxx
```

### Using Secrets in Nix

1. Define the secret in a module:

```nix
{ config, ... }:
{
  sops.secrets.github_token = { };
}
```

2. Use the secret path:

```nix
{
  programs.git.extraConfig = {
    credential.helper = "!cat ${config.sops.secrets.github_token.path}";
  };
}
```

### Nested Secrets

For nested YAML paths:

```nix
{
  sops.secrets."aws/access_key_id" = { };
  sops.secrets."aws/secret_access_key" = { };
}
```

## Common Operations

### Re-encrypt After Key Changes

When adding/removing machines:

```bash
sops -r secrets/default.yaml
```

### Rotate All Secrets

1. Edit `.sops.yaml` with new keys
2. Re-encrypt: `sops -r secrets/default.yaml`
3. Rebuild configuration

### Debug Decryption Issues

```bash
# Check if age key exists
ls ~/.config/sops/age/keys.txt

# Verify public key matches .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt

# Try manual decryption
sops -d secrets/default.yaml
```

## Best Practices

1. **Never commit unencrypted secrets** - SOPS handles encryption automatically
2. **One key per machine** - Each machine has its own age key
3. **Rotate keys periodically** - Update `.sops.yaml` and re-encrypt
4. **Limit secret scope** - Only include secrets needed by the configuration
5. **Use nested paths** - Organize related secrets together

## Security Notes

- The age key at `~/.config/sops/age/keys.txt` is the master key
- Back up the age key securely (it's needed for decryption)
- The decrypted secrets exist only in memory and the Nix store (which is world-readable on NixOS, but protected on macOS)
