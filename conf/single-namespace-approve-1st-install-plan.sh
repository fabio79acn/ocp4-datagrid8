#!/bin/bash

set -xeuo pipefail
echo "Waiting for the 1st datagrid install plan to be present"

readonly myPROJ="coll-gestlck-be--datagrid-83-test-by-martinelli"

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
  myINSTALLPLAN="$(oc get --sort-by=.metadata.creationTimestamp -n ${myPROJ} ip -o custom-columns=NAME:.metadata.name --no-headers=true)"
  [ ! -z $myINSTALLPLAN ] && [[ "${myINSTALLPLAN}" != "null" ]] && break
  show_progress $i
  sleep 0.1
done
echo -e "\nDone!"


oc -n ${myPROJ} patch                          installplan/${myINSTALLPLAN} --type merge -p '{"spec":{"approved":true}}'

oc -n ${myPROJ} wait --for=condition=Installed installplan/${myINSTALLPLAN} --timeout=300s
