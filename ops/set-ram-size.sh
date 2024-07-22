# Set 2Gi RAM example

readonly myRAM_SIZE=2Gi
[ ! -f common.sh ] && exit 1
.      common.sh


oc -n ${myPROJ} patch infinispan/${myINFINISPAN} --type merge -p "{\"spec\":{\"container\":{\"memory\":\"${myRAM_SIZE}\"}}}"
