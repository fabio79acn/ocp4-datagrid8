Curl test
#########

Be aware of an another way to interact with DataGrid; it assumes you've create a mycache

~~~
apiVersion: infinispan.org/v2alpha1
kind: Batch
metadata:
  name: infinispan01
  namespace: mynamespace
spec:
  cluster: infinispan01
  config: |
    create cache --template=org.infinispan.DIST_SYNC mycache
    put --cache=mycache hello world
    put --cache=mycache hola mundo
~~~
