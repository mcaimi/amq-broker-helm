# BROKER TEMPLATE WITH DISK PERSISTENCE AND SSL

This template will deploy a broker with endpoint protected with an SSL certificate stored in a java keystore. It also have disk persistence for Queues and Messages.

Data will be stored under `/opt/amq/data` by default, and the mount point can be customized by changing the `AMQ_DATA_DIR` parameter when rendering the template.
Also, the `VOLUME_CAPACITY` parameter will control how big the backend PersistentVolumeClaim will be (by default it is 1Gi)

The template assumes that these objects have been already created in the target namespace:

1. A secret containing the username and password that unlock the keystore:
```
oc create secret generic amq-truststore-credentials \
    --from-literal=AMQ_TRUSTSTORE_PASSWORD=tspass \
    --from-literal=AMQ_KEYSTORE_PASSWORD=kspass
```

2. A secret containing the keystore and truststore files:
```
oc create secret generic amq-ssl-secret \
    --from-file=broker.ks=conf/broker.ks \
    --from-file=broker.ts=conf/broker.ts
```

3. A configmap holding all custom artemismq config files:
```
oc create configmap amq-config-files \
    --from-file=artemis-users.properties=conf/artemis-users.properties \
    --from-file=artemis-roles.properties=conf/artemis-roles.properties \
    --from-file=broker.xml=conf/broker.xml \
    --from-file=jgroups-ping.xml=conf/jgroups-ping.xml
```

Also, due to a problem with custom broker.xml and the `AMQ_DATA_DIR` parameter, a custom config script needs to be overridden:

```
oc create configmap amq-script-override-custom \
    --from-file=configure_custom_config.sh=scripts-override/configure_custom_config.sh
```

Deployment can be started by rendering the template and by applying the resulting manifests:

```
oc process -f amq-broker-77-custom-persistence-ssl.yaml -p VOLUME_CAPACITY=10Gi -p AMQ_DATA_DIR=/opt/amq/data | oc create -f -
```
