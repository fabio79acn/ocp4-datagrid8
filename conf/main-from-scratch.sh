#!/bin/bash

# TBD: evaluate whether kustomize can produce a similar logic like the one below.

set -euo pipefail

##############################################################################
# before to run this script you have to run: export myPROJ="<your-ocp-project>" 
###############################################################################
[ -z $myPROJ ] && exit 1

set +e
oc get project $myPROJ >/dev/null 2>&1
[ $? -eq 0 ] && oc delete project ${myPROJ}
set -e

sed   -s "s/myPROJ/${myPROJ}/g" 05 | oc create -f-  && \
  sed -s "s/myPROJ/${myPROJ}/g" 10 | oc create -f-  && \
  sed -s "s/myPROJ/${myPROJ}/g" 20 | oc create -f-  && \
  ./25             && \
  echo OK          && \
  sed -s "s/myPROJ/${myPROJ}/g" 30 | oc create -f-  && \
  oc wait --for condition=wellFormed --timeout=1000s infinispan/infinispan01
  sed -s "s/myPROJ/${myPROJ}/g" 40 | oc create -f-  && \
  sed -s "s/myPROJ/${myPROJ}/g" 50 | oc create -f-  && \
  readonly DONE="true" 
  
readonly myPORTAL_USER="$(    oc get -n ${myPROJ} secret infinispan01-generated-operator-secret -o json | jq '.data.username' -r  | base64 -d)"
readonly myPORTAL_PASSWORD="$(oc get -n ${myPROJ} secret infinispan01-generated-operator-secret -o json | jq '.data.password' -r  |base64 -d)"
readonly myCLI_USER="$(       oc get -n ${myPROJ} extract secret/infinispan01-generated-secret  --to=-  |& egrep username |  cut  -d: -f2 | tr  -d ' ')"
readonly myCLI_PASSWORD="$(   oc get -n ${myPROJ} extract secret/infinispan01-generated-secret  --to=-  |& egrep password |  cut  -d: -f2 | tr  -d ' ')"


if [[ ${DONE} == "true" ]]; then
  echo -n "DataGrid portal credentials; username:$myPORTAL_USER password:$myPORTAL_PASSWORD"
  echo    "Datagrid CLI    credentials; username:$myCLI_USER password:$myCLI_PASSWORD"
  echo
  echo "Be aware that you still have to manually expose the admin svc as a https:// route in order to access the DataGrid portal"
fi

[[ ${DONE} != "true" ]] && exit 1


