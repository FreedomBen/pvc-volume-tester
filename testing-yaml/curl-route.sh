#!/usr/bin/env bash

# Crudely grab the route.  If there's more than one and the
# one you want isn't the first one, this won't work
route="$(oc get routes -o jsonpath='{ .items[0].spec.host }')"

commands=(
  "curl -k https://${route}/random/path?greeting=hello&subject=world"
  "curl -k http://${route}/random/path?greeting=hello&subject=world"
)

for cmd in "${commands[@]}"; do
  echo -e "Running: \033[1;36m${cmd}\033[0m"
  $cmd
done
