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
#   base (system), shell (fish), ssh (security), development (dev, tools),
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

**Using COPR on Fedora is OK.** When a package isn't in Fedora's default repos but a maintained COPR exists, enabling it is the preferred approach (mirrors how AUR is used on Arch). **Enable it by writing the `.repo` file directly with `ansible.builtin.yum_repository`, NOT by shelling out to `dnf copr enable`.** Fedora 41+ ships dnf5, whose `copr enable` parses assumeyes (global `dnf -y copr enable`, not `copr enable -y`) and prompts to confirm external repos differently than dnf4 — so the `command: dnf copr enable -y …` route enabled the repo on a dnf4 host but silently created nothing on a dnf5 host (cost us a long debug on x1yogag9). `yum_repository` writes the ini file both dnf versions read identically. Pattern:
```yaml
- ansible.builtin.yum_repository:
    name: "copr:copr.fedorainfracloud.org:<owner>:<project>"
    description: "Copr repo for <project> owned by <owner>"
    baseurl: "https://download.copr.fedorainfracloud.org/results/<owner>/<project>/fedora-$releasever-$basearch/"
    gpgcheck: yes
    gpgkey: "https://download.copr.fedorainfracloud.org/results/<owner>/<project>/pubkey.gpg"
    skip_if_unavailable: yes
  become: yes
```
Reference tasks: `roles/base/tasks/nerd-fonts-fedora.yml` (aquacash5/nerd-fonts) and `roles/development/tasks/copr-fedora.yml` (atim/lazygit, atim/lazydocker, lihaohong/yazi). (`roles/syncthing/tasks/install-redhat.yml` still uses the old `dnf copr enable` form and should be migrated if it misbehaves on dnf5.)

**Keep COPR packages OUT of the shared base batch.** `install-packages-with-mapping.yml` installs everything in one all-or-nothing dnf transaction, so a single unavailable COPR package fails *every* base package with it. Don't add COPR-provided names to `packages.*.fedora`; instead make a self-contained task that (1) enables the COPR, then (2) installs its packages with `update_cache: yes` in the same task — the cache refresh is required because the run's earlier metadata refresh happened before the COPR existed. Wire that task into `main.yml` *after* "Install base packages" (it no longer needs to run first). `nerd-fonts-fedora.yml` is the reference pattern.

**Caveat — a COPR can lag new Fedora releases.** A COPR may exist but have an *empty* build for a brand-new Fedora (the `fedora-NN-x86_64/` dir and repo metadata auto-scaffold with `packages="0"`), so the package silently won't install. Before relying on a COPR for the latest Fedora, verify it has actual RPMs (`dnf repoquery <pkg> --repoid="copr:..."`). When it doesn't, prefer a release-independent source — e.g. LocalSend on Fedora installs from Flathub via `roles/base/tasks/localsend-flatpak-fedora.yml` (uses `community.general.flatpak`/`flatpak_remote`) rather than the f44-empty dregetas/localsend COPR.

### Key Patterns
1. **Dynamic User Detection**: Uses `ansible_user_id` and environment variables rather than hardcoded usernames
2. **OS-Specific Task Inclusion**: Conditional includes based on `ansible_os_family` or `ansible_distribution`
3. **Service Management**: Handles both systemd (Linux) and launchd (macOS) services
4. **Modular Feature Flags**: Roles can be enabled/disabled via variables (e.g., `install_tailscale: true`)
5. **Shell Setup**: The `shell` role installs Fish (plus fzf and autojump, which both integrate with fish) and sets it as the login shell. The login shell is picked from `user_shell_overrides[user]` in `main.yml` (falling back to `default_shell`, which is `/usr/bin/fish`). Zsh / Oh My Zsh / Powerlevel10k were removed — fish is the only managed shell.
6. **Dotfiles via External Repo**: The `dotfiles` role clones `dotfiles_repo` into `dotfiles_path` and runs that repo's `sync-dotfiles.sh restore --all --yes` when `apply_dotfiles_restore` is true. The role's stock Jinja templates (`vimrc.j2`, `tmux.conf.j2`, `init.vim.j2`) only deploy when `deploy_default_configs` is true — disabled in `main.yml` because the dotfiles repo ships its own.

### Important Files
- `roles/base/tasks/install-packages-with-mapping.yml`: Core package mapping logic
- `roles/*/tasks/install-*.yml`: OS-specific installation patterns
- `ansible.cfg`: Performance optimizations (fact caching, SSH pipelining)