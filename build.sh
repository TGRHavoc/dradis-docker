#!/bin/sh

docker build \
  --rm \
  --force-rm \
  "${@}" \
  -t tgrhavoc/dradis-docker .
