# Set 2Gi RAM example
oc -n coll-gestlck-be--datagrid-83-test-by-martinelli patch infinispan/infinispan01 --type merge -p '{"spec":{"container":{"memory":"2Gi"}}}'
