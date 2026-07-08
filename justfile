set shell := ["bash", "-euo", "pipefail", "-c"]
set quiet
set fallback
set default-list

# Release a new pretalx-docker version
[arg('version', pattern='v\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?')]
[confirm("This will push tags to origin. Continue?")]
[group('release')]
release version:
    git pull
    git -C pretalx fetch
    git -C pretalx checkout {{ version }}
    git commit -am "Release {{ version }}"
    git tag -m "Release {{ version }}" {{ version }}
    git push --recurse-submodules=no
    git push --tags --recurse-submodules=no
    @echo '{{ GREEN }}Release {{ version }} complete{{ NORMAL }}'
