##############################################################################
# before to run this script you have to run: 
# export myPROJ="<your-ocp-project>"
# export myINFINISPAN=infinispan01
###############################################################################
[ -z $myPROJ ]       && exit 1
[ -z $myINFINISPAN ] && exit 1
set -euo pipefail
