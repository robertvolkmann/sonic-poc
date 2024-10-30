#!/usr/bin/env bash

export SONIC_BASE_URL='https://sonic-build.azurewebsites.net/api/sonic/artifacts?branchName=202311&platform=vs'
export SONIC_DOCKER_URL="${SONIC_BASE_URL}&target=target%2Fdocker-sonic-vs.gz"

curl -L "${SONIC_DOCKER_URL}" | gunzip | docker load
