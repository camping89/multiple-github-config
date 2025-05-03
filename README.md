# Managing Multiple GitHub Accounts

This guide explains how to set up multiple GitHub accounts on a single machine using SSH keys and repository-specific Git configurations.

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/camping89/multiple-github-config.git
   cd multiple-github-config
   ```

2. Run the setup script (macOS/Linux):
   ```bash
   ./setup.sh
   ```
   This will guide you through the process.

3. For manual setup, follow the detailed instructions below.

## 1. Disable Global Git Config

To ensure you use different identities for different repositories, unset global user settings:

```bash
git config --global --unset user.name
git config --global --unset user.email
```

Enforce configuration for each repository:

```bash
git config --global --add user.useConfigOnly true
```

## 2. Create and Configure SSH Keys

### Generate SSH Keys

For each GitHub account, create a separate SSH key:

```bash
# For personal account
ssh-keygen -t ed25519 -C "personal@email.com" -f ~/.ssh/personal_github

# For work account
ssh-keygen -t ed25519 -C "work@email.com" -f ~/.ssh/work_github

# For another account
ssh-keygen -t ed25519 -C "another@email.com" -f ~/.ssh/another_github
```

### Add SSH Keys to SSH Agent

```bash
ssh-add ~/.ssh/personal_github
ssh-add ~/.ssh/work_github
ssh-add ~/.ssh/another_github
```

Verify keys are loaded:

```bash
ssh-add -l
```

### Add SSH Keys to GitHub Accounts

1. Copy the public key content:
   ```bash
   cat ~/.ssh/personal_github.pub
   ```

2. Go to GitHub → Settings → SSH and GPG keys → New SSH key
3. Paste the key and save
4. Repeat for each GitHub account

### Configure SSH Config File

Edit `~/.ssh/config`:

```bash
# Create or edit config file
nano ~/.ssh/config
```

Add configurations for each account (see `ssh_config_sample` in this repo):

```
# Personal GitHub account
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/personal_github
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes

# Work GitHub account
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/work_github
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes

# Another GitHub account
Host github.com-another
    HostName github.com
    User git
    IdentityFile ~/.ssh/another_github
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes
```

#### Understanding SSH Config Options

Each option in the SSH config serves a specific purpose:

- **Host**: The alias you'll use in git commands. This is what differs between your accounts. Use `github.com` for your primary account and custom names like `github.com-work` for additional accounts.

- **HostName**: The actual server address you're connecting to. For GitHub, this is always `github.com`.

- **User**: The username for SSH authentication to GitHub. This is always `git` for all GitHub accounts.

- **IdentityFile**: Path to your private SSH key for this specific account.

- **IdentitiesOnly**: When set to `yes`, forces SSH to only use the specified identity file for this host. This is critical for preventing authentication confusion when you have multiple keys.

- **AddKeysToAgent**: When set to `yes`, automatically adds the key to the SSH agent when used.

- **UseKeychain**: macOS specific option that allows storing your passphrase in the keychain (not needed on Linux).

Test your SSH connections:

```bash
ssh -T git@github.com
ssh -T git@github.com-work
ssh -T git@github.com-another
```

## 3. Update Git Remote Origin

For existing repositories, update the remote URL based on the SSH config:

```bash
# For personal account (default github.com)
git remote set-url origin git@github.com:username/repository.git

# For work account
git remote set-url origin git@github.com-work:username/repository.git

# For another account
git remote set-url origin git@github.com-another:username/repository.git
```

When cloning new repositories:

```bash
# For personal account
git clone git@github.com:username/repository.git

# For work account
git clone git@github.com-work:username/repository.git

# For another account
git clone git@github.com-another:username/repository.git
```

## 4. Set Repository-Specific User Information

For each repository, configure the appropriate user information:

```bash
# Navigate to your repository
cd /path/to/repository

# Set user information for this repository only
git config user.name "my username"
git config user.email "my@user.email"
```

### Verify Configuration

Confirm your settings are correctly applied:

```bash
git config --show-origin user.name
git config --show-origin user.email
```

These commands should show that the configuration is stored in your repository's `.git/config` file.

## 5. Working with Multiple Repositories

Remember to set user information for each new repository you create or clone:

```bash
# After creating/cloning a new repository
cd /path/to/new/repository
git config user.name "Appropriate Username"
git config user.email "appropriate@email.com"
```

## Sample Files

This repository includes:

- `ssh_config_sample`: Example SSH config file with detailed explanations
- `setup.sh`: Interactive setup script
- `git-account`: Helper script to switch between accounts in any repository

## Troubleshooting

- **Wrong account being used?** Check your remote URL with `git remote -v` and ensure it matches the correct Host in your SSH config
- **Permission denied?** Verify your SSH key is added to the correct GitHub account
- **SSH connection issues?** Test with verbose output: `ssh -vT git@github.com-work`
- **Key authentication failures?** Make sure `IdentitiesOnly yes` is set in your SSH config to prevent trying other keys
- **Changes attributed to wrong user?** Verify repository-specific git config with `git config --list` in the repository directory

By following these steps, you can seamlessly work with multiple GitHub accounts on a single machine.
