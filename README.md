# Ansible Computer Initialization

A comprehensive Ansible-based solution for automating the setup and configuration of development workstations across multiple operating systems.

## Features

- **Cross-platform support**: Ubuntu, Debian, Fedora, Arch Linux, and macOS
- **Modular design**: Use only the components you need
- **Idempotent**: Safe to run multiple times
- **Customizable**: Easy to adapt to your specific needs

## Components

### Base System
- System package updates
- Essential tools installation
- Firewall configuration
- Automatic security updates
- User directory structure

### Shell Environment
- Zsh and Fish both installed; login shell picked per-user via `user_shell_overrides`
- Oh My Zsh framework
- Powerlevel10k theme
- Popular plugins (git, docker, kubectl, fzf, autojump)
- Custom aliases and functions

### SSH Configuration
- OpenSSH server setup
- Secure sshd configuration
- SSH key generation
- SSH agent setup
- Client configuration
- Authorized keys management

### Development Tools
- Modern CLI tools (ripgrep, fd, bat, exa, fzf)
- Text editors (Neovim, VS Code)
- Version control (Git with aliases)
- Programming languages (Python, Node.js, Go, Rust)
- Docker and Docker Compose
- Package managers and build tools

### Additional Services
- **Tailscale**: Zero-config VPN
- **Syncthing**: File synchronization
- **Dotfiles**: Clones a remote dotfiles repo and runs its `sync-dotfiles.sh restore` to deploy configs into `~/`
- **Extras**: Curated extra apps (CLI tools, GUI apps, AUR packages on Arch)

## Quick Start

### Prerequisites

- A supported operating system
- sudo/admin access
- Internet connection

### Installation

1. Clone this repository:
```bash
git clone https://github.com/oriolj/computer-init.git
cd computer-init
```

2. Run the bootstrap script:
```bash
./bootstrap.sh
```

3. Copy and customize the configuration:
```bash
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
# Edit group_vars/all/main.yml with your preferences
```

4. Run the playbook:
```bash
# Full installation
ansible-playbook playbooks/site.yml --ask-become-pass

# Or install specific components
ansible-playbook playbooks/site.yml --tags "shell,development"
```

## Configuration

### Main Variables

Edit `group_vars/all/main.yml`:

```yaml
# User settings
user: "{{ lookup('env', 'USER') }}"

# Dotfiles — cloned and applied via the repo's own sync-dotfiles.sh restore
dotfiles_repo: "https://github.com/oriolj/dotfiles.git"
dotfiles_path: "{{ home_dir }}/git/oriolj/dotfiles"
dotfiles_branch: "master"
apply_dotfiles_restore: true   # runs sync-dotfiles.sh restore --all --yes after clone
deploy_default_configs: false  # skip the role's stock vimrc/tmux/init.vim templates

# Shell — login shell per-user (oriol → fish), fallback default_shell
default_shell: "/bin/zsh"
user_shell_overrides:
  oriol: "/usr/bin/fish"
oh_my_zsh_theme: "powerlevel10k/powerlevel10k"

# Services
install_tailscale: true
install_syncthing: true
```

Cross-platform package lists are in `group_vars/all/packages.yml`
(`packages.{base,development,extras}.{common,<distro>}`). Edit there, not in `main.yml`.

### Sensitive Data

Store sensitive data in `group_vars/all/vault.yml`:

```yaml
vault_tailscale_auth_key: "tskey-auth-..."
vault_github_token: "ghp_..."
```

Encrypt the vault:
```bash
ansible-vault encrypt group_vars/all/vault.yml
```

## Available Tags

Run specific components using tags. Each role has a primary tag and an alias:

| Role          | Tags                  |
|---------------|-----------------------|
| `base`        | `base`, `system`      |
| `shell`       | `shell`, `zsh`        |
| `ssh`         | `ssh`, `security`     |
| `development` | `development`, `dev`, `tools` |
| `dotfiles`    | `dotfiles`, `config`  |
| `extras`      | `extras`, `aur`       |
| `tailscale`   | `tailscale`, `vpn`    |
| `syncthing`   | `syncthing`, `sync`   |

Note: there is no `docker` tag — Docker is installed as part of the `development` role
(gated by `install_docker`).

Example:
```bash
ansible-playbook playbooks/site.yml --tags "shell,development"
```

## Playbooks

### site.yml
Main playbook that runs all roles based on configuration.

