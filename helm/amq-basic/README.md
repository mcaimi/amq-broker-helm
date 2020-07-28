# BASIC BROKER HELM CHART

This chart will deploy a basic broker with no persistence and no SSL endpoint.

## BASIC INSTALLATION

The most basic deployment can be performed by following these steps:

- Customize the application name in `values.yaml`:

```
application:
  name: amq-broker-basic
  rolloutTrigger: ConfigChange
  [...]
```

the application name will be used as a prefix for most of the objects deployed by the Chart itself.

- Create a Kubernetes Secret with the default admin username and password

```
$ oc create secret generic amq-broker-basic-secret
        --from-literal=AMQ_USER=admin \
        --from-literal=AMQ_PASSWORD=password
``` 
Be aware that the name of the secret must be equal to "<application name>-secret" for the chart to pick it up.

- Choose a node port TCP value for the external service:

```
application:
  [...]
  nodePort: 30001
  [...]
```
this port needs to be in the allowed NodePort range set up in the kubelet (typically in the range 30000-32768)

- Install the Chart under your preferred project

```
$ oc new-project amq-demo
$ helm install amq-basic .
NAME: amq-basic
LAST DEPLOYED: Tue Jul 28 11:16:10 2020
NAMESPACE: amq-demo
STATUS: deployed
REVISION: 1
TEST SUITE: None
$ helm list
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART                                   APP VERSION
amq-basic       amq-demo        1               2020-07-28 11:16:10.373612234 +0200 CEST        deployed        AMQ Broker Basic deployment Chart-1.0

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

To add users to the broker edit the `users` section in `values.yaml`. For example, this setup here:

```
users:
  - name: admin
    password: "password"
    role: admin
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
    admin = password
    demouser = demo
    anotheruser = demo1
```

- `artemis-roles.properties`

```
    ## CUSTOMCONFIG
    admin = admin
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
