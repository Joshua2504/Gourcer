# Gourcer (for gource)

Gourcer is a simple script that generates a [Gource](https://github.com/acaudwell/Gource) video of all your repositories.

## Usage

1. Clone the repository in the same folder as your other repositories, e.g. ``Projects`` or whatever.
2. Make Gourcer executable: ``chmod +x gourcer.sh`` 
3. Run Gourcer: ``./gourcer.sh``

Gourcer will output a gource video including all repositories in the same folder.

## Configuration

Gourcer uses a unified configuration file that works for both repository downloading and visualization. 

### Setup

1. Copy the configuration template: `cp config.conf.example config.conf`
2. Edit `config.conf` and customize the settings for your needs

The configuration file includes settings for:
- GitHub organization repository downloading 
- Gource visualization parameters
- Paths for logos, music, avatars, etc.

## Organization Repository Download

For visualizing all repositories from a GitHub organization, you can use the included download script:

### Quick Setup

1. Set your GitHub organization name in `config.conf`:
   ```bash
   GITHUB_ORG="your-organization-name"
   ```
2. Optionally, add a GitHub personal access token for private repos and higher rate limits:
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

### Customize User Display Names

You can create a `usernames.conf` file (or set a different path in `config.conf`) to override usernames in the visualization:

```
Joshua Treudler=Francis
Tobias=Knight
```

`Joshua Treudler` would be displayed as *Francis*, `Tobias` as *Knight*.

### Background Music

You may configure background music in `config.conf`:

```bash
BACKGROUND_MUSIC="music.mp3"
```

You can use `ffmpeg` to convert most file formats to mp3:

```bash
ffmpeg -i music.ogg music.mp3
```

### Advanced Configuration

The `config.conf` file allows you to customize many aspects of the visualization including:
- Video resolution and compression
- Animation timing and speed
- Logo and avatar paths  
- Output filename
- And much more...
