# SSL-ENABLED BROKER HELM CHART

This chart will deploy a basic ssl-enabled broker with no persistence.

## INSTALLATION

The most basic deployment can be performed by following these steps:

- Create (or import) a keystore/truststore pair for this broker: look [here](https://github.com/mcaimi/amq-custom-templates-openshift/blob/master/README.md) for an howto. Put the files under `tls/` and update the tls section in `values.yaml`:

```
tls:
  keystore: keystore.ks
  truststore: keystore.ts
  keystore_password: kspwd
  truststore_password: tspwd
```

- Customize the application name in `values.yaml`:

```
application:
  name: amq-broker-persistence-ssl
  [...]
  volume_capacity: "1G"
```

```
parameters:
  [...]
  amq_data_dir: "/opt/amq/data"
  [...]
```

the application name will be used as a prefix for most of the objects deployed by the Chart itself.

- Update the Admin user name and password in `values.yaml`

```
admin:
  user: admin
  password: password
  role: admin
``` 

- If needed, enable and choose a node port TCP value and corresponding service for the external service in `values.yaml`:

```
nodeport:
  port: 30003
  service: multiplex-ssl
  enabled: true
```
this port needs to be in the allowed NodePort range set up in the kubelet (typically in the range 30000-32768)

- Install the Chart under your preferred project

```
$ oc new-project amq-demo-persistence-ssl
$ helm install amq-persistence-ssl .
```

After a while, the broker should be up and running:

```
$ oc get all
NAME                               READY   STATUS      RESTARTS   AGE
pod/amq-broker-basic-dc-1-deploy   0/1     Completed   0          13m
pod/amq-broker-basic-dc-1-trrsw    1/1     Running     0          13m

NAME                                          DESIRED   CURRENT   READY   AGE
replicationcontroller/amq-broker-basic-dc-1   1         1         1       13m

NAME                                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
service/amq-broker-basic-svc-amqp      ClusterIP   172.25.221.5    <none>        5672/TCP          13m
service/amq-broker-basic-svc-jolokia   ClusterIP   172.25.51.89    <none>        8161/TCP          13m
service/amq-broker-basic-svc-mqtt      ClusterIP   172.25.14.64    <none>        1883/TCP          13m
service/amq-broker-basic-svc-stomp     ClusterIP   172.25.196.97   <none>        61613/TCP         13m
service/amq-broker-basic-svc-tcp       ClusterIP   172.25.56.105   <none>        61616/TCP         13m
service/artemis-nodeport-svc           NodePort    172.25.159.17   <none>        61616:30000/TCP   13m

NAME                                                     REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfig.apps.openshift.io/amq-broker-basic-dc   1          1         1         config

NAME                                                      HOST/PORT                                                  PATH   SERVICES                       PORT    TERMINATION   WILDCARD
route.route.openshift.io/amq-broker-basic-route-console   amq-broker-basic-route-console-amq-demo.apps-crc.testing          amq-broker-basic-svc-jolokia   <all>                 None
```

## ADDING QUEUES, USERS AND ROLES

To add multiple users to the broker edit the `users` section in `values.yaml`. For example, this setup here:

```
users:
  - name: demouser
    password: "demo"
    role: user
  - name: anotheruser
    password: "demo1"
    role: user
```

would be rendered by the Helm Chart into these two files:

- `artemis-users.properties`

```
    ## CUSTOMCONFIG
    
    # ADMIN USER
    admin = password
    
    # ADDITIONAL USERS
    demouser = demo
    anotheruser = demo1
```

- `artemis-roles.properties`

```
    ## CUSTOMCONFIG
    # ADMIN ROLE MAPPING
    admin = admin

    # ADDITIONAL ROLE MAPPING
    user = demouser
    user = anotheruser
```

The `queues` section in `values.yaml` allows to add custom queues to the broker at install time. For example, this setup:

```
queues:
  - name: demoQueue
    permissions:
      - grant: consume
        roles:
          - admin
          - user
      - grant: browse
        roles:
          - admin
          - user
      - grant: send
        roles:
          - admin
          - user
      - grant: manage
        roles:
          - admin
```

would result in this rendered section inside `broker.xml`:

```
            <security-setting match="demoQueue">
             <permission type="consume" roles="admin,user," />
             <permission type="browse" roles="admin,user," />
             <permission type="send" roles="admin,user," />
             <permission type="manage" roles="admin," />
             </security-setting>
```
