How to install and upgrade Data Grid 8 Operator
===============================================

January 17, 2024
Francisco De Melo Junior Alexander Barbosa Ayala

Related topics:
    KubernetesOperators

Related products:
    Red Hat Data GridRed Hat OpenShift Container Platform

Share:

In Red Hat OpenShift 4, the Operator framework became a fundamental part of the daily cluster operations. An operator is a custom controller that listens to a few custom resources. Operators can be used for networking, cluster management, or installing and running applications. They provide a custom mechanism that extends the default OpenShift Container Platform capabilities.

Specifically, in terms of application operators, Data Grid Operator (a Go application) deploys Red Hat Data Grid (a Java application) by providing five APIs for creating a Data Grid cluster/caches/custom settings. The Data Grid Operator provides Custom Resources (CRs), which are based on template files called Custom Resource Definitions (CRDs). The CRDs are installed together with the Data Grid Operator and will be located on the etcd database in the OpenShift Container Platform cluster (cluster-wide).

Each API extends OpenShift Container Platform and provides you the ability to create and execute an operation on Red Hat Data Grid, Red Hat's solution for in-memory cache based on the Infinispan community project. These resources are user-configurable and serve to dictate how Data Grid is deployed and functions within a cluster.


Data Grid Operator custom resources
===================================
Data Grid Operator provides the following types of custom resources for users to declare:

  - Cache: The caches used by Data Grid can be replicated or distributed, for instance.
  - Batch: Functions for the cluster to execute.
  - Backup: Backs up data (used together with Restore).
  - Restore: Restores cache entries/cache data from a previous backup.
  - Infinispan: Instantiates and configure Infinispan clusters; specify either DataGrid (valid type) or Cache (deprecated type) as the service type.


How to install Data Grid 8 Operator
===================================
The Data Grid Operator needs two objects to be installed: Subscription and the appropriate OperatorGroup (OG):

  - The Subscription provides the details for the Operator Lifecycle Manager (OLM) to install a specific Operator, providing the version, the name, and the namespace to be installed. This means the Subscription is ingested by the OLM and leads to the installation of the Data Grid Operator (given a correct channel/version provided).
  - The OG can be used to set/delimit the target namespaces, which are the namespace the Data Grid Operator will monitor (for namespace-bounded installation) and the user can only create a single OperatorGroup per namespace.

By default, the Data Grid Operator will be installed on openshift-operators namespace where the OperatorGroup already exists; given this OperatorGroup has no boundaries, it enables the Operators deployed to that namespace to have a cluster scope. If the user does not want the Operator(s) to have cluster scope, then they should install it in a different namespace and create the adequate OperatorGroup. Furthermore, the user should only have to explicitly create an OperatorGroup when deploying outside of the openshift-operators namespace, where it does not exist already.
Table 1: Types of Data Grid Operator installation. Type of installation 	Example Subscription 	OperatorGroup 	Namespace
Cluster-wide installation 	kind: Subscription
  name: datagrid
  namespace: openshift-operators 	already present 	openshift-operators
Namespace-bounded installation 	kind: Subscription
  name: datagrid
  namespace: example 	to be created if not present 	any (except openshift-operators)

Unlike upstream operators and the AMQ Operator, Data Grid Operator does not allow direct Cluster Service Version (CSV) installation; the only supported approach is via the OLM’s Subscription application.

The process describes how to upgrade from Data Grid 8.1/8.2 to Data Grid 8.3 in Data Grid 8 Operator. You can install the Data Grid Operator (for instance, via template) by creating a Subscription to a specific channel (8.1.x, 8.2.x, 8.3.x, 8.4.x) and setting the OperatorGroup accordingly, feeding from the CatalogSource (redhat-operators that will have the healthy or not healthy status) and declared via the YAML template below:
~~~
- apiVersion: operators.coreos.com/v1alpha1
  kind: Subscription
  metadata:
    name: datagrid-operator
    namespace: ${OPERATOR_NAMESPACE}
  spec:
    channel: 8.2.x
    installPlanApproval: Manual
    name: datagrid
    source: redhat-operators
    sourceNamespace: openshift-marketplace
    startingCSV: datagrid-operator.v8.2.8
