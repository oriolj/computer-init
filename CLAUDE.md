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

# Role tags (each role is also reachable by an alias):
#   base (system), shell (zsh), ssh (security), development (dev, tools),
#   dotfiles (config), extras (aur), tailscale (vpn), syncthing (sync)
# There is no `docker` tag — Docker installs as part of the `development` role.
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
- **`group_vars/all/main.yml`**: User settings, feature flags, AUR package list, SSH keys, vault references. Does NOT define `packages` or `package_map` — those live in `packages.yml`.
- **`group_vars/all/packages.yml`**: Cross-platform package lists (`packages.{base,development,extras}.{common,ubuntu,debian,fedora,arch,darwin}`) and `package_map` for name remapping. Loaded after `main.yml` and is the source of truth for those keys.
- **`inventory/hosts.yml`**: Ansible inventory (defaults to localhost). Referenced from `ansible.cfg`.

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

**Using COPR on Fedora is OK.** When a package isn't in Fedora's default repos but a maintained COPR exists, enabling it is the preferred approach (mirrors how AUR is used on Arch). Pattern: install `dnf-command(copr)`, then `dnf copr enable -y <owner>/<project>` guarded by `creates: /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:<owner>:<project>.repo`, then add the package to the relevant `packages.*.fedora` list. Examples: `roles/syncthing/tasks/install-redhat.yml` (decathorpe/syncthing) and `roles/base/tasks/localsend-copr-fedora.yml` (dregetas/localsend). For COPR repos that must be enabled before the shared `install-packages-with-mapping.yml` runs, wire the enable step into `roles/base/tasks/main.yml` ahead of "Install base packages".

### Key Patterns
1. **Dynamic User Detection**: Uses `ansible_user_id` and environment variables rather than hardcoded usernames
2. **OS-Specific Task Inclusion**: Conditional includes based on `ansible_os_family` or `ansible_distribution`
3. **Service Management**: Handles both systemd (Linux) and launchd (macOS) services
4. **Modular Feature Flags**: Roles can be enabled/disabled via variables (e.g., `install_tailscale: true`)
5. **Dual Shell Setup**: The `shell` role installs both Zsh (with Oh My Zsh + Powerlevel10k) and Fish. The login shell is picked from `user_shell_overrides[user]` in `main.yml` (falling back to `default_shell`). The `oriol` user is set to fish.
6. **Dotfiles via External Repo**: The `dotfiles` role clones `dotfiles_repo` into `dotfiles_path` and runs that repo's `sync-dotfiles.sh restore --all --yes` when `apply_dotfiles_restore` is true. The role's stock Jinja templates (`vimrc.j2`, `tmux.conf.j2`, `init.vim.j2`) only deploy when `deploy_default_configs` is true — disabled in `main.yml` because the dotfiles repo ships its own.

### Important Files
- `roles/base/tasks/install-packages-with-mapping.yml`: Core package mapping logic
- `roles/*/tasks/install-*.yml`: OS-specific installation patterns
- `ansible.cfg`: Performance optimizations (fact caching, SSH pipelining)