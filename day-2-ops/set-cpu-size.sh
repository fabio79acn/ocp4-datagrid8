# Set 2Gi RAM example


[ ! -f common.sh ] && exit 1
.      common.sh

while getopts ":c:" opt; do
  case ${opt} in
    c)
      echo "Option -c was triggered with argument: $OPTARG"
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
