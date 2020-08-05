# CLUSTERED BROKER HELM CHART WITH DISK PERSISTENCE AND SSL SUPPORT

This chart will deploy a clustered broker with disk persistence and no SSL endpoint.
*This is still heavily in development, it is definitely not ready to be used in a production environment*

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
  name: amq-broker-persistence
  rolloutTrigger: ConfigChange
  [...]
  volume_capacity: "1G"
  replicas: 2

[...]
parameters:
  [...]
  amq_clustered: True
```

```
parameters:
  [...]
  amq_data_dir: "/opt/amq/data"
  [...]
```

the application name will be used as a prefix for most of the objects deployed by the Chart itself.

- Update the Admin user name and password in `values.yaml`, and also the cluster user credentials:

```
admin:
  user: admin
  password: password
  cluster_user: cluster_admin
  cluster_password: cluster_password
  role: admin
``` 

- Choose a node port TCP value and corresponding service for the external service in `values.yaml`:

```
nodeport:
  port: 30002
  service: multiplex
```
this port needs to be in the allowed NodePort range set up in the kubelet (typically in the range 30000-32768)

- Configure the JGroups ping service for the cluster in `values.yaml`

```
ping_service:
  name: "{{ .Values.application.name }}-ping-svc"
  port: 8888
```

- Install the Chart under your preferred project

```
$ oc new-project amq-cluster-ssl
$ helm install amq-cluster-ssl .
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
