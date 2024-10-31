#!/bin/bash

# Define the Gource visualization settings
# More settings can be set directly in the Gource command below
title="Development Visualization"
resolution="600x338"
output_file="gource.mp4"

# Create a temporary directory within the project directory
tmp_dir="/tmp/gourcer"
mkdir -p "$tmp_dir"

# Find all Git repositories in the parent directory
repos=$(find ../ -name ".git" -type d | sed 's/\/.git//')

# Generate Gource logs for each repository
for repo in $repos; do
    repo_name=$(basename "$repo")
    gource --output-custom-log "${tmp_dir}/gource-${repo_name}.txt" "$repo"
done

# Combine all Gource logs into one
cat ${tmp_dir}/gource-* | sort -n > ${tmp_dir}/combined.txt

# Generate the Gource visualization video
gource ${tmp_dir}/combined.txt --seconds-per-day 5 --auto-skip-seconds 0.1 --title "$title" --disable-auto-rotate --camera-mode overview --user-friction 1 --max-user-speed 15 --filename-time 5 --highlight-users --time-scale 4 --user-scale 1.2 --hide usernames -${resolution} -o - | \
ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 "$output_file"

# Delete the custom logs
rm -r "$tmp_dir"
