# Set 4 instances
oc -n coll-gestlck-be--datagrid-83-test-by-martinelli patch infinispan/infinispan01 --type merge -p '{"spec":{"replicas":"4"}}'
