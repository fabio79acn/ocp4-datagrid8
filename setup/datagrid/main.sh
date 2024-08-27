#!/bin/bash

# TBD: evaluate whether kustomize can produce a similar logic like the one below.

set -euo pipefail

##############################################################################
# before to run this script you have to run: export myPROJ="<your-ocp-project>" 
###############################################################################
[ -z $myPROJ ] && exit 1

set +e
oc get project $myPROJ >/dev/null 2>&1
[ $? -ne 0 ] && exit 1
set -e

#oc delete  project ${myPROJ}  && \
#  oc create -f 05  && \
  sed -s "s/myPROJ/${myPROJ}/g" 10 | oc create -f-  && \
  sed -s "s/myPROJ/${myPROJ}/g" 20 | oc create -f-  && \
  ./25             && \
  echo OK          && \
  sleep 5          && \
  sed -s "s/myPROJ/${myPROJ}/g" 30 | oc create -f-  && \
  sed -s "s/myPROJ/${myPROJ}/g" 40 | oc create -f-  && \
  sed -s "s/myPROJ/${myPROJ}/g" 50 | oc create -f-  && \
  readonly DONE="true" 
  
if [[ ${DONE} == "true" ]]; then
  echo -n "DataGrid portal credentials; username:$(oc get -n ${myPROJ} secret infinispan01-generated-operator-secret -o json | jq '.data.username' -r  | base64 -d) password:$(oc get -n ${myPROJ} secret infinispan01-generated-operator-secret -o json | jq '.data.password' -r  |base64 -d)"
  echo
  echo "You still have to manually expose the admin svc as a https:// route in order to access the DataGrid portal !!"
fi

[[ ${DONE} != "true" ]] && exit 1

