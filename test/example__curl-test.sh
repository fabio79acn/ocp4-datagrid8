#!/bin/bash 

set -euo pipefail

#readonly myPROJ="coll-gestlck-be--datagrid-83-test-by-martinelli"
[ -z $myPROJ ] && exit 1

readonly INFINISPAN_CLUSTER="infinispan01"
readonly myTEST_POD="$(oc get -n ${myPROJ} pods -l clusterName=${INFINISPAN_CLUSTER} -o json | jq -r '.items[] | select(.status.containerStatuses[].ready == true) | .metadata.name' | head -1)"
[ -z ${myTEST_POD} ] && exit 1
readonly INFINISPAN_USER="admin"
readonly INFINISPAN_PASSWORD="password"
readonly mySVC="${INFINISPAN_CLUSTER}.${myPROJ}.svc"
readonly INFINISPAN_CACHE="mycache01"

set +e
# create cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -svu ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X POST             "http://${mySVC}:11222/rest/v2/caches/${INFINISPAN_CACHE}"
# PUT into the cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -svu ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X POST -d "value1" "http://${mySVC}:11222/rest/v2/caches/${INFINISPAN_CACHE}/key1"
# GET from the cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -svu ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X GET              "http://${mySVC}:11222/rest/v2/caches/${INFINISPAN_CACHE}/key1"
set -e
