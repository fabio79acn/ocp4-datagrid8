#!/bin/bash

set -euo pipefail

[ -z ${myPROJ} ] && exit 1

readonly myHYPERFOIL_TMP_DIR="/tmp/hyperfoil"
[   -d $myHYPERFOIL_TMP_DIR ] && rm -rf $myHYPERFOIL_TMP_DIR
[ ! -d $myHYPERFOIL_TMP_DIR ] && mkdir  $myHYPERFOIL_TMP_DIR
cd     $myHYPERFOIL_TMP_DIR

set +e
while true; do
  oc -n ${myPROJ} wait --for=condition=Ready -l app=hyperfoil -l role=controller  po  --timeout=600s
  [ $? -eq 0 ] && break
  sleep 1
done
set -e

readonly myCACERTs="/etc/pki/ca-trust/extracted/java/cacerts"
readonly myOCP4_CA_DIR="/run/secrets/kubernetes.io/serviceaccount/"
readonly myOCP4_CA="${myOCP4_CA_DIR}/service-ca.crt"
mkdir -p $myHYPERFOIL_TMP_DIR/$myOCP4_CA_DIR

oc -n ${myPROJ} exec  hyperfoil-controller -- tar cf - "${myCACERTs}" | tar xf -
chmod u+w $myHYPERFOIL_TMP_DIR/${myCACERTs}
oc -n ${myPROJ} exec  hyperfoil-controller -- cat "${myOCP4_CA}" > $myHYPERFOIL_TMP_DIR/${myOCP4_CA}

cp                        $myHYPERFOIL_TMP_DIR/${myCACERTs} $myHYPERFOIL_TMP_DIR/${myCACERTs}.orig
keytool -noprompt  \
	-importcert -file $myHYPERFOIL_TMP_DIR/${myOCP4_CA} \
	-alias ocp4 \
	        -keystore $myHYPERFOIL_TMP_DIR/${myCACERTs} -storepass changeit

readonly myHYPERFOIL_TMP_DIR02="${myHYPERFOIL_TMP_DIR}/to-be-imported-as-config-map"
mkdir $myHYPERFOIL_TMP_DIR02
cp    $myHYPERFOIL_TMP_DIR/${myCACERTs} $myHYPERFOIL_TMP_DIR02

cat << EOF > ${myHYPERFOIL_TMP_DIR02}/log4j2.xml 
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
   <Appenders>
      <Console name="CONSOLE" target="SYSTEM_OUT">
         <PatternLayout pattern="%d{HH:mm:ss,SSS} %-5p [%c] (%t) %m%n"/>
      </Console>
   </Appenders>
   <Loggers>
      <Root level="INFO">
         <AppenderRef ref="CONSOLE"/>
      </Root>
   </Loggers>
</Configuration>
EOF
chmod u-w $myHYPERFOIL_TMP_DIR/${myCACERTs} $myHYPERFOIL_TMP_DIR02/cacerts
find ${myHYPERFOIL_TMP_DIR02}
keytool -list -keystore $myHYPERFOIL_TMP_DIR02/cacerts  -storepass changeit  -alias ocp4


readonly myCM=mylog-and-cacerts

set +e
oc -n ${myPROJ} get cm/$myCM 2>&1 >/dev/null && oc -n ${myPROJ} delete cm/$myCM 
set -e
oc -n ${myPROJ} create cm mylog-and-cacerts --from-file=${myHYPERFOIL_TMP_DIR02}

