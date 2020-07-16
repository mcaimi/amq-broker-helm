# BASIC BROKER TEMPLATE

This template will deploy a basic broker with no persistence and no SSL endpoint.
It assumes a configmap with pre-configured custom files is already present in the target namespace:

```
oc create configmap amq-config-files \
    --from-file=artemis-users.properties=conf/artemis-users.properties \
    --from-file=artemis-roles.properties=conf/artemis-roles.properties \
    --from-file=broker.xml=conf/broker.xml \
    --from-file=jgroups-ping.xml=conf/jgroups-ping.xml
```

In the case you want to add new parameters/env variables to the template that need to be rendered inside configuration files (`broker.xml` for example), this override script needs to be injected inside the container image:

```
oc create configmap amq-script-override-custom \
    --from-file=configure_custom_config.sh=scripts-override/configure_custom_config.sh
```

Deployment is performed by rendering the template and applying all resulting manifests

```
oc process -f amq-broker-77-custom-basic.yaml | oc create -f -
```

