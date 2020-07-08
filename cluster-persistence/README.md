# CLUSTERED BROKER TEMPLATE WITH DISK PERSISTENCE

This template will deploy a clustered AMQ Broker with disk persistence for Queues and Messages but no SSL.

Data will be stored under `/opt/amq/data` by default, and the mount point can be customized by changing the `AMQ_DATA_DIR` parameter when rendering the template.
Also, the `VOLUME_CAPACITY` parameter will control how big the backend PersistentVolumeClaim will be (by default it is 1Gi)

Replica number (by default 0) can be specified by setting the `AMQ_REPLICAS` parameters when rendering the template.

The template will assume that these objects are already created inside the target namespace:

1. A secret holding the Admin and Cluster credentials
```
oc creare secret generic amq-credentials-secret \
    --from-literal=AMQ_USER=admin \
    --from-literal=AMQ_PASSWORD=password \
    --from-literal=AMQ_CLUSTER_USER=clusteruser \
    --from-literal=AMQ_CLUSTER_PASSWORD=clusterpassword
```

2. A configmap holding all custom Artemis configuration files. (Pay attention to the artemis-users.properties, the `admin` password must be the same specified in the secret created during step 1)
```
oc create configmap amq-config-files \
    --from-file=artemis-users.properties=conf/artemis-users.properties \
    --from-file=artemis-roles.properties=conf/artemis-roles.properties \
    --from-file=broker.xml=conf/broker.xml \
    --from-file=jgroups-ping.xml=conf/jgroups-ping.xml
```

Deployment is performed by rendering the template and applying all resulting manifests

```
oc process -f amq-broker-77-custom-persistence-clustered.yaml -p AMQ_REPLICAS=2 -p AMQ_CLUSTERED=true -p VOLUME_CAPACITY=10Gi -p AMQ_DATA_DIR=/opt/amq/data | oc create -f -
```

