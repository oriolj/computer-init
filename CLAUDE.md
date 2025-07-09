# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible-based computer initialization project that automates the setup and configuration of development workstations across multiple operating systems (Ubuntu, Debian, Fedora, Arch Linux, and macOS).

## Common Commands

### Initial Setup
```bash
# Bootstrap Ansible installation
./bootstrap.sh

# Run complete setup
ansible-playbook playbooks/site.yml --ask-become-pass

# Run specific components using tags
ansible-playbook playbooks/site.yml --tags "shell,development" --ask-become-pass

# Available tags: base, shell, ssh, development, docker, dotfiles, tailscale, syncthing, extras
```

### Development Commands
```bash
# Run system updates
ansible-playbook playbooks/update.yml --ask-become-pass

# Dry run to see what would change
ansible-playbook playbooks/site.yml --check --diff

# Run with vault for encrypted variables
ansible-playbook playbooks/site.yml --ask-become-pass --ask-vault-pass

# Encrypt/decrypt vault files
ansible-vault encrypt group_vars/all/vault.yml
ansible-vault decrypt group_vars/all/vault.yml
```

### Testing and Validation
```bash
# Syntax check for playbooks
ansible-playbook playbooks/site.yml --syntax-check

# List all tasks that would be executed
ansible-playbook playbooks/site.yml --list-tasks

# List all available tags
ansible-playbook playbooks/site.yml --list-tags
```

## Architecture

### Configuration Structure
- **`group_vars/all/main.yml`**: Primary configuration file containing user settings, package selections, and feature flags
- **`group_vars/all/packages.yml`**: Cross-platform package mappings handling distribution-specific package names
- **`inventory/hosts.yml`**: Ansible inventory (defaults to localhost)

### Role Organization
Each role in `roles/` is self-contained with:
- `tasks/main.yml`: Entry point with OS-specific includes
- `tasks/install-*.yml`: OS-specific installation tasks
- `handlers/main.yml`: Service restart handlers
- `templates/`: Jinja2 templates for configuration files

### Cross-Platform Package Management
The project uses a custom `package_map` structure to handle package name differences across distributions. The `install-packages-with-mapping.yml` task file implements the mapping logic:
- Common package names are defined once
- OS-specific overrides are applied when needed
- Graceful fallback for unmapped packages

### Key Patterns
1. **Dynamic User Detection**: Uses `ansible_user_id` and environment variables rather than hardcoded usernames
2. **OS-Specific Task Inclusion**: Conditional includes based on `ansible_os_family` or `ansible_distribution`
3. **Service Management**: Handles both systemd (Linux) and launchd (macOS) services
4. **Modular Feature Flags**: Roles can be enabled/disabled via variables (e.g., `install_tailscale: true`)

### Important Files
- `roles/base/tasks/install-packages-with-mapping.yml`: Core package mapping logic
- `roles/*/tasks/install-*.yml`: OS-specific installation patterns
- `ansible.cfg`: Performance optimizations (fact caching, SSH pipelining)