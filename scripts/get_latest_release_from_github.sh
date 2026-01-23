#!/bin/bash

# Variables
# GITHUB_REPO_OWNER="rustdesk"   # Replace with the owner of the repository
# GITHUB_REPO_NAME="rustdesk"     # Replace with the name of the repository
# LOOKING_FOR="x86_64.deb"

GITHUB_REPO_OWNER="balena-io"   # Replace with the owner of the repository
GITHUB_REPO_NAME="etcher"     # Replace with the name of the repository
LOOKING_FOR="amd64.deb"

GITHUB_API_URL="https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/releases/latest"

# Function to fetch the latest release
fetch_latest_release() {
  echo "Fetching the latest release from $GITHUB_REPO_OWNER/$GITHUB_REPO_NAME..."

  # Make a request to the GitHub API
  response=$(curl -s "$GITHUB_API_URL")
  
  # Check if the GitHub API response is valid JSON
  if [[ $? -ne 0 || -z "$response" || "$(echo "$response" | jq -r '.message')" == "Not Found" ]]; then
    echo "Error: Failed to fetch release information or repository not found."
    exit 1
  fi

  echo "Looking for $LOOKING_FOR"

  # Parse the release information using jq
  tag_name=$(echo "$response" | jq -r '.tag_name // empty')
  deb_url=$(echo "$response" | jq -r '.assets[]? | select(.name | endswith("'"$LOOKING_FOR"'")) | .browser_download_url')

  # Check if a release tag was found
  if [[ -z "$tag_name" ]]; then
    echo "Error: No release tag found."
    exit 1
  fi

  # Check if a .deb file for x86_64 architecture was found
  if [[ -z "$deb_url" ]]; then
    echo "Error: No $LOOKING_FOR package found in the latest release."
    exit 1
  fi

  echo "Latest release tag: $tag_name"
  echo "Download URL for $LOOKING_FOR package: $deb_url"

  # Download the .deb package
  echo "Downloading the .deb package..."
  deb_file="${deb_url##*/}"
  curl -LO "$deb_url"

  # Verify if the download was successful
  if [[ ! -f "$deb_file" ]]; then
    echo "Error: Failed to download the .deb package."
    exit 1
  fi

  # Install the .deb package
  echo "Installing the .deb package..."
  sudo dpkg -i "$deb_file"

  # Check if the installation was successful
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to install the .deb package. You might need to fix dependencies manually using 'sudo apt-get -f install'."
    exit 1
  fi

  # Delete the .deb package
  echo "Cleaning up: Deleting the .deb package..."
  rm -f "$deb_file"

  echo "Installation of $deb_file completed successfully!"


}

# Call the function
fetch_latest_release