# BROKER TEMPLATE WITH STORAGE PERSISTENCE

This template will deploy a broker with disk persistence and no SSL endpoint.

Data will be stored under `/opt/amq/data` by default, and the mount point can be customized by changing the `AMQ_DATA_DIR` parameter when rendering the template.
Also, the `VOLUME_CAPACITY` parameter will control how big the backend PersistentVolumeClaim will be (by default it is 1Gi)

It assumes a configmap with pre-configured custom files is already present in the target namespace:

```
oc create configmap amq-config-files \
    --from-file=artemis-users.properties=conf/artemis-users.properties \
    --from-file=artemis-roles.properties=conf/artemis-roles.properties \
    --from-file=broker.xml=conf/broker.xml \
    --from-file=jgroups-ping.xml=conf/jgroups-ping.xml
```

Deployment is performed by rendering the template and applying all resulting manifests

```
oc process -f amq-broker-77-custom-persistence.yaml -p VOLUME_CAPACITY=10Gi -p AMQ_DATA_DIR=/opt/amq/data | oc create -f -
```

