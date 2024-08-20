#!/bin/bash 

set -euo pipefail

#readonly myPROJ="coll-gestlck-be--datagrid-83-test-by-martinelli"
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
readonly INFINISPAN_CACHE="my-curl-cache-02"
readonly myCACHE_DEF=/tmp/my-datagrid-cache-def.json
[ -f $myCACHE_DEF ] && rm -f $myCACHE_DEF

# cat << EOF > $myCACHE_DEF
# {
#   "distributed-cache": {
#     "mode": "SYNC",
#     "owners": 4,
#     "statistics": true,
#     "encoding": {
#       "media-type": "text/plain"
#     },
#     "memory": {
#       "storage": "OFF_HEAP"
#     },
#     "persistence": {
#       "file-store": {
#         "data": {
#           "path": "data"
#         },
#         "index": {
#           "path": "index"
#         }
#       },
#       "passivation": false
#     }
#   }
# }
# EOF


cat << EOF > $myCACHE_DEF
{
    "distributed-cache": {
        "encoding": {
            "key": {
              "media-type": "application/x-www-form-urlencoded"
            },
            "value": {
              "media-type": "application/x-www-form-urlencoded"
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



#cat << EOF > $myCACHE_DEF
#{"distributed-cache":{"configuration":"org.infinispan.LOCAL","mode":"SYNC","remote-timeout":"17500","statistics":true,"locking":{"concurrency-level":"1000","acquire-timeout":"15000","striping":false},"state-transfer":{"timeout":"60000"}}}
#EOF

set -e
#  GET caches
echo "----------------------------------------------------------------------------------------"
echo -n "Current caches: "
oc -n ${myPROJ} exec ${myTEST_POD} -- curl       -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}"
echo

# DELETE cache if already present
readonly myCURRENT_CACHES=$(oc -n ${myPROJ} exec ${myTEST_POD} -- curl       -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X GET              -k "${myDATAGRID}")
[[ "$myCURRENT_CACHES" == *"$INFINISPAN_CACHE"* ]] && oc -n ${myPROJ} exec ${myTEST_POD} -- curl       -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} --digest -X DELETE           -k "${myDATAGRID}/${INFINISPAN_CACHE}"

# create cache
oc cp $myCACHE_DEF   ${myTEST_POD}:$myCACHE_DEF
oc -n ${myPROJ} exec ${myTEST_POD} -- cat $myCACHE_DEF
set  -x
readonly MEDIATYPE_JSON="Content-Type: application/json"
oc -n ${myPROJ} exec ${myTEST_POD} -- curl --http1.1 -4 -vvv -su ${INFINISPAN_USER}:${INFINISPAN_PASSWORD} -H "$MEDIATYPE_JSON" --data-binary @$myCACHE_DEF --digest -X POST -k "${myDATAGRID}/${INFINISPAN_CACHE}"
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

[ -f $myCACHE_DEF ] && rm -f $myCACHE_DEF
