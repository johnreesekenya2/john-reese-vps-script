
#!/bin/bash

# JOHN REESE VPS - Push to GitHub Script
# Uses GitHub API client to upload changes

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}🚀 JOHN REESE VPS - GitHub Push${NC}"
echo -e "${WHITE}═══════════════════════════════${NC}"

# Check if GitHub token is set
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo -e "${BLUE}ℹ️ Setting up GitHub token...${NC}"
    echo "Please enter your GitHub Personal Access Token:"
    read -s GITHUB_TOKEN
    export GITHUB_TOKEN
fi

# Make github client executable
chmod +x bin/github-api-client

echo -e "${BLUE}ℹ️ Uploading VPS nginx configuration...${NC}"
./bin/github-api-client upload vps-nginx.conf "Add VPS nginx configuration"

echo -e "${BLUE}ℹ️ Uploading VPS nginx installer...${NC}"
./bin/github-api-client upload install-vps-nginx.sh "Add VPS nginx installer script"

echo -e "${BLUE}ℹ️ Uploading nginx reset script...${NC}"
./bin/github-api-client upload reset-nginx.sh "Add nginx reset utility"

echo -e "${BLUE}ℹ️ Uploading entire project directory...${NC}"
./bin/github-api-client upload-dir . "Update JOHN REESE VPS with latest changes"

echo -e "${GREEN}✅ All changes pushed to GitHub successfully!${NC}"
echo -e "${WHITE}Repository: https://github.com/johnreesekenya2/john-reese-vps-script${NC}"
