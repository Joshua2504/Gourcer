#!/bin/bash

# Download Organization Repositories Script
# This script downloads all repositories from a GitHub organization
# Author: GitHub Copilot (based on Gourcer by Joshua2504)

# Default Configuration
GITHUB_ORG=""  # Set your GitHub organization name here
GITHUB_TOKEN=""  # Optional: Set your GitHub personal access token for private repos and higher rate limits
CLONE_DIR="./org-repos"  # Directory where repositories will be cloned
USE_SSH=false  # Set to true to use SSH instead of HTTPS for cloning
SKIP_EXISTING=true  # Set to true to skip repositories that already exist locally
GIT_ONLY=true  # Set to true to keep only .git folder (saves disk space, sufficient for Gource)

# Load configuration from file if it exists
if [ -f "org-config.conf" ]; then
    source "org-config.conf"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_error "Please install them and try again."
        print_error "On macOS: brew install curl jq git"
        exit 1
    fi
}

# Function to get GitHub API URL with authentication if token is provided
get_github_api_url() {
    local endpoint="$1"
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "https://api.github.com$endpoint"
    else
        echo "https://api.github.com$endpoint"
    fi
}

# Function to make GitHub API request with optional authentication
github_api_request() {
    local url="$1"
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -s -H "Authorization: token $GITHUB_TOKEN" "$url"
    else
        curl -s "$url"
    fi
}

# Function to validate organization name
validate_organization() {
    if [ -z "$GITHUB_ORG" ]; then
        print_error "GitHub organization name is not set!"
        print_error "Please edit this script and set the GITHUB_ORG variable."
        exit 1
    fi
    
    print_status "Checking if organization '$GITHUB_ORG' exists..."
    local org_url=$(get_github_api_url "/orgs/$GITHUB_ORG")
    local org_response=$(github_api_request "$org_url")
    
    if echo "$org_response" | jq -e '.message == "Not Found"' > /dev/null 2>&1; then
        print_error "Organization '$GITHUB_ORG' not found!"
        print_error "Please check the organization name and try again."
        exit 1
    fi
    
    print_success "Organization '$GITHUB_ORG' found!"
}

# Function to get all repositories from the organization
get_repositories() {
    print_status "Fetching repositories from organization '$GITHUB_ORG'..."
    
    local repos=()
    local page=1
    local per_page=100
    
    while true; do
        local repos_url=$(get_github_api_url "/orgs/$GITHUB_ORG/repos?page=$page&per_page=$per_page")
        local page_repos=$(github_api_request "$repos_url")
        
        # Check if the response contains an error
        if echo "$page_repos" | jq -e '.message' > /dev/null 2>&1; then
            local error_message=$(echo "$page_repos" | jq -r '.message')
            print_error "GitHub API error: $error_message"
            exit 1
        fi
        
        # Check if we got any repositories on this page
        local repo_count=$(echo "$page_repos" | jq length)
        if [ "$repo_count" -eq 0 ]; then
            break
        fi
        
        # Add repositories from this page to our array
        while IFS= read -r repo; do
            repos+=("$repo")
        done < <(echo "$page_repos" | jq -r '.[] | @base64')
        
        page=$((page + 1))
    done
    
    echo "${repos[@]}"
}

# Function to clone a repository
clone_repository() {
    local repo_data="$1"
    local repo_json=$(echo "$repo_data" | base64 --decode)
    
    local repo_name=$(echo "$repo_json" | jq -r '.name')
    local repo_clone_url
    local repo_default_branch=$(echo "$repo_json" | jq -r '.default_branch')
    
    if [ "$USE_SSH" = true ]; then
        repo_clone_url=$(echo "$repo_json" | jq -r '.ssh_url')
    else
        repo_clone_url=$(echo "$repo_json" | jq -r '.clone_url')
    fi
    
    local repo_path="$CLONE_DIR/$repo_name"
    
    # Check if repository already exists
    if [ -d "$repo_path" ] && [ "$SKIP_EXISTING" = true ]; then
        print_warning "Repository '$repo_name' already exists, skipping..."
        return 0
    fi
    
    print_status "Cloning repository '$repo_name'$([ "$GIT_ONLY" = true ] && echo " (git history only)" || echo "")..."
    
    # Create clone directory if it doesn't exist
    mkdir -p "$CLONE_DIR"
    
    # Clone the repository
    if git clone "$repo_clone_url" "$repo_path" > /dev/null 2>&1; then
        # Optionally keep only the .git folder to save disk space
        if [ "$GIT_ONLY" = true ]; then
            print_status "Removing source files from '$repo_name' (keeping only .git folder)..."
            
            # Remove all files and folders except .git
            find "$repo_path" -mindepth 1 -name '.git' -prune -o -exec rm -rf {} + 2>/dev/null || true
            
            print_success "Successfully prepared '$repo_name' for Gource (git history only)"
        else
            print_success "Successfully cloned '$repo_name'"
        fi
    else
        print_error "Failed to clone repository '$repo_name'"
        return 1
    fi
}

# Function to display summary
display_summary() {
    local total_repos="$1"
    local successful_clones="$2"
    local failed_clones="$3"
    
    echo
    echo "========================="
    echo "DOWNLOAD SUMMARY"
    echo "========================="
    echo "Organization: $GITHUB_ORG"
    echo "Total repositories: $total_repos"
    echo "Successfully cloned: $successful_clones"
    echo "Failed to clone: $failed_clones"
    echo "Clone directory: $CLONE_DIR"
    echo "Git history only: $([ "$GIT_ONLY" = true ] && echo "Yes (disk space optimized)" || echo "No (full repositories)")"
    echo
    
    if [ "$successful_clones" -gt 0 ]; then
        print_success "Repositories are ready for Gourcer visualization!"
        print_status "You can now run './gourcer.sh' to generate a visualization of all repositories."
        
        if [ "$GIT_ONLY" = true ]; then
            print_status "Disk space optimized: Only git history kept (sufficient for Gource)."
        fi
    fi
}

# Main execution
main() {
    echo "================================================"
    echo "GitHub Organization Repository Downloader"
    echo "================================================"
    echo
    
    # Check dependencies
    check_dependencies
    
    # Validate organization
    validate_organization
    
    # Get all repositories
    local all_repos=($(get_repositories))
    local total_repos=${#all_repos[@]}
    
    if [ "$total_repos" -eq 0 ]; then
        print_warning "No repositories found in organization '$GITHUB_ORG'"
        exit 0
    fi
    
    print_success "Found $total_repos repositories in organization '$GITHUB_ORG'"
    echo
    
    # Clone repositories
    local successful_clones=0
    local failed_clones=0
    
    for repo_data in "${all_repos[@]}"; do
        if clone_repository "$repo_data"; then
            successful_clones=$((successful_clones + 1))
        else
            failed_clones=$((failed_clones + 1))
        fi
    done
    
    # Display summary
    display_summary "$total_repos" "$successful_clones" "$failed_clones"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
