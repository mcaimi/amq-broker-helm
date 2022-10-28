{{- define "drainer.pod" -}}
alpha.image.policy.openshift.io/resolve-names: "*"
statefulsets.kubernetes.io/drainer-pod-template: |
 {
    "metadata": {
      "labels": {
        "app": "{{ .Values.application.name }}-amq-drainer"
      }
    },
    "spec": {
      "serviceAccount": "{{ tpl .Values.templates.service_account .}}",
      "serviceAccountName": "{{ tpl .Values.templates.service_account .}}",
      "terminationGracePeriodSeconds": 5,
      "containers": [
        {
          "env": [
            {
              "name": "APPLICATION_NAME",
              "value": "{{ .Values.application.name }}"
            },
            {
              "name": "HEADLESS_ENDPOINT",
              "value": "{{ tpl .Values.templates.service . }}"
            },
            {
              "name": "PING_SVC_NAME",
              "value": "{{ tpl .Values.ping_service.name . }}"
            },
            {
              "name": "AMQ_EXTRA_ARGS",
              "value": "--no-autotune"
            },
            {
              "name": "AMQ_USER",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "{{ tpl .Values.templates.app_secret . }}",
                  "key": "AMQ_USER"
                }
              }
            },
            {
              "name": "AMQ_PASSWORD",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "{{ tpl .Values.templates.app_secret . }}",
                  "key": "AMQ_PASSWORD"
                }
              }
            },
            {
              "name": "AMQ_ROLE",
              "value": "{{ .Values.admin.role }}"
            },
            {
              "name": "AMQ_NAME",
              "value": "{{ .Values.parameters.amq_broker_name }}"
            },
            {
              "name": "AMQ_TRANSPORTS",
              "value": "{{ .Values.parameters.amq_protocols }}"
            },
            {
              "name": "AMQ_GLOBAL_MAX_SIZE",
              "value": "{{ .Values.parameters.amq_global_max_size }}"
            },
            {
              "name": "AMQ_ALLOW_ANONYMOUS",
              "value": "{{ .Values.parameters.allow_anonymous }}"
            },
            {
              "name": "AMQ_DATA_DIR",
              "value": "{{ .Values.parameters.amq_data_dir }}"
            },
            {
              "name": "AMQ_DATA_DIR_LOGGING",
              "value": "{{ .Values.parameters.amq_data_dir_logging }}"
            },
            {
              "name": "AMQ_CLUSTERED",
              "value": "{{ .Values.parameters.amq_clustered }}"
            },
            {
              "name": "AMQ_REPLICAS",
              "value": "{{ .Values.application.replicas }}"
            },
            {
              "name": "AMQ_CLUSTER_USER",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "{{ tpl .Values.templates.app_secret .}}",
                  "key": "AMQ_CLUSTER_USER"
                }
              }
            },
            {
              "name": "AMQ_CLUSTER_PASSWORD",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "{{ tpl .Values.templates.app_secret .}}",
                  "key": "AMQ_CLUSTER_PASSWORD"
                }
              }
            },
            {
              "name": "POD_NAMESPACE",
              "valueFrom": {
                "fieldRef": {
                  "fieldPath": "metadata.namespace"
                }
              }
            },
            {
              "name": "OPENSHIFT_DNS_PING_SERVICE_PORT",
              "value": "{{ .Values.ping_service.jgroups.bind_port }}"
            }
          ],
          "image": "{{ tpl .Values.templates.broker_image .}}",
          "name": "{{ .Values.application.name }}-amq-drainer-pod",

          "command": ["/bin/sh", "-c", "echo \"Starting the drainer\" ; /opt/amq/bin/drain.sh; echo \"Drain completed! Exit code $?\""],
          "volumeMounts": [
            {
              "name": "{{ tpl .Values.templates.pvc_name . }}",
              "mountPath": "{{ .Values.parameters.amq_data_dir }}"
            }
          ]
        }
      ]
    }
  }
{{- end -}}
