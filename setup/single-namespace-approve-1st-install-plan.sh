#!/bin/bash

set -euo pipefail
echo "Waiting for the 1st datagrid install plan to be present"

[ -z ${myPROJ} ] && exit 1

# Function to display progress bar
show_progress() {
  local PROG_BAR_WIDTH=50
  local PROGRESS=$(($1 * $PROG_BAR_WIDTH / 100))
  local REMAINING=$(($PROG_BAR_WIDTH - $PROGRESS))
  local PROGRESS_BAR=$(printf "%${PROGRESS}s" | tr ' ' '#')
  local REMAINING_BAR=$(printf "%${REMAINING}s" | tr ' ' ' ')
  
  printf "\r[%s%s] %d%%" "$PROGRESS_BAR" "$REMAINING_BAR" "$1"
}


myINSTALLPLAN=""
for i in $(seq 0 100); do
  myINSTALLPLAN="$(oc get --sort-by=.metadata.creationTimestamp -n ${myPROJ} ip -o custom-columns=NAME:.metadata.name --no-headers=true | head -1)"
  [[ "${myINSTALLPLAN}" =~ "install" ]] && break
  show_progress $i
  sleep 2
done
echo  "Install plan:${myINSTALLPLAN} is now available, processing it"

set -x
oc -n ${myPROJ} patch                            installplan/${myINSTALLPLAN} --type merge -p '{"spec":{"approved":true}}'
oc -n ${myPROJ} wait --for=condition=Installed   installplan/${myINSTALLPLAN}                      --timeout=300s
sleep 10
oc -n ${myPROJ} wait --for=condition=Available   deployment/infinispan-operator-controller-manager --timeout=600s
oc -n ${myPROJ} wait --for=condition=Initialized po -l app.kubernetes.io/name=infinispan-operator  --timeout=600s
set +x
echo