#!/bin/bash 

set -euo pipefail

[ -z $myPROJ ] && exit 1
oc get projects -o name |& egrep $myPROJ 2>&1
[ $? -ne 0 ] && exit 1

readonly myDATAGRID="https://localhost:11222/rest/v2/caches/"
readonly INFINISPAN_CLUSTER="infinispan01"
readonly myTEST_POD="$(oc get -n ${myPROJ} pods -l clusterName=${INFINISPAN_CLUSTER} -o json | jq -r '.items[] | select(.status.containerStatuses[].ready == true) | .metadata.name' | head -1)"
[ -z ${myTEST_POD} ] && exit 1
readonly INFINISPAN_USER="    $(oc -n ${myPROJ} extract secret/${INFINISPAN_CLUSTER}-generated-secret  --to=-   |& egrep username |  cut  -d: -f2 | tr  -d ' ')"
readonly INFINISPAN_PASSWORD="$(oc -n ${myPROJ} extract secret/${INFINISPAN_CLUSTER}-generated-secret  --to=-   |& egrep password |  cut  -d: -f2 | tr  -d ' ')"
[ -z $INFINISPAN_USER ] && exit 1;[ -z $INFINISPAN_PASSWORD ] && exit 1
#readonly mySVC="${INFINISPAN_CLUSTER}.${myPROJ}.svc"

readonly myCACHE_DEF_DIR='../../cache-definitions'
readonly myCACHE_DEF_FILE='replicated-cache-02'
[ ! -f $myCACHE_DEF_DIR/${myCACHE_DEF_FILE}.json ] && exit 1
readonly INFINISPAN_CACHE="${myCACHE_DEF_FILE}"

set -e
# create cache
oc cp $myCACHE_DEF_DIR/${myCACHE_DEF_FILE}.json  ${myTEST_POD}:/tmp/${myCACHE_DEF_FILE}.json
oc -n ${myPROJ} exec ${myTEST_POD} --  cat                     /tmp/${myCACHE_DEF_FILE}.json
set  -x
readonly MEDIATYPE_JSON="Content-Type: application/json"
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4 -vvv -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -H "$MEDIATYPE_JSON" --data-binary @/tmp/${myCACHE_DEF_FILE}.json --digest -X POST -k "${myDATAGRID}/${INFINISPAN_CACHE}"
set +x

set -e
# PUT into the cache
echo    "Put porco=dio in cache ${INFINISPAN_CACHE}"
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4      -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X POST -d "dio" -k "${myDATAGRID}/${INFINISPAN_CACHE}/porco"
echo "----------------------------------------------------------------------------------------"

set +e

