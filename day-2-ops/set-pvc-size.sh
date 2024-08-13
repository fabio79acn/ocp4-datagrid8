# Set 3Gi PVC size example

readonly myPVC_SIZE=3Gi
[ ! -f common.sh ] && exit 1
.      common.sh



oc -n $myPROJ patch infinispan/${myINFINISPAN} --type=merge -p "{\"spec\": {\"service\": {\"container\": {\"storage\": \"${myPVC_SIZE}\"}}}}"
