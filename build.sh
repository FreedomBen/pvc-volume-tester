#!/usr/bin/env bash

sudo podman build \
  -t volume-tester \
  -t quay.io/freedomben/volume-tester \
  -t docker.io/freedomben/volume-tester \
  .
