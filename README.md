# docker-geocat
A docker image that provides the major geocat dependencies and some scripts to help you get up and running as a developer.

## Developer cheatsheet:
```bash
# Build the image from the Dockerfile
docker build -t geocat .

# Run the image, get a shell
docker run -t -i geocat /bin/bash

# Run the image, get a shell, and mount the current directory as /workspace
docker run -it --rm -v "$PWD":/workspace -w /workspace geocat /bin/bash
```

## Long-lived branches
* master - CRTM 2.0.0 (for now)
* experimental - matches master, but tracks the docker-science-stack experimental branch
* crtm_2_1_x - CRTM 2.1.x
* crtm_2_2_x - CRTM 2.2.x
