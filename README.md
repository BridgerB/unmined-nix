# unmined-nix

Nix flake for [uNmINeD](https://unmined.net) - a fast Minecraft world mapper
with both GUI and CLI tools.

## Quick Start

```bash
# Run GUI (default)
nix run github:BridgerB/unmined-nix

# Run CLI
nix run github:BridgerB/unmined-nix#unmined-cli -- --help
```

## Installation

### NixOS

```nix
{
  inputs.unmined.url = "github:BridgerB/unmined-nix";

  environment.systemPackages = [
    inputs.unmined.packages.x86_64-linux.unmined-gui
    inputs.unmined.packages.x86_64-linux.unmined-cli
  ];
}
```

### Home Manager

```nix
{
  inputs.unmined.url = "github:BridgerB/unmined-nix";

  home.packages = [
    inputs.unmined.packages.x86_64-linux.unmined-gui
    inputs.unmined.packages.x86_64-linux.unmined-cli
  ];
}
```

## Usage

### GUI

```bash
nix run . -- /path/to/minecraft/world
```

### CLI

```bash
# Get help
nix run .#unmined-cli -- --help

# Render a world
nix run .#unmined-cli -- render /path/to/world --output /path/to/maps

# Batch processing
for world in worlds/*; do
  nix run .#unmined-cli -- render "$world" --output "maps/$(basename "$world")"
done
```

## Available Packages

| Package       | Command                 | Description     |
| ------------- | ----------------------- | --------------- |
| `default`     | `nix run .`             | GUI (default)   |
| `unmined-gui` | `nix run .#unmined-gui` | GUI application |
| `unmined-cli` | `nix run .#unmined-cli` | CLI tool        |

## Development

```bash
# Build locally
nix build .                # GUI
nix build .#unmined-cli    # CLI

# Test
nix run . -- --version
nix run .#unmined-cli -- --help
```

## Updating

When a new version is released:

1. Update version in `flake.nix`
2. Update URL timestamp parameter
3. Run `nix build .` to get new hash
4. Update `sha256` with hash from error message

## Troubleshooting

**GUI won't launch**: Clear runtime cache

```bash
rm -rf ~/.cache/unmined-runtime && nix run .
```

**Missing libraries**: Check error and add library to `flake.nix`

## Technical Notes

- Both are .NET 9.0 applications
- GUI creates writable runtime directory at `~/.cache/unmined-runtime`
- Binaries are not patched to avoid corrupting embedded .NET data
- Libraries provided via `LD_LIBRARY_PATH`
- Only supports `x86_64-linux` (upstream limitation)

## License

- Packaging: MIT
- uNmINeD: Proprietary (see https://unmined.net)
