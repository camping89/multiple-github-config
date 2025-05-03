#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Multiple GitHub Accounts Setup ===${NC}"
echo -e "This script will help you set up your environment for multiple GitHub accounts."
echo ""

# Check if SSH config exists
SSH_CONFIG_PATH="$HOME/.ssh/config"
if [ -f "$SSH_CONFIG_PATH" ]; then
  echo -e "${GREEN}SSH config file exists at $SSH_CONFIG_PATH${NC}"
  echo "We'll add to this file. Make sure to backup if needed."
else
  echo -e "${GREEN}Creating SSH config file at $SSH_CONFIG_PATH${NC}"
  mkdir -p "$HOME/.ssh"
  touch "$SSH_CONFIG_PATH"
  chmod 600 "$SSH_CONFIG_PATH"
fi

# Ask about global git config
echo ""
echo -e "${BLUE}Step 1: Git Global Configuration${NC}"
echo "Do you want to disable global user name and email? (Recommended for multiple accounts)"
read -p "Disable global Git user config? (y/n): " DISABLE_GLOBAL

if [ "$DISABLE_GLOBAL" == "y" ] || [ "$DISABLE_GLOBAL" == "Y" ]; then
  echo "Removing global Git user configuration..."
  git config --global --unset user.name
  git config --global --unset user.email
  git config --global --add user.useConfigOnly true
  echo -e "${GREEN}Global user configuration disabled.${NC}"
else
  echo "Keeping global Git user configuration."
fi

# Setup SSH keys
echo ""
echo -e "${BLUE}Step 2: SSH Key Setup${NC}"
echo "Let's set up SSH keys for your accounts."

# Function to setup an account
setup_account() {
  local account_name=$1
  local default=$2
  
  echo ""
  echo -e "${BLUE}Setting up $account_name account${NC}"
  
  # Get email
  read -p "Enter your $account_name GitHub email: " GITHUB_EMAIL
  
  # Generate key name
  local keyname="github_${account_name,,}"
  local keypath="$HOME/.ssh/$keyname"
  
  # Ask about existing key
  if [ -f "$keypath" ]; then
    echo "SSH key already exists at $keypath"
    read -p "Use existing key? (y/n): " USE_EXISTING
    
    if [ "$USE_EXISTING" != "y" ] && [ "$USE_EXISTING" != "Y" ]; then
      read -p "Generate new key? This will overwrite the existing key (y/n): " GENERATE_NEW
      if [ "$GENERATE_NEW" == "y" ] || [ "$GENERATE_NEW" == "Y" ]; then
        ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$keypath"
      else
        echo "Skipping key generation for $account_name"
      fi
    fi
  else
    # Generate new key
    echo "Generating new SSH key for $account_name..."
    ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$keypath"
  fi
  
  # Add key to agent
  ssh-add "$keypath" 2>/dev/null
  
  # Add to SSH config
  local host_alias="github.com"
  if [ "$default" != "true" ]; then
    host_alias="github.com-${account_name,,}"
  fi
  
  # Check if entry already exists
  if grep -q "Host $host_alias" "$SSH_CONFIG_PATH"; then
    echo "Configuration for $host_alias already exists in SSH config."
  else
    echo "Adding configuration to SSH config..."
    
    echo "" >> "$SSH_CONFIG_PATH"
    echo "# $account_name GitHub account" >> "$SSH_CONFIG_PATH"
    echo "Host $host_alias" >> "$SSH_CONFIG_PATH"
    echo "    HostName github.com" >> "$SSH_CONFIG_PATH"
    echo "    User git" >> "$SSH_CONFIG_PATH"
    echo "    IdentityFile $keypath" >> "$SSH_CONFIG_PATH"
    echo "    IdentitiesOnly yes" >> "$SSH_CONFIG_PATH"
    echo "    AddKeysToAgent yes" >> "$SSH_CONFIG_PATH"
    echo "    UseKeychain yes" >> "$SSH_CONFIG_PATH"
  fi
  
  # Display public key
  echo ""
  echo -e "${GREEN}SSH key generated for $account_name:${NC}"
  echo -e "${RED}Add this public key to your GitHub account:${NC}"
  cat "${keypath}.pub"
  echo ""
  echo "To add this key to GitHub:"
  echo "1. Copy the key above"
  echo "2. Go to GitHub → Settings → SSH and GPG keys → New SSH key"
  echo "3. Paste the key and save"
  
  # Ask to wait
  read -p "Press Enter once you've added the key to GitHub... "
  
  # Test connection
  if [ "$default" == "true" ]; then
    echo "Testing connection to GitHub with default account..."
    ssh -T git@github.com
  else
    echo "Testing connection to GitHub with $account_name account..."
    ssh -T git@"$host_alias"
  fi
}

# Setup default account
read -p "Set up your default GitHub account? (y/n): " SETUP_DEFAULT
if [ "$SETUP_DEFAULT" == "y" ] || [ "$SETUP_DEFAULT" == "Y" ]; then
  read -p "What do you want to call this account? (e.g., personal): " DEFAULT_NAME
  setup_account "$DEFAULT_NAME" "true"
fi

# Setup additional accounts
while true; do
  read -p "Add another GitHub account? (y/n): " ADD_ANOTHER
  if [ "$ADD_ANOTHER" != "y" ] && [ "$ADD_ANOTHER" != "Y" ]; then
    break
  fi
  
  read -p "What do you want to call this account? (e.g., work): " ACCOUNT_NAME
  setup_account "$ACCOUNT_NAME" "false"
done

# Create git-account helper script
echo ""
echo -e "${BLUE}Step 3: Creating helper script${NC}"
echo "Creating git-account helper script..."

HELPER_SCRIPT="$HOME/bin/git-account"
mkdir -p "$HOME/bin"

cat > "$HELPER_SCRIPT" << 'EOF'
#!/bin/bash

# Help text
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ $# -eq 0 ]; then
  echo "Usage: git-account <account-name> [<email>]"
  echo ""
  echo "Sets the local git repository user name and email"
  echo ""
  echo "Arguments:"
  echo "  account-name   Name of the account (e.g., personal, work)"
  echo "  email          Optional: Email to use (if not provided, will use previously set email)"
  echo ""
  exit 0
fi

# Set git config for the repository
ACCOUNT=$1
EMAIL=$2

if [ -z "$EMAIL" ]; then
  git config user.name "$ACCOUNT"
  echo "Set user.name to $ACCOUNT"
  echo "Email unchanged"
else
  git config user.name "$ACCOUNT"
  git config user.email "$EMAIL"
  echo "Set user.name to $ACCOUNT"
  echo "Set user.email to $EMAIL"
fi

# Show current config
echo ""
echo "Current repository git config:"
echo "user.name: $(git config user.name)"
echo "user.email: $(git config user.email)"
echo ""
echo "To verify origin, check:"
echo "$(git remote -v)"
EOF

chmod +x "$HELPER_SCRIPT"

echo -e "${GREEN}Helper script created at $HELPER_SCRIPT${NC}"
echo "Add this directory to your PATH if it's not already there."
echo "You can now use 'git-account <name> <email>' in any repository to set the user."

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo "Remember to use the correct git remote URL format for each account:"
echo "- Default account: git@github.com:username/repo.git"
echo "- Other accounts: git@github.com-accountname:username/repo.git"
echo ""
echo "For example, to clone a repository with your work account:"
echo "git clone git@github.com-work:username/repo.git"
echo ""
echo "And set the user for each repository:"
echo "cd repo"
echo "git-account work work@email.com"
echo ""
echo "Thank you for using this setup script!"
