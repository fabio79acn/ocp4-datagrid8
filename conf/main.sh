#!/bin/bash

set -euo pipefail

readonly myPROJ="coll-gestlck-be--datagrid-83-test-by-martinelli"

oc delete  project ${myPROJ}  && \
  oc create -f 05  && \
  oc create -f 10  && \
  oc create -f 20  && \
  ./25             && \
  echo OK          && \
  sleep 5             \
  oc create -f 30     \
  oc create -f 40     \
  oc create -f 50  
  

echo -n "Portal credentials, username:$(oc get -n ${myPROJ} secret infinispan01-generated-operator-secret -o json | jq '.data.username' -r  | base64 -d) password:$(oc get -n ${myPROJ} secret infinispan01-generated-operator-secret -o json | jq '.data.password' -r  |base64 -d)"
echo
echo "You still have to expose the admin service in order to access the DataGrid portal !!"
