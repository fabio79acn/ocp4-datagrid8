# Set 2Gi RAM example


[ ! -f common.sh ] && exit 1
.      common.sh

while getopts ":s:" opt; do
  case ${opt} in
    s)
      echo "Option -s was triggered with argument: $OPTARG"
      readonly myCPU_SIZE=$OPTARG
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


oc -n ${myPROJ} patch infinispan/${myINFINISPAN} --type merge -p "{\"spec\":{\"container\":{\"cpu\":\"${myCPU_SIZE}m\"}}}"
