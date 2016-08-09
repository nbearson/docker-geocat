# docker-geocat
A docker image that provides the major geocat dependencies and some scripts to help you get up and running as a developer.

Cheatsheet:
```bash
# Build the image from the Dockerfile
docker build -t geocat .

# Run the image, get a shell
docker run -t -i geocat /bin/bash

# Run the image, get a shell, and mount the current directory as /workspace
docker run -it --rm -v "$PWD":/workspace -w /workspace geocat /bin/bash
```
