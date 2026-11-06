# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Fish shell CTF environment management toolkit that provides utilities for CTF/pentesting box workflows. The main `ctf` command orchestrates setup, cleanup, and management of individual CTF box environments.

## Architecture

### Core Components

- **Main CLI**: `functions/ctf.fish` - Central command dispatcher with menu system
- **Subcommands**: Individual `_ctf_*.fish` functions for specific operations
- **Color System**: `_ctf_colors.fish` provides consistent terminal output formatting
- **Completions**: `completions/ctf.fish` provides Fish shell tab completion

### Command Structure

The toolkit follows a subcommand pattern: `ctf <command> [args]`

Available commands:
- `start <boxname> <ip>` - Initialize CTF box environment
- `cleanup` - Clean up and reset environment  
- `addhost <ip> <host>` - Manage /etc/hosts entries
- `env [set|edit] [var] [value]` - Environment variable management

### Environment Management

The system uses a dual environment approach:
- **Box-specific env**: `~/Lab/boxes/<boxname>/env.fish` - Persistent box configuration
- **Global env**: `~/Lab/env.fish` - Active session variables

Key environment variables set during `start`:
- `$arch` - Local tun0 IP address
- `$box` - Box name
- `$ip` - Target box IP
- `$url` - Box URL (http://$box.htb)
- `$boxpwd` - Box working directory path

### Directory Structure

CTF boxes are organized under `~/Lab/boxes/`:
- Active boxes: `~/Lab/boxes/0_<boxname>/` (prefixed with 0_)
- Archived boxes: `~/Lab/boxes/<boxname>/` (moved after cleanup)

Each box directory contains:
- `env.fish` - Environment variables
- `hosts.bak` - Backup of /etc/hosts (created during cleanup)
- `screenshots/` - Directory for screenshots
- `<boxname>.md` - Markdown file (if Obsidian integration enabled)

### Key Workflows

#### Box Initialization (`start`)
1. Validates dependencies (ntpd, gnome-text-editor)
2. Creates or restores box directory structure
3. Sets up environment variables
4. Manages /etc/hosts entries
5. Optionally integrates with Obsidian (if `$OBSIDIAN` set)
6. Syncs time with target box

#### Box Cleanup (`cleanup`)
1. Backs up current /etc/hosts to box directory
2. Removes the box IP/hostname entries from /etc/hosts while preserving
   unrelated entries and the localhost records
3. Aborts if the archived destination already exists (no nested moves)
4. Moves active box from `0_<boxname>` to `<boxname>`
5. Cleans up Obsidian integration
6. Unsets environment variables
7. Syncs time with public NTP

### Integration Features

- **Obsidian Integration**: Creates hardlinks and symlinks for note-taking workflow
- **Time Synchronization**: Syncs system time with target boxes
- **Host Management**: Automated /etc/hosts manipulation for easy domain access

## Development Commands

This is a Fish shell script toolkit - no build process required. Install by:
1. Setting `$CTF_HOME` environment variable to repository path
2. Adding `source "$CTF_HOME/functions/ctf.fish"` to Fish config
3. Adding completions directory to Fish completion path

## Testing

No formal test suite exists. Test manually with:
```fish
ctf start testbox 10.10.10.1
ctf addhost 10.10.10.2 subdomain.testbox.htb
ctf env set TESTVAR testvalue
ctf cleanup
```

## File Permissions

The toolkit requires sudo access for:
- Modifying /etc/hosts
- Running ntpdate for time synchronization
- File ownership changes during cleanup