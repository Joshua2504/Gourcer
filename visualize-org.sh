#!/bin/bash

# Gourcer Organization Visualizer
# This script downloads all repositories from a GitHub organization and creates a Gource visualization
# Author: GitHub Copilot (based on Gourcer by Joshua2504)

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if configuration file exists
if [ ! -f "org-config.conf" ]; then
    print_error "Configuration file 'org-config.conf' not found!"
    print_error "Please copy 'org-config.conf.example' to 'org-config.conf' and configure it."
    exit 1
fi

# Load configuration
source "org-config.conf"

if [ -z "$GITHUB_ORG" ]; then
    print_error "GITHUB_ORG is not set in org-config.conf"
    exit 1
fi

echo "================================================"
echo "Gourcer Organization Visualizer"
echo "================================================"
echo "Organization: $GITHUB_ORG"
echo

# Step 1: Download repositories
print_status "Step 1: Downloading repositories from GitHub organization..."
if ./download-org-repos.sh; then
    print_success "Successfully downloaded repositories"
else
    print_error "Failed to download repositories"
    exit 1
fi

echo

# Step 2: Generate visualization
print_status "Step 2: Generating Gource visualization..."
if ./gourcer.sh; then
    print_success "Successfully generated Gource visualization!"
    print_success "Output file: gource.mp4"
else
    print_error "Failed to generate Gource visualization"
    exit 1
fi

echo
echo "================================================"
echo "Visualization Complete!"
echo "================================================"
echo "Your Gource visualization is ready: gource.mp4"
