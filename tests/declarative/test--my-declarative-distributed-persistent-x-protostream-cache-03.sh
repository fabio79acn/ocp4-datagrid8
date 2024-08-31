#!/bin/bash

set -euox pipefail

readonly myFILE01="./../../cache-definitions/my-declarative-distributed-persistent-x-protostream-cache-03.yaml"
[ ! -f   $myFILE01 ] && exit 1
[ -z $myPROJ       ] && exit 1
oc get projects | egrep $myPROJ >/dev/null  2>&1
[ $? -ne 0     ] && exit 1


sed -e "s/myPROJ/${myPROJ}/" $myFILE01  | oc  create -f-
