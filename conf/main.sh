#!/bin/bash

set -euo pipefail

oc delete  project coll-gestlck-be--datagrid-83-test-by-martinelli  && \
  oc create -f 05  && \
  oc create -f 10  && \
  oc create -f 20  && \
  ./25             && \
  echo OK          && \
  timeout 20 oc get csv -w \
  oc create -f 30