- apiVersion: operators.coreos.com/v1
  kind: OperatorGroup
  metadata:
    name: infinispan
    namespace: ${OPERATOR_NAMESPACE}
  spec:
    targetNamespaces:
      - ${CLUSTER_NAMESPACE}
~~~


And then process the template above:
~~~
$ oc process -f template-01-complete.yaml | oc apply -f -
project.project.openshift.io/dg-test-nyc configured
subscription.operators.coreos.com/datagrid-operator configured
operatorgroup.operators.coreos.com/infinispan configured
~~~


This will give you the Operator installed (8.2.8 below):
~~~
$ oc get csv
NAME                       DISPLAY     VERSION   REPLACES                   PHASE
datagrid-operator.v8.2.8   Data Grid   8.2.8     datagrid-operator.v8.2.7   Succeeded
~~~


The Operator is not the cluster. To create a cluster, create an Infinispan CR (which is exemplified below):
~~~
- apiVersion: infinispan.org/v1
  kind: Infinispan
  metadata:
    name: ${CLUSTER_NAME}
    namespace: ${CLUSTER_NAMESPACE}
    annotations:
      infinispan.org/monitoring: 'false'
    labels:
      type: middleware
      prometheus_domain: ${CLUSTER_NAME}
  spec:
    configMapName: "${CLUSTER_NAME}-custom-config"
    container:
      cpu: '2'
      extraJvmOpts: '-Xlog:gc*=info:file=/tmp/gc.log:time,level,tags,uptimemillis:filecount=10,filesize=1m'
      memory: 3Gi
~~~


How to upgrade the Data Grid Operator
=====================================
The Data Grid Operator can be upgraded, as in all OpenShift Container Platform objects attached to it to be moved. 
The process is based on the InstallPlan object and is described below based on How to upgrade from Data Grid 8.1/8.2 to Data Grid 8.3 in Data Grid 8 Operator and example. 
Given an installed operator (see above) and an install plan:

~~~
$ oc get csv
NAME                       DISPLAY     VERSION   REPLACES                   PHASE
datagrid-operator.v8.2.8   Data Grid   8.2.8     datagrid-operator.v8.2.7   Succeeded ← there is always one there
[fdemeloj@fdemeloj dg828]$ oc get ip
NAME            CSV                        APPROVAL   APPROVED
install-tmbnx   datagrid-operator.v8.2.8   Manual     true
~~~


The Data Grid Operator upgrade will be one of the two scenarios below:

  - If Approval is set for Manual: Change the channel to 8.3.x and approve the upgrades via Approved = true.
  - If Approval is set for Automatic: Change the channel to 8.3.x.

In the above scenario, to upgrade from Data Grid 8.2.8 to Data Grid 8.3.x, change the channel version on the subscription:

### get subscription
~~~
oc get sub
NAME                PACKAGE    SOURCE             CHANNEL
datagrid-operator   datagrid   redhat-operators   8.2.x
~~~
### edit the subscriptions
~~~
$ oc edit sub datagrid-operator
From:
  spec:
    channel: 8.2.x
To:
  spec:
  channel: 8.3.x
—> subscription.operators.coreos.com/datagrid-operator
~~~
~~~
$ oc get sub -o json | grep "channel"                 
"channel": "8.3.x”
~~~


The change above on the subscription will make the one Install Plan appear:

### get the install plan (ip):
~~~
$ oc get ip
NAME            CSV                        APPROVAL   APPROVED
install-tmbnx   datagrid-operator.v8.2.8   Manual     true
install-tmlfx   datagrid-operator.v8.3.3   Manual     false ← Approved == false
~~~


### edit from approved false to true:
~~~
oc patch ip install-tmlfx --type merge -p '{"spec":{"approved":true}}'
→ installplan.operators.coreos.com/install-tmlfx patched
~~~


