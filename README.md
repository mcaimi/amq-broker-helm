# RED HAT AMQ BROKER HELM CHART

This chart handles the deployment of RedHat AMQ broker instances on both OCP and generic k8s distributions. These deployment flavors are supported:

1. Standalone AMQ Broker
2. Choice between `Deployment` and `StatefulSet`
3. TLS optional
4. Persistence is optional. (Needs a supported StorageClass)
5. NodePorts and Passthrough Routes
6. Optional Prometheus monitoring
7. Optional Clustering (WIP)
8. Deployment compatibility with both Openshift and base Kubernetes

|NAME                              | DESCRIPTION                                              | DEFAULT VALUE |
|----------------------------------|----------------------------------------------------------|----------------|
| kind                             | Deploy broker as Deployment or StatefulSet               | `Deployment` |
| clustered                        | Deploy a clustered broker                                | `False` |
| platform                         | Choose platform type (openshift or kubernetes)           | `openshift` |
| application.name                 | The name for the application.                            | `amq-broker-persistence` |
| application.amq_broker_version   | Broker Image tag                                         | `7.7` |
| application.amq_broker_image     | Broker Image name                                        | `registry.redhat.io/amq7/amq-broker` |
| application.pullPolicy           | Pull policy                                              | `IfNotPresent` |
| application.replicas             | Number of replicas for a clustered broker                | `2` |
| application.volume_capacity      | Size of persistent volume                                | `1G` |
| service.console                  | Jolokia console port and configuration | See values.yaml |
| service.acceptors                | Array of acceptors. Only the multiplex is exposed by default | See values.yaml |
| ingress                          | Ingress configuration (only applies to kubernetes platform | See values.yaml |
| ingress.passthrough              | Passthrough ingress rule options (k8s only)              | See values.yaml |
| ingress.console                  | Artemis console ingress rule options (k8s only)          | See values.yaml |
| tls.keystore                     | Name of the keystore file                                | See values.yaml |
| tls.truststore                   | Name of the truststoreile                                | See values.yaml |
| tls.keystore_password            | Password to unlock the keystore on container boot        | See values.yaml |
| tls.truststore_password          | Password to unlock the truststore on container boot      | See values.yaml |
| nodeport.enabled                 | Create node port to expose AMQ to clients outside of the cluster | `30002` |
| nodeport.port                    | Node port number used when enabled | `30002` |
| passthrough_route.enabled        | Create a passthrough route to allow inbound TCP/SNI connections to a TLS-enabled broker | `False` |
| parameters.tls_enabled           | Enable or disable TLS support for acceptors | `false` |
| parameters.jolokia_passthrough   | Configure TLS for the jolokia console as a passthrough route or an edge terminated route if tls_enabled is set to true | `false` |
| parameters.amq_protocols         | Protocols to configure, separated by commas. Allowed values are: `openwire`, `amqp`, `stomp`, `mqtt` and `hornetq`. | `openwire,amqp,stomp,mqtt,hornetq` |
| parameters.amq_broker_name       | Broker name (TODO is this used? Same as application.name ) | `broker` |
| parameters.amq_admin_role        | Admin role | `admin` |
| parameters.amq_global_max_size   | Maximum amount of memory which message data may consume ( TODO: 100 gb as default is a bit high for most systems) | `"100 gb"` |
| parameters.amq_require_login     | Determines whether or not the broker will allow anonymous access, or require login | `False` |
| parameters.amq_extra_args        | Extra arguments for broker creation  | `` |
| parameters.amq_anycast_prefix    | Anycast prefix applied to the multiplexed protocol port 61616   | `jmx.queue.` |
| parameters.amq_multicast_prefix  | Multicast prefix applied to the multiplexed protocol port 61616   | `jmx.topic.` |
| parameters.amq_enable_metrics_plugin | Whether to enable artemis metrics plugin | `False` |
| parameters.amq_journal_type      | Journal type to use; aio or nio supported | `nio` |
| parameters.amq_data_dir          | Directory for storing data | `/opt/amq/data` |
| templates.service                | Template for service name | See values.yaml |
| templates.deployment             | Template for deployment name | See values.yaml |
| templates.route                  | Template for route name | See values.yaml |
| templates.broker_image           | Template for image name | See values.yaml |
| templates.override_cm            | Template for ConfigMap name containing overrides | See values.yaml |
| templates.config_cm              | Template for ConfigMap nggame | See values.yaml |
| templates.app_secret             | Template for name of a secret containing credential data such as users and passwords | See values.yaml |
| templates.pvc_name               | Template for persistent volume name | See values.yaml |
| security.enabled                 | Enabled security | `true` |
| security.secrets                 | Array of names of additional secrets to mount into /opt/amq/conf  | [] |
| security.createSecret            | Create secret with users and passwords. Disable when secrets is created outside of this chart. For example by ExternalSecret | `true` |
| security.jaasUsers.key           | Specify the key (filename) of the user/password file in the secret | `artemis-users.properties` |
| admin.user                       | Admin user. Mandatory even if security.createSecret is `false`) | `admin` |
| admin.password                   | Admin password. Optional. Only used if security.createSecret is `true` | `password` |
| admin.role                       | Admin role name | `admin` |
| users                            | Array of additional users. Only used if security.createSecret is `true` else users are expected to be defined in secret. | [] |
| queue.defaults                   | Default values for queues parameters | [] |
| queue.addresses                  | Array of queues to create. | [] |
| metrics.enabled                  | Enable metrics in AMQ and let Prometheus collect metrics using ServiceMonitor | `false` |
| metrics.jvm_memory               | Enable JVM memory metrics | `true` |
| metrics.jvm_gc                   | Enable JVM garbage collection statistics in metrics | `false` |
| metrics.jvm_threads              | Enable JVM Thread statistics | `false` |
| metrics.servicemonitor.port      | Collect metrics from this port. Default is the management port.  | `8161` |
| metrics.servicemonitor.interval  | Metrics are collected with fixed interval.  | `20s` |
| resources                        | Kubernetes limits and resources to attach to pod templates | See values.yaml |

