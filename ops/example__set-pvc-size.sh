# Set 4Gi PVC size example
oc -n coll-gestlck-be--datagrid-83-test-by-martinelli patch infinispan/infinispan01 --type=merge -p '{"spec": {"service": {"container": {"storage": "4Gi"}}}}'