And there we go—the Data Grid Operator 8.3.x is installed:
~~~
$ oc get csv
NAME                       DISPLAY     VERSION   REPLACES                   PHASE
datagrid-operator.v8.3.3   Data Grid   8.3.3     datagrid-operator.v8.2.8   Succeeded
~~~



Install a specific version and skip the upgrade process
=======================================================
The upgrade process described above can be skipped so one can install a specific version of Data Grid Operator directly. This is done via Subscription Operator 8.3.8 via Subscription to channel: 8.3.x and parameter startingCSV to 8.3.6:
~~~
- apiVersion: operators.coreos.com/v1alpha1
  kind: Subscription
  metadata:
    name: datagrid-operator
    namespace: ${OPERATOR_NAMESPACE}
  spec:
    channel: 8.3.x
    installPlanApproval: Manual
    name: datagrid
    source: redhat-operators
    sourceNamespace: openshift-marketplace
    startingCSV: datagrid-operator.v8.3.6 ←
~~~


So you can create a new namespace and install a new Data Grid Operator with a specific version.
Multiple Data Grid Operator versions in the same cluster

The Data Grid Operator is aimed for a singleton model, either namespace-bounded or cluster-wide installations. Therefore, having two Data Grid Operators (with different versions) in the same cluster is not supported—and certainly will cause problems, given the Custom Resource Definitions are cluster-wide resources—so for the whole cluster.

However, to counter this limitation, Data Grid Operator 8.4.x allows the installation of multiple Data Grid server versions called Operands, which allows one Data Grid Operator to handle multiple Data Grid servers simultaneously. This means one Data Grid Operator provides support for multiple version Data Grid servers running at the same time (multi-operand deployment).


Downgrading
===========
Unlike the AMQ Streams Operator or the OpenShift Service Mesh Operator, the Data Grid Operator does not allow downgrading. As a result, you must remove all Custom Resources, then Data Grid Operator, and then respective Custom Resource Definitions, which are installed together with the Data Grid Operator upon initial installation. Finally, re-install the desired Data Grid Operator version. As you can see, it is not a smooth process and needs to be thoroughly completed, given the Data Grid Operator deletion can still leave some objects on the OpenShift Container Platform cluster.


Operator Lifecycle Manager (OLM) framework
==========================================
In a nutshell, the OLM utilizes the channel information in the CatalogSource (CS) to fetch the Data Grid image bundle. The CatalogSource is indeed the index for the bundle, which then points to the Data Grid Operator image itself: ClusterServiceVersion (CSV). The Subscription references are used to determine the update graph of a given channel, and the bundle images in that channel are then pulled as needed.

The workflow is simplified below:

Operator Lifecycle Manager → CatalogSource (index) → bundle → image (CSV) → Catalog Operator installs the CRDs

Figure 1 exemplifies the OLM installation process.
argocd shop refresh
Figure 1: OLM Installation

It is the CSV in an Operator bundle that brings the CRDs. The Catalog Operator is responsible for installing the required CSV and is present on the OpenShift OLM namespace together with the OLM operator manager pod. For more information about the OLM, see this reference.


Conclusion
==========
In summary, the installation and upgrade of the Data Grid Operator above is shown in detail above. As well as installing a specific version of the Data Grid Operator. The process above can be generalized for other operators, for example, the EAP Operator or SSO Operator, given the respective subscription's details such as channel, name, and startingCSV spec features. This can be used to install a certain version, e.g., Data Grid 8.4.9 on OpenShift Container Platform 4.12. Furthermore, as explained above, having multiple Operators will cause issues.

Finally, although the Data Grid Operator 8.3.x is associated directly (and only with one Data Grid server version), the Data Grid Operator 8.4.x allows the installation of multiple Data Grid server versions. This extremely useful feature allows one Data Grid Operator to handle multiple Data Grid servers simultaneously keeping the Singleton Model.


Additional resources
====================
To learn more about the Data Grid Operator, see the Data Grid Operator Guide. Additionally, to learn more about the Data Grid server, see the Data Grid Server Guide.

For any other specific inquiries, please open a case with Red Hat support. Our global team of experts can help you with any issues.

Special thanks to Luke Stanton and Will Russell for the review of this article.
