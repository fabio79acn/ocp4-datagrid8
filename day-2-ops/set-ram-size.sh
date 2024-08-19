# Set 2Gi RAM example


[ ! -f common.sh ] && exit 1
.      common.sh

while getopts ":r:" opt; do
  case ${opt} in
    r)
      echo "Option -r was triggered with argument: $OPTARG"
      readonly myRAM_SIZE=$OPTARG
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


oc -n ${myPROJ} patch infinispan/${myINFINISPAN} --type merge -p "{\"spec\":{\"container\":{\"memory\":\"${myRAM_SIZE}Gi\"}}}"
