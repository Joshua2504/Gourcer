# Gourcer (for gource)

Gourcer is a simple script that generates a gource video of all your repositories.

## Usage

1. Clone the repository in the same folder as your other repositories, e.g. ``Projects`` or whatever.
2. Make Gourcer executable: ``chmod +x gourcer.sh`` 
3. Run Gourcer: ``./gourcer.sh``

Gourcer will output a gource video including all repositories in the same folder.

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