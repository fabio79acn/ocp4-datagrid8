echo "Waiting for the 1st datagrid install plan to be present"

# Function to display progress bar
show_progress() {
  local PROG_BAR_WIDTH=50
  local PROGRESS=$(($1 * $PROG_BAR_WIDTH / 100))
  local REMAINING=$(($PROG_BAR_WIDTH - $PROGRESS))
  local PROGRESS_BAR=$(printf "%${PROGRESS}s" | tr ' ' '#')
  local REMAINING_BAR=$(printf "%${REMAINING}s" | tr ' ' ' ')
  
  printf "\r[%s%s] %d%%" "$PROGRESS_BAR" "$REMAINING_BAR" "$1"
}

# Example usage
for i in $(seq 0 100); do
  show_progress $i
  sleep 0.1
done

echo -e "\nDone!"


readonly myINSTALLPLAN="$(oc get -n coll-gestlck-be--datagrid-83-test-by-martinelli ip  -o json  | jq '.items[0].metadata.name' -r)"

oc -n coll-gestlck-be--datagrid-83-test-by-martinelli patch ip $myINSTALLPLAN --type merge -p '{"spec":{"approved":true}}'

oc wait --for=condition=Installed installplan/${myINSTALLPLAN} -n coll-gestlck-be--datagrid-83-test-by-martinelli --timeout=300s
