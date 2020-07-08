# BASIC BROKER TEMPLATE WITH SSL

This template will deploy a basic broker with endpoint protected with an SSL certificate stored in a java keystore.
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

Deployment can be started by rendering the template and by applying the resulting manifests:

```
oc process -f amq-broker-77-custom-ssl.yaml | oc create -f -
```
