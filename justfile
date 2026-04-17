set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @just --list

# Release a new pretalx-docker version
[group('release')]
[confirm("This will push tags to origin. Continue?")]
[arg('version', pattern='v\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?')]
release version:
    git pull
    git -C pretalx fetch
    git -C pretalx checkout {{ version }}
    git commit -am "Release {{ version }}"
    git tag -m "Release {{ version }}" {{ version }}
    git push --recurse-submodules=no
    git push --tags --recurse-submodules=no
    @echo '{{ GREEN }}Release {{ version }} complete{{ NORMAL }}'
