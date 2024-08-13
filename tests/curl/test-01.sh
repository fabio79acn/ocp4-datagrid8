#!/bin/bash 

set -euo pipefail

#readonly myPROJ="coll-gestlck-be--datagrid-83-test-by-martinelli"
[ -z $myPROJ ] && exit 1

readonly INFINISPAN_CLUSTER="infinispan01"
readonly myTEST_POD="$(oc get -n ${myPROJ} pods -l clusterName=${INFINISPAN_CLUSTER} -o json | jq -r '.items[] | select(.status.containerStatuses[].ready == true) | .metadata.name' | head -1)"
[ -z ${myTEST_POD} ] && exit 1
readonly INFINISPAN_USER="    $(oc -n ${myPROJ} extract secret/${INFINISPAN_CLUSTER}-generated-secret  --to=-   |& egrep username |  cut  -d: -f2 | tr  -d ' ')"
readonly INFINISPAN_PASSWORD="$(oc -n ${myPROJ} extract secret/${INFINISPAN_CLUSTER}-generated-secret  --to=-   |& egrep password |  cut  -d: -f2 | tr  -d ' ')"
[ -z $INFINISPAN_USER ] && exit 1;[ -z $INFINISPAN_PASSWORD ] && exit 1
#readonly mySVC="${INFINISPAN_CLUSTER}.${myPROJ}.svc"
readonly INFINISPAN_CACHE="my-curl-cache-01"
readonly myCACHE_DEF=/tmp/my-datagrid-cache-def.json
[ -f $myCACHE_DEF ] && rm -f $myCACHE_DEF
cat << EOF > $myCACHE_DEF
{
    "distributed-cache": {
        "encoding": {
            "key": {
              "media-type": "application/x-protostream"
            },
            "value": {
              "media-type": "application/x-protostream"
            }
          },
        "expiration": {
            "max-idle": -1,
            "lifespan": -1,
            "interval": 60000
        },
        "indexing": {
            "enabled": false
        },
        "memory": {
            "max-size": "1000MB",
            "max-count": -1,
            "when-full": "REMOVE",
            "storage": "HEAP"
        },
        "mode": "SYNC",
        "owners": 2,
        "partition-handling": {
            "when-split": "ALLOW_READ_WRITES",
            "merge-policy": "REMOVE_ALL"
        },
        "state-transfer": {
            "enabled": false,
            "await-initial-transfer": false
        },
        "statistics": true,
        "transaction": {
            "mode": "NONE"
        }
    }
}
EOF

set -e
# create cache
oc cp $myCACHE_DEF   ${myTEST_POD}:$myCACHE_DEF
oc -n ${myPROJ} exec ${myTEST_POD} -- cat $myCACHE_DEF
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -0 -4 -vvv -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -H \"Content-Type: application/json\"  --data-binary \"@$myCACHE_DEF\" -X POST -k "https://localhost:11222/rest/v2/caches/${INFINISPAN_CACHE}"
# PUT into the cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -0 -4 -vvv -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X POST -d "value1" -k "https://localhost:11222/rest/v2/caches/${INFINISPAN_CACHE}/key1"
# GET from the cache
oc -n ${myPROJ} exec ${myTEST_POD} -- curl -0 -4 -vvv -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -X GET              -k "https://localhost:11222/rest/v2/caches/${INFINISPAN_CACHE}/key1"
set +e
[ -f $myCACHE_DEF ] && rm -f $myCACHE_DEF
