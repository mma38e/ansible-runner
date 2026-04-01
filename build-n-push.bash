#!/bin/bash
set -euo pipefail
# build-n-push.bash — build and push the ansible-runner container to Docker Hub

## VARIABLES — override via environment or edit defaults below
DOCKER_HUB_USER=${DOCKER_HUB_USER:=mma38e}
IMAGE_NAME=${IMAGE_NAME:=ansible-runner}
WORKING_DIR=${WORKING_DIR:=$(pwd)}

source "${WORKING_DIR}/version"
TAG=${CONTAINER_VERSION}

FULL_IMAGE="${DOCKER_HUB_USER}/${IMAGE_NAME}"

## Usage
function usage {
    echo "build-n-push.bash"
    echo ""
    echo "  DOCKER_HUB_USER=<user>  Docker Hub username (default: ${DOCKER_HUB_USER})"
    echo ""
    echo "Flags:"
    echo "  --build    Build the image"
    echo "  --push     Push the image to Docker Hub"
    echo "  --all      Build and push"
    echo "  --help     Show this menu"
}

## Build
function build_image {
    echo "==> Building ${FULL_IMAGE}:${TAG}"
    docker build \
        -t "${FULL_IMAGE}:${TAG}" \
        -t "${FULL_IMAGE}:latest" \
        -f Dockerfile \
        .
    echo "==> Build complete: ${FULL_IMAGE}:${TAG}"
}

## Push
function push_image {
    echo "==> Pushing ${FULL_IMAGE}:${TAG} to Docker Hub"
    docker push "${FULL_IMAGE}:${TAG}"
    docker push "${FULL_IMAGE}:latest"
    echo "==> Push complete"
}

## Entry
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

do_build=0
do_push=0

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --build) do_build=1 ;;
        --push)  do_push=1 ;;
        --all)   do_build=1; do_push=1 ;;
        --help)  usage; exit 0 ;;
        *) echo "Unknown flag: $1"; usage; exit 1 ;;
    esac
    shift
done

[[ $do_build -eq 1 ]] && build_image
[[ $do_push -eq 1 ]]  && push_image

exit 0
