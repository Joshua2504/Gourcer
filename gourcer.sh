#!/bin/bash

# Gourcer - A script to generate a Gource visualization of multiple Git repositories
# Author: Joshua Tobias Treudler (Joshua2504)

# Default settings for the Gource visualization (can be overridden by config.conf)
TITLE="Development Visualization" # Title of the visualization (shown in the left-down corner)
LOGO_PATH="./sylent-logo-med.png" # Path to the logo file (shown in the right-down corner)
RESOLUTION="1280x720" # Resolution of the output video
OUTPUT_FILE="gource.mp4" # Output file name
COMPRESSION_LEVEL="20" # between 0 and 51 (lossless)
HIDE_USERNAMES=false # Set to true to hide usernames in the visualization
TIME_SCALE="1.2" # between 0.1 and 4.0
SECONDS_PER_DAY="0.4" # between 0.1 and 4.0
BACKGROUND_MUSIC="music.mp3" # Path to the background music file
AVATARS_DIR="./assets/avatars" # Directory for custom avatars
USERNAMES_FILE="usernames.conf" # Username replacements file

# Load configuration from file if it exists
if [ -f "config.conf" ]; then
    source "config.conf"
fi

# Use config variables (maintain backward compatibility with hardcoded variable names)
title="$TITLE"
logo="$LOGO_PATH"
resolution="$RESOLUTION"
output_file="$OUTPUT_FILE"
compression_level="$COMPRESSION_LEVEL"
hide_usernames="$HIDE_USERNAMES"
time_scale="$TIME_SCALE"
seconds_per_day="$SECONDS_PER_DAY"
background_music="$BACKGROUND_MUSIC"
avatars_dir="$AVATARS_DIR"
usernames_file="$USERNAMES_FILE"

# Create a temporary directory
tmp_dir="/tmp/gourcer"
mkdir -p "$tmp_dir"

# Create a directory for custom avatars
mkdir -p "$avatars_dir"

# Find all Git repositories within the parent directory and org-repos directory
repos=$(find ../ -name ".git" -type d | sed 's/\/.git//')
if [ -d "./org-repos" ]; then
    org_repos=$(find ./org-repos -name ".git" -type d | sed 's/\/.git//')
    repos="$repos $org_repos"
fi

# Generate Gource logs for each repository
for repo in $repos; do
    repo_name=$(basename "$repo")
    
    # Check if the repository has any commits
    cd "$repo"
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo "Skipping $repo_name - no commits found"
        cd - >/dev/null
        continue
    fi
    cd - >/dev/null
    
    # Try to generate gource log, skip if it fails
    if ! gource --output-custom-log - "$repo" 2>/dev/null | awk -v repo="$repo_name" 'BEGIN {FS=OFS="|"} {$4=repo "/" $4}1' > "${tmp_dir}/gource-${repo_name}.txt"; then
        echo "Skipping $repo_name - failed to generate gource log"
        rm -f "${tmp_dir}/gource-${repo_name}.txt"
        continue
    fi
    
    # Check if the log file has content
    if [ ! -s "${tmp_dir}/gource-${repo_name}.txt" ]; then
        echo "Skipping $repo_name - empty log generated"
        rm -f "${tmp_dir}/gource-${repo_name}.txt"
    fi
done

# Combine all repository logs into a single log file
if ls ${tmp_dir}/gource-*.txt >/dev/null 2>&1; then
    cat ${tmp_dir}/gource-*.txt | sort -n > ${tmp_dir}/combined.txt
else
    echo "No valid repository logs found. Exiting."
    rm -r "$tmp_dir"
    exit 1
fi

# Check if combined log has content
if [ ! -s "${tmp_dir}/combined.txt" ]; then
    echo "Combined log file is empty. No commits found in any repositories."
    rm -r "$tmp_dir"
    exit 1
fi

# Check if usernames.conf exists and read username replacements if it does
if [ -f "$usernames_file" ]; then
    while IFS='=' read -r original_username new_username; do
        sed -i '' "s/${original_username}/${new_username}/g" ${tmp_dir}/combined.txt
    done < "$usernames_file"
fi

# Check if hide_usernames is set to true and set the appropriate option
if [ "$hide_usernames" = true ]; then
    hide_option="--hide usernames"
else
    hide_option=""
fi

# Generate the Gource visualization video with the specified settings
gource ${tmp_dir}/combined.txt \
    --seconds-per-day "$seconds_per_day" \
    --auto-skip-seconds 0.1 \
    --title "$title" \
    --camera-mode overview \
    --user-friction 1 \
    --user-scale 1.1 \
    --max-user-speed 15 \
    --filename-time 3 \
    --file-font-size 8 \
    --time-scale "$time_scale" \
    --file-idle-time 0 \
    --key \
    --highlight-users \
    --highlight-dirs \
    --dir-name-position 1 \
    --dir-name-depth 10 \
    --dir-font-size 10 \
    --caption-offset 10 \
    --padding 1 \
    --logo "$logo" \
    --hide bloom \
    $hide_option \
    --user-image-dir "$avatars_dir" \
    -${resolution} -o - | \
ffmpeg -y -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf "$compression_level" -threads 0 -bf 0 -shortest "$output_file"

# Check if background music file exists and conditionally add it to the video
if [ -f "$background_music" ]; then
    ffmpeg -i "$output_file" -i "$background_music" -c:v copy -c:a aac -strict experimental -shortest "temp_$output_file"
    if [ -f "temp_$output_file" ]; then
        mv "temp_$output_file" "$output_file"
    fi
fi

# Delete the temporary directory
rm -r "$tmp_dir"