#!/bin/bash 

set -euo pipefail

readonly myPROJ="coll-gestlck-be--datagrid-83-test-by-martinelli"
readonly myTEST_POD="$(oc get -n ${myPROJ} pods -l clusterName=infinispan01 -o json | jq -r '.items[] | select(.status.containerStatuses[].ready == true) | .metadata.name' | head -1)"
readonly INFINISPAN_USER="admin"
readonly INFINISPAN_PASSWORD="password"
readonly mySVC="infinispan01.${myPROJ}.svc"
[ -z ${myTEST_POD} ] && exit 1

set +e
# create cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -svu ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X POST             "http://${mySVC}:11222/rest/v2/caches/mycache"
# PUT into the cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -svu ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X POST -d "value1" "http://${mySVC}:11222/rest/v2/caches/mycache/key1"
# GET from the cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -svu ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X GET              "http://${mySVC}:11222/rest/v2/caches/mycache/key1"
set -e
