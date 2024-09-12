#!/bin/bash

set -euo pipefail

[ -z $myPROJ ] && exit 1
oc get projects -o name |& egrep $myPROJ 2>&1
[ $? -ne 0 ] && exit 1

readonly INFINISPAN_CLUSTER="infinispan01"
readonly myDATAGRID="https://${INFINISPAN_CLUSTER}.${myPROJ}.svc:11222/rest/v2/caches"
readonly myTEST_POD="$(oc get -n ${myPROJ} pods -l clusterName=${INFINISPAN_CLUSTER} -o json | jq -r '.items[] | select(.status.containerStatuses[].ready == true) | .metadata.name' | head -1)"
[ -z ${myTEST_POD} ] && exit 1
readonly INFINISPAN_USER="    $(oc -n ${myPROJ} extract secret/${INFINISPAN_CLUSTER}-generated-secret  --to=-   |& egrep username |  cut  -d: -f2 | tr  -d ' ')"
readonly INFINISPAN_PASSWORD="$(oc -n ${myPROJ} extract secret/${INFINISPAN_CLUSTER}-generated-secret  --to=-   |& egrep password |  cut  -d: -f2 | tr  -d ' ')"
[ -z $INFINISPAN_USER ] && exit 1;[ -z $INFINISPAN_PASSWORD ] && exit 1

readonly myCACHE_DEF_DIR='../../cache-definitions'
readonly myCACHE_DEF_FILE='replicated-cache-01'
[ ! -f $myCACHE_DEF_DIR/${myCACHE_DEF_FILE}.json ] && exit 1
readonly INFINISPAN_CACHE="cache-test"

set -e

# GET into the cache

for i in $(seq 1 100); do
echo    "GET key-${i}=value-${i} in cache ${INFINISPAN_CACHE}:";
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --retry 5 --retry-connrefused --http1.1 -4 -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET -k "${myDATAGRID}/${INFINISPAN_CACHE}/key-${i}";echo
sleep 1;

done

set +e
