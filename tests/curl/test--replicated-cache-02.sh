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
#  GET caches
echo "----------------------------------------------------------------------------------------"
echo -n "Current caches: "
oc -n ${myPROJ} exec ${myTEST_POD} -- curl       -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}"
echo

# DELETE cache if already present
echo -n "Delete cache $myCACHE_DEF_FILE if exists. "
readonly myCURRENT_CACHES=$(oc -n ${myPROJ} exec ${myTEST_POD} -- curl       -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}")
[[ "$myCURRENT_CACHES" == *"$INFINISPAN_CACHE"* ]] && oc -n ${myPROJ} exec ${myTEST_POD} -- curl       -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X DELETE           -k "${myDATAGRID}/${INFINISPAN_CACHE}" && echo " Cache $myCACHE_DEF_FILE Deleted."

# create cache
oc cp $myCACHE_DEF_DIR/${myCACHE_DEF_FILE}.json  ${myTEST_POD}:/tmp/${myCACHE_DEF_FILE}.json
oc -n ${myPROJ} exec ${myTEST_POD} --  cat                     /tmp/${myCACHE_DEF_FILE}.json
set  -x
readonly MEDIATYPE_JSON="Content-Type: application/json"
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4 -vvv -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -H "$MEDIATYPE_JSON" --data-binary @/tmp/${myCACHE_DEF_FILE}.json --digest -X POST -k "${myDATAGRID}/${INFINISPAN_CACHE}"
set +x

set -e
#  GET caches
echo -n "Current caches: "
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4      -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}";echo
echo "----------------------------------------------------------------------------------------"

# PUT into the cache
echo    "Put key1=value1 in cache ${INFINISPAN_CACHE}"
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4      -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X POST -d "value1" -k "${myDATAGRID}/${INFINISPAN_CACHE}/key1"
echo "----------------------------------------------------------------------------------------"

# GET from the cache
echo -n "Get key key1 from cache ${INFINISPAN_CACHE}: "
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4      -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}/${INFINISPAN_CACHE}/key1";echo
echo "----------------------------------------------------------------------------------------"

# GET cache config
echo -n "Get cache ${INFINISPAN_CACHE} config: "
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4      -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}/${INFINISPAN_CACHE}?action=config";echo
echo "----------------------------------------------------------------------------------------"

# GET stats from the cache
echo -n "Get cache ${INFINISPAN_CACHE} stats: "
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4      -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}/${INFINISPAN_CACHE}?action=stats";echo
echo "----------------------------------------------------------------------------------------"

# DELETE the whole cache
#oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4     -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X DELETE           -k "${myDATAGRID}/${INFINISPAN_CACHE}"
echo "----------------------------------------------------------------------------------------"
set +e

