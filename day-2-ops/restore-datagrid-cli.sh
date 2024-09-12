#!/bin/bash

set -euo pipefail
# before to run this script you have to run: export myPROJ="<your-ocp-project>"
# before to run this script you have to run: export myDATAGRID="<your-infinispan-cluster-name>"

readonly myCLI_USER="$(       oc extract -n ${myPROJ} secret/${myDATAGRID}-generated-secret  --to=-  |& egrep username |  cut  -d: -f2 | tr  -d ' ')"
readonly myCLI_PASSWORD="$(   oc extract -n ${myPROJ} secret/${myDATAGRID}-generated-secret  --to=-  |& egrep password |  cut  -d: -f2 | tr  -d ' ')"

  readonly PODs="$(oc -n ${myPROJ} get po  -l app=infinispan-pod -o jsonpath='{.items[*].metadata.name}')"

  [ -z "$PODs" ] && exit 1

  for PO in $PODs ; do oc -n ${myPROJ} exec $PO -- mkdir -p /home/jboss/.config/red_hat_data_grid/ ; done
  cat << EOF > /tmp/cli.properties
autoconnect-url=https\://${myCLI_USER}\:${myCLI_PASSWORD}@localhost\:11222

# Skip SSL certificate verification
trustall=true

# Connection timeout in milliseconds
timeout=5000

# Suppress command output (optional)
quiet=false
EOF
  for PO in $PODs ; do oc -n ${myPROJ} cp /tmp/cli.properties $PO:/home/jboss/.config/red_hat_data_grid/ ; done
  echo "The file /home/jboss/.config/red_hat_data_grid/cli.properties has been installed on each DataGrid pod"
  rm -f /tmp/cli.properties

