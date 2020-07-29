# CUSTOM RED HAT AMQ BROKER TEMPLATES FOR OPENSHIFT

With these custom templates an user can deploy an AMQ Broker instance with custom configurations:

1. Custom broker.xml file
2. Custom artemis-users and artemis-roles property files
3. Customizable per-queue security settings

Available Templates | Repository Link
------------------- | ---------------
Basic AMQ Broker | [BASIC](https://github.com/mcaimi/amq-custom-templates-openshift/tree/master/basic)
Basic AMQ Broker with SSL | [BASIC SSL](https://github.com/mcaimi/amq-custom-templates-openshift/tree/master/ssl)
AMQ Broker with Storage Persistence | [PERSISTENCE](https://github.com/mcaimi/amq-custom-templates-openshift/tree/master/persistence)
AMQ Broker with Storage Persistence and SSL | [PERSISTENCE-SSL](https://github.com/mcaimi/amq-custom-templates-openshift/tree/master/persistence-ssl)
Clustered AMQ Broker with Persistence | [CLUSTER-PERSISTENCE](https://github.com/mcaimi/amq-custom-templates-openshift/tree/master/cluster-persistence)
Clustered AMQ Broker with Persistence and SSL | [CLUSTER-PERSISTENCE-SSL](https://github.com/mcaimi/amq-custom-templates-openshift/tree/master/cluster-persistence-ssl)

Development is also starting to convert all those templates to Helm Charts: charts will be added when conversion is finished.

Avaliable Helm Charts | Repo Link
--------------------- | ---------
Basic Helm Chart | [amq-basic](https://github.com/mcaimi/amq-custom-templates-openshift/tree/master/helm/amq-basic)

For any of the OpenShift templates, the list of available parameters can be retrieved by running:

```
oc process --parameters -f <template_file_name>.yaml
```

For example, for the "basic" template:

```
^ >> oc process --parameters -f basic/amq-broker-77-custom-basic.yaml
NAME                        DESCRIPTION
                                                   GENERATOR           VALUE
APPLICATION_NAME            The name for the application.
                                                                       broker
AMQ_PROTOCOL                Protocols to configure, separated by commas. Allowed values are: `openwire`, `amqp`, `stomp`, `mqtt` and `hornetq`.
                                                                       openwire,amqp,stomp,mqtt,hornetq
AMQ_QUEUES                  Queue names, separated by commas. These queues will be automatically created when the broker starts. If left empty, queues will be still created dynamically.

AMQ_ADDRESSES               Address names, separated by commas. These addresses will be automatically created when the broker starts. If left empty, addresses will be still created dynamically.

AMQ_ROLE                    User role for standard broker user.
                                                                       admin
AMQ_NAME                    The name of the broker
                                                                       broker
AMQ_GLOBAL_MAX_SIZE         Maximum amount of memory which message data may consume (Default: Undefined, half of the system's memory).
                                                                       100 gb
AMQ_REQUIRE_LOGIN           Determines whether or not the broker will allow anonymous access, or require login

AMQ_EXTRA_ARGS              Extra arguments for broker creation

AMQ_ANYCAST_PREFIX          Anycast prefix applied to the multiplexed protocol port 61616

AMQ_MULTICAST_PREFIX        Multicast prefix applied to the multiplexed protocol port 61616

IMAGE_STREAM_NAMESPACE      Namespace in which the ImageStreams for Red Hat Middleware images are installed. These ImageStreams are normally installed in the openshift namespace. You should only need to modify this if you've installed the ImageStreams in a different namespace/project.                       openshift
IMAGE                       Broker Image
                                                                       registry.redhat.io/amq7/amq-broker:7.7
AMQ_CREDENTIAL_SECRET       Name of a secret containing credential data such as passwords and SSL related files
                                                                       amq-credentials-secret
AMQ_ENABLE_METRICS_PLUGIN   Whether to enable artemis metrics plugin
                                                                       false
AMQ_JOURNAL_TYPE            Journal type to use; aio or nio supported
                                                                       nio
```

## SSL-ENABLED TEMPLATES

In order to deploy SSL-enabled templates, a secret with valid Java Truststore and Keystore files must be created. This is true for both the Openshift Templates and Helm Charts.
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

If passwords are needed to unlock the keystore and the truststore, where applicable save these in the appropriate secret by setting the `AMQ_KEYSTORE_PASSWORD` and `AMQ_TRUSTSTORE_PASSWORD` parameters.
