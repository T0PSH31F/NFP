# Vicinae Sops Secrets Setup

This guide explains how to configure API keys and tokens for Vicinae extensions using sops-nix.

## Overview

The `secrets/vicinae.yaml` file stores sensitive data like:
- GitHub personal access tokens (for GitHub search extension)
- Weather API keys (for weather extension)
- Spotify credentials (for Spotify control extension)
- Other API keys required by extensions

## Initial Setup

### 1. Encrypt the secrets file

Before you can edit the secrets, you need to encrypt the file with your age key:

```bash
# Make sure your age key exists
ls ~/.config/sops/age/keys.txt

# Encrypt the vicinae.yaml file (first time only)
cd /home/t0psh31f/Clan/Grandlix-Gang
sops --encrypt --age $(age-keygen -y ~/.config/sops/age/keys.txt) secrets/vicinae.yaml > secrets/vicinae.yaml.enc
mv secrets/vicinae.yaml.enc secrets/vicinae.yaml
```

### 2. Edit the secrets

```bash
sops secrets/vicinae.yaml
```

This will open your editor with the decrypted content. The structure should be:

```yaml
vicinae.json: |
  {
    "providers": {
      "@knoopx/github-0": {
        "preferences": {
          "githubToken": "ghp_YOUR_ACTUAL_GITHUB_TOKEN"
        }
      },
      "@knoopx/weather-0": {
        "preferences": {
          "apiKey": "YOUR_ACTUAL_WEATHER_API_KEY",
          "location": "Your City, State"
        }
      }
    }
  }
```

### 3. Get API Keys

**GitHub Token:**
1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. Select scopes: `repo` (for private repos) or `public_repo` (for public only)
4. Copy the token and paste it in the secrets file

**Weather API:**
1. Sign up at https://openweathermap.org/api
2. Get your free API key
3. Add it to the secrets file

**Gemini API:**
1. Go to https://makersuite.google.com/app/apikey
2. Create a new API key
3. Copy and add to `gemini_api_key` field
4. Exposed as `$GEMINI_API_KEY` environment variable

**OpenRouter API:**
1. Sign up at https://openrouter.ai/
2. Go to https://openrouter.ai/keys
3. Generate a new API key
4. Add to `openrouter_api_key` field
5. Exposed as `$OPENROUTER_API_KEY` environment variable

## Environment Variables

The following environment variables are automatically set from sops secrets:

- `$GEMINI_API_KEY` - Google Gemini API key for AI/LLM access
- `$OPENROUTER_API_KEY` - OpenRouter API key for multi-model LLM access

These are available in all shell sessions and can be used by:
- CLI tools (aider, fabric-ai, etc.)
- Development environments
- Terminal-based LLM clients
- Any application that reads these environment variables

## Extension Configuration

### Currently Enabled Extensions

- **bluetooth** - No configuration needed
- **power-profile** - No configuration needed  
- **nix** - No configuration needed

### Commented Extensions (Require Configuration)

To enable extensions that need API keys:

1. Uncomment the extension in `vicinae.nix`:
   ```nix
   github # Uncomment this line
   ```

2. Add the configuration to `secrets/vicinae.yaml`:
   ```bash
   sops secrets/vicinae.yaml
   ```

3. Rebuild your system:
   ```bash
   nix develop --command clan machines update z0r0
   ```

## Extension Provider Names

When configuring extensions in sops, use these provider names:

- GitHub extension: `@knoopx/github-0`
- Weather extension: `@knoopx/weather-0`
- Spotify extension: `@knoopx/spotify-0`

The `-0` suffix indicates the first instance of that extension.

## Troubleshooting

**Secret file not found:**
```
Error: cannot read keyfile
```
- Make sure `~/.config/sops/age/keys.txt` exists
- Check the path in `flake-parts/users/t0psh31f.nix`

**Extension not working:**
- Check the extension name matches the provider name in secrets
- Verify the API key is correct
- Check systemd logs: `systemctl --user status vicinae.service`

**Syntax errors:**
- The vicinae.json content must be valid JSON (not YAML)
- Use double quotes for strings, not single quotes
- No trailing commas in JSON

## Example Complete Configuration

```yaml
vicinae.json: |
  {
    "providers": {
      "@knoopx/github-0": {
        "preferences": {
          "githubToken": "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        }
      },
      "@knoopx/weather-0": {
        "preferences": {
          "apiKey": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
          "location": "San Francisco, CA",
          "units": "imperial"
        }
      },
      "@knoopx/spotify-0": {
        "preferences": {
          "clientId": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
          "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        }
      }
    }
  }

# AI/LLM API Keys (exported as environment variables)
gemini_api_key: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
openrouter_api_key: sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Security Notes

- Never commit unencrypted secrets to git
- The `secrets/vicinae.yaml` file should be encrypted by sops
- Age key should be backed up securely
- Rotate API keys periodically

## References

- [Vicinae Documentation](https://docs.vicinae.com/nixos)
- [Vicinae Extensions](https://github.com/vicinaehq/extensions)
- [Sops-nix Documentation](https://github.com/Mic92/sops-nix)
