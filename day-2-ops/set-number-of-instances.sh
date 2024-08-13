# Set 5 instances

readonly myREPLICAS=5
[ ! -f common.sh ] && exit 1
.      common.sh

oc -n $myPROJ patch infinispan/$myINFINISPAN --type merge -p "{\"spec\":{\"replicas\":${myREPLICAS}}}"
