#!/bin/bash

set -euo pipefail

##############################################################################
# before to run this script you have to run: export myPROJ="<your-ocp-project>" 
###############################################################################
[ -z $myPROJ ] && exit 1
readonly myDATAGRID="infinispan01"

set +e
oc get project $myPROJ >/dev/null 2>&1
[ $? -ne 0 ] && echo "I could not find an OCP4 project called: ${myPROJ}" && exit 1
set -e

#sed -s "s/myPROJ/${myPROJ}/g" 05 | oc create -f-  &&                         \
sed -s "s/myPROJ/${myPROJ}/g" 10 | oc create -f-  &&                         \
sed -s "s/myPROJ/${myPROJ}/g" 20 | oc create -f-  &&                         \
./25                                              &&                         \
sed -s "s/myPROJ/${myPROJ}/g" 30 | oc create -f-  &&                         \
oc wait --for condition=wellFormed --timeout=5000s infinispan/$myDATAGRID && \
sed -s "s/myPROJ/${myPROJ}/g" 40 | oc create -f-  &&                         \
sed -s "s/myPROJ/${myPROJ}/g" 50 | oc create -f-  &&                         \
sed -s "s/myPROJ/${myPROJ}/g" 60 | oc create -f-  &&                         \
readonly DONE="true"



if [[ ${DONE} == "true" ]]; then
   
  readonly myPORTAL_USER="$(    oc get     -n ${myPROJ} secret ${myDATAGRID}-generated-operator-secret -o json | jq '.data.username' -r  | base64 -d)"
  readonly myPORTAL_PASSWORD="$(oc get     -n ${myPROJ} secret ${myDATAGRID}-generated-operator-secret -o json | jq '.data.password' -r  |base64 -d)"
  readonly myCLI_USER="$(       oc extract -n ${myPROJ} secret/${myDATAGRID}-generated-secret  --to=-  |& egrep username |  cut  -d: -f2 | tr  -d ' ')"
  readonly myCLI_PASSWORD="$(   oc extract -n ${myPROJ} secret/${myDATAGRID}-generated-secret  --to=-  |& egrep password |  cut  -d: -f2 | tr  -d ' ')"

  echo    "DataGrid Web portal credentials| username:$myPORTAL_USER password:$myPORTAL_PASSWORD"
  echo    "Datagrid     CLI    credentials| username:$myCLI_USER    password:$myCLI_PASSWORD"

  readonly PODs="$(oc get po  -l app=infinispan-pod -o jsonpath='{.items[*].metadata.name}')"

  [ -z "$PODs" ] && exit 1

  for PO in $PODs ; do oc exec $PO -- mkdir -p /home/jboss/.config/red_hat_data_grid/ ; done
  cat << EOF > /tmp/cli.properties
autoconnect-url=https\://${myCLI_USER}\:${myCLI_PASSWORD}@localhost\:11222

# Skip SSL certificate verification
trustall=true

# Connection timeout in milliseconds
timeout=5000

# Suppress command output (optional)
quiet=false
EOF
  for PO in $PODs ; do oc cp /tmp/cli.properties $PO:/home/jboss/.config/red_hat_data_grid/ ; done
  echo "The file /home/jboss/.config/red_hat_data_grid/cli.properties has been installed on each DataGrid pod"
  rm -f /tmp/cli.properties

  echo
fi

[[ ${DONE} != "true" ]] && echo "DataGrid setup FAILED :-(" && exit 1


