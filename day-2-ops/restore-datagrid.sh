#!/bin/bash

set -euox pipefail

readonly myFILE01="./datagrid-restore.yaml"
readonly myBACKUP="$(oc get backup --no-headers | awk '{print $1}' | tail -1)"
readonly myRESTORE="restore-${myBACKUP}"
[ ! -f   $myFILE01 ] && exit 1
[ -z $myPROJ       ] && exit 1
oc get projects | egrep $myPROJ >/dev/null  2>&1
[ $? -ne 0     ] && exit 1


sed  -e "s/myRESTORE/${myRESTORE}/" -e "s/myPROJ/${myPROJ}/" -e "s/myBACKUP/${myBACKUP}/" -e "s/myINFINISPAN/${myINFINISPAN}/" $myFILE01  | oc  create -f-
