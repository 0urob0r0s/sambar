# sambar

A profile-driven Samba deployment supporting everything from MS-DOS to modern OS.

## Quick Start

```bash
# Copy an example to configs/ and edit with your paths
cp examples/vintage_full.env configs/vintage_full.env

# Run
docker compose --env-file configs/vintage_full.env up -d
```

## Profiles

| Profile | Clients Supported | Ports |
|---------|-------------------|-------|
| `VINTAGE_FULL` | MS-DOS, Win 3.11, Win9x, WinXP, Win10+, macOS | 139 + 445 |
| `VINTAGE_ONLY` | MS-DOS, Win 3.11 | 139 |
| `OLDWINDOWS_FULL` | Win9x, WinXP, Win10+, macOS | 139 + 445 |
| `OLDWINDOWS_ONLY` | Win9x, Win2000, WinXP | 139 + 445 |
| `MODERN` | Win10+, macOS, Linux | 445 |

## Running Multiple Profiles

Non-overlapping profiles can coexist (e.g., VINTAGE_ONLY on port 139 + MODERN on port 445):

```bash
docker compose --env-file configs/vintage_only.env -p sambar-vintage up -d
docker compose --env-file configs/modern.env -p sambar-modern up -d
```

## Configuration

Your configs live in `configs/` (gitignored). See `examples/` for templates.

Each `.env` file defines:

- **PROFILE** — compatibility level (see table above)
- **SHARE_N** — share name exposed to clients
- **VOL_N_SRC/DST/MODE** — host path, container mount point, and ro/rw

Up to 8 shares are supported per instance.

### Adding a New Share

In your `.env` file, pick the next unused slot:

```bash
SHARE_5=games
VOL_5_SRC=/srv/samba/games
VOL_5_DST=/mnt/games
VOL_5_MODE=ro
```

### Creating a New Config

Copy any example, change `CONTAINER_NAME` and `PROFILE`, adjust shares as needed:

```bash
cp examples/modern.env configs/modern.env
```

## Rebuilding

```bash
docker compose --env-file configs/vintage_full.env up -d --build
```
