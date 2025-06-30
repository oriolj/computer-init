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
- Zsh installation and configuration
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
- **Dotfiles**: Configuration management

## Quick Start

### Prerequisites

- A supported operating system
- sudo/admin access
- Internet connection

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/ansible-computer-init.git
cd ansible-computer-init
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
user: "{{ ansible_user_id }}"
dotfiles_repo: "https://github.com/yourusername/dotfiles.git"

# Shell configuration  
oh_my_zsh_theme: "powerlevel10k/powerlevel10k"
oh_my_zsh_plugins:
  - git
  - docker
  - kubectl

# Development tools
languages:
  - python
  - nodejs
  - go
  - rust

# Services
install_tailscale: true
install_syncthing: true
```

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

Run specific components using tags:

- `base` - Base system configuration
- `shell` - Zsh and Oh My Zsh setup
- `ssh` - SSH server configuration
- `development` - Development tools
- `docker` - Docker installation
- `dotfiles` - Dotfiles management
- `tailscale` - Tailscale VPN
- `syncthing` - File synchronization

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
ansible-computer-init/
├── ansible.cfg              # Ansible configuration
├── bootstrap.sh             # Initial setup script
├── inventory/               # Inventory configuration
├── group_vars/              # Variables
│   └── all/
│       ├── main.yml        # Main configuration
│       ├── packages.yml    # Package definitions
│       └── vault.yml       # Encrypted secrets
├── roles/                   # Ansible roles
│   ├── base/               # Base system setup
│   ├── shell/              # Shell configuration
│   ├── ssh/                # SSH setup
│   ├── development/        # Dev tools
│   ├── dotfiles/           # Dotfiles management
│   ├── tailscale/          # Tailscale VPN
│   └── syncthing/          # File sync
└── playbooks/              # Playbooks
```

## Customization

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