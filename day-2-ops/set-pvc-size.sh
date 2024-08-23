# Set 3Gi PVC size example


[ ! -f common.sh ] && exit 1
.      common.sh

while getopts ":s:" opt; do
  case ${opt} in
    s)
      echo "Option -s was triggered with argument: $OPTARG"
      readonly myPVC_SIZE=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


#RH Case 03881959 :-(
#oc -n $myPROJ patch infinispan/${myINFINISPAN} --type=merge -p "{\"spec\": {\"service\": {\"container\": {\"storage\": \"${myPVC_SIZE}Gi\"}}}}"

# pvc.spec.resources.requests.storage
readonly myPVCs="$(oc -n $myPROJ get pvc -l clusterName=infinispan01 -o name | tr  "\n" " ")"
[ -z "$myPVCs" ] && exit 1
for PVC in $myPVCs; do 
  oc -n $myPROJ patch ${PVC} --type=merge -p "{\"spec\": {\"resources\": {\"requests\": {\"storage\": \"${myPVC_SIZE}Gi\"}}}}"
done

