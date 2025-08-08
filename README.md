# Gourcer (for gource)

Gourcer is a simple script that generates a [Gource](https://github.com/acaudwell/Gource) video of all your repositories.

## Usage

1. Clone the repository in the same folder as your other repositories, e.g. ``Projects`` or whatever.
2. Make Gourcer executable: ``chmod +x gourcer.sh`` 
3. Run Gourcer: ``./gourcer.sh``

Gourcer will output a gource video including all repositories in the same folder.

## Organization Repository Download

For visualizing all repositories from a GitHub organization, you can use the included download script:

### Setup

1. Copy the configuration template: `cp org-config.conf.example org-config.conf`
2. Edit `org-config.conf` and set your GitHub organization name:
   ```bash
   GITHUB_ORG="your-organization-name"
   ```
3. Optionally, add a GitHub personal access token for private repos and higher rate limits:
   ```bash
   GITHUB_TOKEN="your-github-token"
   ```

### Download Organization Repositories

#### Option 1: All-in-One (Recommended)

Run the complete workflow with one command:
```bash
chmod +x visualize-org.sh
./visualize-org.sh
```

This will download all repositories and generate the visualization automatically.

#### Option 2: Step-by-Step

1. Make the download script executable: `chmod +x download-org-repos.sh`
2. Run the download script: `./download-org-repos.sh`
3. Run Gourcer to visualize all repositories: `./gourcer.sh`

The download script will:
- Fetch all repositories from your specified GitHub organization
- Clone them into the `org-repos` directory
- **Keep only .git folders by default** (saves significant disk space - Gource only needs git history)
- Skip repositories that already exist locally (configurable)
- Support both HTTPS and SSH cloning
- Provide colored output with progress information

### Dependencies for Organization Download

The download script requires:
- `curl` - for GitHub API requests
- `jq` - for JSON parsing
- `git` - for repository cloning

On macOS, install with: `brew install curl jq git`

## Additional Options

### Overwrite Usernames

You can create a ``username.conf`` file to overwrite usernames, for example:

```
Joshua Treudler=Francis
Tobias=Knight
```

``Joshua Treudler`` would be displayed as *Francis*, ``Tobias`` as *Knight*.

### Background Music

You may set ``background_music`` to anything, for example:

```
background_music="music.mp3"
```

You can use ``ffmpeg`` to convert most file formats to mp3, e.g.:

```
ffmpeg -i music.ogg music.mp3
```
