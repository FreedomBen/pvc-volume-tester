#!/usr/bin/env bash

oc process \
  -f metals-example-ocp-secrets-template.yaml \
  -p TLS_TERMINATION=edge \
  -p METALS_SSL=off \
  -o yaml \
  | oc apply -f -
