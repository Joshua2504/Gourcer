#!/bin/bash

# Gourcer - A script to generate a Gource visualization of multiple Git repositories
# Author: Joshua Tobias Treudler (Joshua2504)

# Settings for the Gource visualization
title="Development Visualization" # Title of the visualization (shown in the left-down corner)
resolution="1280x720" # Resolution of the output video
output_file="gource.mp4" # Output file name
compression_level="20" # between 0 and 51 (lossless)
hide_usernames=false # Set to true to hide usernames in the visualization
time_scale="1" # between 0.1 and 4.0
seconds_per_day="0.5" # between 0.1 and 4.0
background_music="music.mp3" # Path to the background music file

# Create a temporary directory
tmp_dir="/tmp/gourcer"
mkdir -p "$tmp_dir"

# Create a directory for custom avatars
avatars_dir="./avatars"
mkdir -p "$avatars_dir"

# Find all Git repositories within the parent directory
repos=$(find ../ -name ".git" -type d | sed 's/\/.git//')

# Generate Gource logs for each repository
for repo in $repos; do
    repo_name=$(basename "$repo")
    gource --output-custom-log "${tmp_dir}/gource-${repo_name}.txt" "$repo"
done

# Combine all repository logs into a single log file
cat ${tmp_dir}/gource-* | sort -n > ${tmp_dir}/combined.txt

# Check if usernames.conf exists and read username replacements if it does
if [ -f usernames.conf ]; then
    while IFS='=' read -r original_username new_username; do
        sed -i '' "s/${original_username}/${new_username}/g" ${tmp_dir}/combined.txt
    done < usernames.conf
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
    --disable-auto-rotate \
    --camera-mode overview \
    --user-friction 1 \
    --user-scale 1 \
    --max-user-speed 15 \
    --filename-time 5 \
    --time-scale "$time_scale" \
    --file-idle-time 0 \
    --key \
    --highlight-users \
    --highlight-dirs \
    --dir-name-position 1 \
    --dir-name-depth 10 \
    --caption-offset 5 \
    --padding 1 \
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