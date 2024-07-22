Curl test
#########

Be aware of an another method to interact with DataGrid

~~~
apiVersion: infinispan.org/v2alpha1
kind: Batch
metadata:
  name: infinispan01
  namespace: mynamespace
spec:
  cluster: infinispan01
  config: |
    create cache --template=org.infinispan.DIST_SYNC mycache99
    put --cache=mycache99 hello world
    put --cache=mycache99 hola mundo
~~~
