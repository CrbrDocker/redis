#!/bin/bash
# Quick & dirty script to check if we need to rebuid our image
#

# Notes :
#  - docker buildx MUST be setup
#  - we must already be logged on our registry server
#  - check the state of your git repo before lauching

#set -x

IMAGE_NAME="crbrdocker/redis"
SRC_IMAGE="crbrdocker/debian:bookworm"
DOCKERFILE="DockerFileRedis"

. ./subscripts/need_rebuild.sh