## INSTALLATION

The most basic deployment can be performed by following these steps:

### Disk Persistence:

Every deployment flavor (TLS and Non-TLS) can be made persistent by setting the `persitent` flag to `true`:

```
application:
  [...]
  volume_capacity: "1G"
  persistent: true
```

### Non-TLS AMQ Brokers

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
  tls_enabled: false
  [...]
```

If needed, the broker can be consumed by clients running outside OCP by deploying a NodePort resource:

```
nodeport:
  [...]
  enabled: true
```

Since no TLS passthrough is possible without proper tls support, the passthrough_route should be disabled:

```
passthrough_route:
  enabled: false
  [...]
```

### TLS-enabled AMQ Brokers

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
  name: amq-broker-artemis
  [...]
  volume_capacity: "1G"
```

```
parameters:
  [...]
  tls_enabled: true
  jolokia_passthrough: false # set this to true if you want to use the same keystore for the jolokia console too. in this case the route will be created as passthrough
  amq_data_dir: "/opt/amq/data"
  [...]
```

For TLS-enabled brokers, both the NodePort and the Passthrough route options are working. Both can be enabled at the same time.

### Common Setup

The application name will be used as a prefix for most of the objects deployed by the Chart itself.

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
  service: multiplex
  enabled: true
```
this port needs to be in the allowed NodePort range set up in the kubelet (typically in the range 30000-32768)

- Install the Chart under your preferred project

```
$ oc new-project amq-demo-artemis
$ helm install amq-broker-artemis .
```

After a while and depending on what options are enabled in the values file, the broker should be up and running:

```
$ oc get all
NAME                                         READY   STATUS    RESTARTS   AGE
pod/amq-broker-artemis-dc-6f7658dbc7-xgxll   1/1     Running   0          86s

NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
service/amq-broker-artemis-nodeport-svc   NodePort    172.30.208.78    <none>        61616:30003/TCP      87s
service/amq-broker-artemis-svc            ClusterIP   172.30.194.187   <none>        61616/TCP,8161/TCP   87s

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/amq-broker-artemis-dc   1/1     1            1           87s

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/amq-broker-artemis-dc-6f7658dbc7   1         1         1       87s

NAME                                                        HOST/PORT                                                               PATH   SERVICES                 PORT   TERMINATION     WILDCARD
route.route.openshift.io/amq-broker-artemis-route-console   amq-broker-artemis-route-console-amq-helm-test.apps.lab01.gpslab.club          amq-broker-artemis-svc   8161   edge/Redirect   None
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

Users and passwords may be stored in an existing secret instead of as clear text in the values.yaml: disable the creation of the built-in user secret and specify the name of an existing secret.

Set the `jaasUsers.key` to the filename used in the secret. Note that the filename have to be something different from `artemis-users.properties` as the default file will be mounted in the same directory in the container.  

For example: 
```
security:
  secrets:
    - broker-external-secret
  createSecret: false
  jaasUsers:
    key: my-secured-artemis-users.properties

```

*Note*, that the AMQ_USER and AMQ_PASSWORD *must* be set, as the broker still uses these environment parameters:

```
stringData:
  AMQ_USER: broker-admin
  AMQ_PASSWORD: mySecretPassword
  my-secured-artimis-users.properties: |
    # ADMIN USER
    broker-admin = mySecretPassword
    # ADDITIONAL USERS
    consumer-user = otherSecretPassword
type: Opaque
```

The `queues` section in `values.yaml` allows to add custom queues to the broker at install time. For example, this setup:

```
queues:
  defaults:
    [...]
  addresses:
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

the defaults section under the queues stanza contains the values set for every queue if not overridden on a per queue basis.

## Metering

An optional prometheus ServiceMonitor is shipped with the chart. See values.yaml (metering stanza) for configuration.

## Clustering

Optional clustering is somewhat supported, but it is still considered WIP.

## Kubernetes support

AMQ Broker can be deployed also on standard Kubernetes clusters:

1. Ingress Rules are deployed instead of Openshift Routes for both the console and the passthrough route
2. A valid RedHat pull secret needs to be explicitly created in order to pull the AMQ broker images from registry.redhat.io:

```
$ kubectl create secret docker-registry <PULL SECRET NAME> \
          --docker-server=registry.redhat.io \
          --docker-username=<CUSTOMER PORTAL USERNAME> \
          --docker-password=<CUSTOMER PORTAL PASSWORD> \
          --docker-email=<email address>
```

The secret created with the command shown above needs to be set up in the _values.yaml_ file:

```
[...]
application:
[...]
  pullSecretName: <PULL SECRET NAME>
[...]
```

## KEYSTORE CREATION MINI-HOWTO

In order to deploy SSL-enabled templates, a secret with valid Java Truststore and Keystore files must be created.
To create a keystore:

1. Generate a self-signed certificate for the broker keystore:
```
$ keytool -genkey -alias broker -keyalg RSA -keystore broker.ks
```

2. Export the certificate so that it can be shared with clients:
```
$ keytool -export -alias broker -keystore broker.ks -file broker_cert
```

3. Generate a self-signed certificate for the client keystore:
```
$ keytool -genkey -alias client -keyalg RSA -keystore client.ks
```

4. Create a client truststore that imports the broker certificate:
```
$ keytool -import -alias broker -keystore client.ts -file broker_cert
```

5. Export the client’s certificate from the keystore:
```
$ keytool -export -alias client -keystore client.ks -file client_cert
```

6. Import the client’s exported certificate into a broker SERVER truststore:
```
$ keytool -import -alias client -keystore broker.ts -file client_cert
```

