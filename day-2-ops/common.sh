##############################################################################
# before to run this script you have to run: 
# export myPROJ="<your-ocp-project>"
# export myINFINISPAN=infinispan01
###############################################################################
[ -z $myPROJ ]       && echo "You have to run: export myPROJ=\"<your-ocp-project>\"" && exit 1
[ -z $myINFINISPAN ] && echo "You have to run: export myINFINISPAN=infinispan01"     && exit 1
set -euo pipefail