### bootstrap.yml
Minimal setup for preparing a system for Ansible.

### update.yml
Updates all installed packages and tools.

## Directory Structure

```
computer-init/
├── ansible.cfg              # Ansible configuration
├── bootstrap.sh             # Initial setup script
├── inventory/hosts.yml      # Inventory (defaults to localhost)
├── group_vars/all/
│   ├── main.yml             # User settings, feature flags, AUR list, SSH keys
│   ├── packages.yml         # Cross-platform package lists + package_map
│   └── vault.yml            # Encrypted secrets (create from vault.yml.example)
├── roles/
│   ├── base/                # Packages, firewall, timezone, dirs, yay (Arch)
│   ├── shell/               # Zsh + Oh My Zsh + Powerlevel10k, Fish
│   ├── ssh/                 # sshd config, authorized_keys, ssh-agent
│   ├── development/         # Dev tools, languages, Docker, VS Code, Git
│   ├── dotfiles/            # Clone dotfiles repo + sync-dotfiles.sh restore
│   ├── extras/              # Extra packages incl. AUR
│   ├── tailscale/           # Tailscale VPN
│   └── syncthing/           # File sync
└── playbooks/
    ├── site.yml             # Main playbook
    ├── bootstrap.yml        # Minimal pre-Ansible setup
    └── update.yml           # System / shell-plugin updates
```

## Customization

### Managing SSH Authorized Keys

To add SSH public keys that will be distributed to all hosts:

1. Edit `group_vars/all/main.yml`
2. Add your SSH public key to the `ssh_authorized_keys` list:

```yaml
ssh_authorized_keys:
  - key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvzwS3jm0Qa9ICBq8aAeKQdnYpAh1rrErtUGxDXYn7E"
    comment: "Fold 7"
    state: present
  - key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB..."
    comment: "Work laptop"
    state: present
  # To remove a key, set state to absent:
  - key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB..."
    comment: "Old key"
    state: absent
```

3. Run the SSH role to update all hosts:

```bash
ansible-playbook playbooks/site.yml --tags ssh --ask-become-pass
```

The keys will be managed in `~/.ssh/authorized_keys` on all target hosts.

### Adding New Packages

Edit `group_vars/all/packages.yml`:

```yaml
packages:
  base:
    common:
      - your-package
    ubuntu:
      - ubuntu-specific-package
```

### Dotfiles

The `dotfiles` role clones `dotfiles_repo` (default: `https://github.com/oriolj/dotfiles.git`)
into `dotfiles_path` and, when `apply_dotfiles_restore: true`, runs that repo's
`sync-dotfiles.sh restore --all --yes` to deploy configs into `~/`.

> **Heads up:** `sync-dotfiles.sh restore` does `rsync --delete` on tracked
> directories, so it mirrors the repo into `~/.config/...` and removes anything
> not in the repo. Safe on a fresh machine; on an existing host preview first:
> `cd $dotfiles_path && ./sync-dotfiles.sh restore --dry-run`.

To use your own dotfiles repo, override `dotfiles_repo`/`dotfiles_branch` in
`main.yml`. Set `apply_dotfiles_restore: false` to skip the restore step (the
repo will still be cloned). Set `deploy_default_configs: true` to additionally
write the role's stock `vimrc.j2` / `tmux.conf.j2` / `init.vim.j2` templates.

### Creating New Roles

1. Create role structure:
```bash
mkdir -p roles/myrole/{tasks,handlers,templates,files,vars,defaults}
```

2. Add tasks in `roles/myrole/tasks/main.yml`

3. Include in `playbooks/site.yml`:
```yaml
roles:
  - { role: myrole, tags: ['myrole'] }
```

## Troubleshooting

### Permission Issues
Run with `--ask-become-pass` if sudo password is required.

### Package Not Found
Some packages have different names across distributions. Check `group_vars/all/packages.yml` for mappings.

### Service Won't Start
Check logs:
```bash
journalctl -u service-name -f
```

## OS-Specific Notes

### macOS
- Requires Homebrew (installed by bootstrap)
- Some features require manual approval in System Preferences
- Docker Desktop must be installed separately

### Arch Linux
- AUR packages require an AUR helper
- Enable multilib repository for some packages

### WSL
- Some systemd services may not work
- Use WSL2 for better compatibility

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms if possible
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by various dotfiles repositories
- Built with Ansible best practices
- Community contributions welcome