# macOS Support Guide

This project supports macOS with some limitations and specific considerations.

## Prerequisites

- macOS 10.15 (Catalina) or later
- Command Line Tools for Xcode: `xcode-select --install`
- Homebrew will be installed automatically if not present

## What Works on macOS

✅ **Fully Supported:**
- Shell setup (Zsh + Oh My Zsh)
- Development tools installation via Homebrew
- Git configuration
- VS Code installation
- Programming languages (Python, Node.js, Go, Rust)
- Modern CLI tools (ripgrep, fd, bat, exa, etc.)
- Dotfiles management
- Tailscale VPN
- Syncthing

⚠️ **Partially Supported:**
- SSH configuration (client only, macOS SSH server uses different config)
- Package installation (uses Homebrew instead of system package manager)

❌ **Not Supported:**
- Firewall configuration (macOS uses pfctl, not ufw)
- Automatic system updates (different mechanism)
- SSH server configuration (uses launchd, not systemd)
- Some Linux-specific tools

## Running on macOS

1. **Clone and setup:**
```bash
git clone https://github.com/yourusername/ansible-computer-init.git
cd ansible-computer-init
./bootstrap.sh
```

2. **Run the playbook:**
```bash
# No sudo password needed for macOS
ansible-playbook playbooks/site.yml
```

3. **Run specific components:**
```bash
# Recommended for macOS
ansible-playbook playbooks/site.yml --tags "shell,development,dotfiles"
```

## macOS-Specific Configuration

### Homebrew Packages

Edit `group_vars/all/packages.yml` to add macOS-specific packages under the `darwin:` section.

### Services

Services on macOS are managed with `brew services`:

```bash
# List services
brew services list

# Start/stop services
brew services start syncthing
brew services stop syncthing
```

### Shell Configuration

The default shell on modern macOS is already zsh, so the playbook will:
- Install Oh My Zsh
- Configure plugins and themes
- Set up your dotfiles

### Known Issues

1. **Ansible might require Python 3:**
   ```bash
   brew install python@3.11
   export PATH="/usr/local/opt/python@3.11/bin:$PATH"
   ```

2. **Some tools need manual authorization:**
   - Tailscale requires manual login after installation
   - VS Code needs accessibility permissions

3. **Terminal.app limitations:**
   - Some themes/fonts may not display correctly
   - Consider using iTerm2: `brew install --cask iterm2`

## Recommended macOS-Only Tools

Add these to your `aur_packages` equivalent for macOS:

```yaml
# In group_vars/all/main.yml
macos_cask_packages:
  - iterm2
  - rectangle  # Window management
  - alfred     # Spotlight replacement
  - docker     # Docker Desktop
  - slack
  - spotify
```

Then create a task to install them:

```yaml
- name: Install macOS applications
  homebrew_cask:
    name: "{{ item }}"
    state: present
  loop: "{{ macos_cask_packages }}"
  when: ansible_os_family == 'Darwin'
```