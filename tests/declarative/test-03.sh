#!/bin/bash 

set -euo pipefail

readonly myFILE01="test-03.yaml"
readonly myTEST_NAME="my-declarative-distributed-persistent-cache-03"
[ ! -f $myFILE01 ] && exit 1
[ -z $myPROJ   ] && exit 1
oc get projects | egrep $myPROJ >/dev/null  2>&1
[ $? -ne 0     ] && exit 1
egrep $myTEST_NAME $myFILE01 >/dev/null  2>&1
[ $? -ne 0     ] && exit 1


sed -e "s/myPROJ/${myPROJ}/" $myFILE01  | oc create -f-

set -x;sleep 60;set +x

readonly myFILE02="test-03-batch.yaml"
[ ! -f $myFILE02 ] && exit 1
egrep $myTEST_NAME $myFILE02 >/dev/null  2>&1
[ $? -ne 0     ] && exit 1


sed -e "s/myPROJ/${myPROJ}/" $myFILE02  | oc create -f- 
