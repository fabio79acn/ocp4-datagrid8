#!/bin/bash 

set -euo pipefail

readonly myFILE="test-01.yaml"
readonly myTEST_NAME="declarative-test-01"
[ ! -f $myFILE ] && exit 1
[ -z $myPROJ   ] && exit 1
oc get projects | egrep $myPROJ >/dev/null  2>&1
[ $? -ne 0     ] && exit 1
egrep $myTEST_NAME $myFILE >/dev/null  2>&1
[ $? -ne 0     ] && exit 1


for x in $(seq 10 20) ; do sed -e "s/myPROJ/${myPROJ}/" -e "s/$myTEST_NAME/declarative-test-$x/g" $myFILE  | oc create -f-  ; done
