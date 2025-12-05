default:
    @just --list

# Release a new pretalx-docker version
[group('release')]
release version:
    git pull
    git -C pretalx fetch
    git -C pretalx checkout {{ version }}
    git commit -am "Release {{ version }}"
    git tag -m "Release {{ version }}" {{ version }}
    git push --recurse-submodules=no
    git push --tags --recurse-submodules=no
