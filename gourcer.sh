#!/bin/bash

# Define the Gource visualization settings
title="Development Visualization"
resolution="1280x720"
output_file="gource.mp4"
compression_level="20"
hide_usernames=false
time_scale="1"  # max is 4
seconds_per_day="1.5"

# Create a temporary directory within the project directory
tmp_dir="/tmp/gourcer"
mkdir -p "$tmp_dir"

# Create a directory for custom avatars
avatars_dir="./avatars"
mkdir -p "$avatars_dir"

# Find all Git repositories in the parent directory
repos=$(find ../ -name ".git" -type d | sed 's/\/.git//')

# Generate Gource logs for each repository
for repo in $repos; do
    repo_name=$(basename "$repo")
    gource --output-custom-log "${tmp_dir}/gource-${repo_name}.txt" "$repo"
done

# Combine all Gource logs into one
cat ${tmp_dir}/gource-* | sort -n > ${tmp_dir}/combined.txt

# Check if usernames.conf exists and read username replacements if it does
if [ -f usernames.conf ]; then
    while IFS='=' read -r original_username new_username; do
        sed -i '' "s/${original_username}/${new_username}/g" ${tmp_dir}/combined.txt
    done < usernames.conf
fi

# Determine the hide usernames option
if [ "$hide_usernames" = true ]; then
    hide_option="--hide usernames"
else
    hide_option=""
fi

# Generate the Gource visualization video with additional details
gource ${tmp_dir}/combined.txt \
    --seconds-per-day "$seconds_per_day" \
    --auto-skip-seconds 1 \
    --title "$title" \
    --disable-auto-rotate \
    --camera-mode overview \
    --user-friction 1 \
    --max-user-speed 15 \
    --filename-time 3 \
    --highlight-users \
    --time-scale "$time_scale" \
    --user-scale 1 \
    --file-idle-time 0 \
    --highlight-dirs \
    --dir-name-depth 2 \
    --key \
    --highlight-users \
    --highlight-dirs \
    --dir-name-position 1 \
    --dir-name-depth 3 \
    $hide_option \
    --user-image-dir "$avatars_dir" \
    -${resolution} -o - | \
ffmpeg -y -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf "$compression_level" -threads 0 -bf 0 "$output_file"

# Delete the custom logs
rm -r "$tmp_dir"
