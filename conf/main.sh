#!/bin/bash

set -euo pipefail

oc delete  project coll-gestlck-be--datagrid-83-test-by-martinelli  && \
  oc create -f 05  && \
  oc create -f 10  && \
  oc create -f 20  && \
  ./25             && \
  echo OK          && \
  sleep 5             \
  oc create -f 30

