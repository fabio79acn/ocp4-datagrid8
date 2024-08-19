# Set 3Gi PVC size example


[ ! -f common.sh ] && exit 1
.      common.sh

while getopts ":p:" opt; do
  case ${opt} in
    p)
      echo "Option -p was triggered with argument: $OPTARG"
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



oc -n $myPROJ patch infinispan/${myINFINISPAN} --type=merge -p "{\"spec\": {\"service\": {\"container\": {\"storage\": \"${myPVC_SIZE}Gi\"}}}}"
