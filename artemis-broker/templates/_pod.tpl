{{- define "amq.pod" -}}
{{- if eq .Values.platform "kubernetes" -}}
imagePullSecrets:
  - name: {{ .Values.application.pullSecretName }}
{{- end }}
containers:
- env:
{{- if .Values.clustered }}
  - name: APPLICATION_NAME
    value: "{{ .Values.application.name }}"
  - name: PING_SVC_NAME
    value: "{{ tpl .Values.ping_service.name . }}"
  - name: AMQ_CLUSTERED
    value: "{{ .Values.clustered }}"
  - name: AMQ_REPLICAS
    value: "{{ .Values.application.replicas }}"
  - name: AMQ_CLUSTER_USER
    valueFrom:
      secretKeyRef:
        name: {{ tpl .Values.templates.app_secret . }}
        key: AMQ_CLUSTER_USER
  - name: AMQ_CLUSTER_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ tpl .Values.templates.app_secret . }}
        key: AMQ_CLUSTER_PASSWORD
  - name: OPENSHIFT_DNS_PING_SERVICE_PORT
    value: "{{ .Values.ping_service.jgroups.bind_port }}"
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
{{- end }}
  - name: AMQ_USER
    valueFrom:
      secretKeyRef:
        name: {{ tpl .Values.templates.app_secret . }}
        key: AMQ_USER
  - name: AMQ_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ tpl .Values.templates.app_secret . }}
        key: AMQ_PASSWORD
  - name: AMQ_ROLE
    value: "{{ .Values.admin.role }}"
  - name: AMQ_NAME
    value: "{{ .Values.parameters.amq_broker_name }}"
  - name: AMQ_TRANSPORTS
    value: "{{ .Values.parameters.amq_protocols }}"
  {{- if .Values.parameters.tls_enabled }}
  - name: AB_JOLOKIA_HTTPS
    value: "{{ .Values.parameters.jolokia_passthrough }}"
  - name: AMQ_KEYSTORE_TRUSTSTORE_DIR
    value: {{ .Values.tls.secret_mount_path }}
  - name: AMQ_TRUSTSTORE
    value: {{ .Values.tls.truststore }}
  - name: AMQ_TRUSTSTORE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ tpl .Values.templates.app_certificates . }}
        key: AMQ_TRUSTSTORE_PASSWORD
  - name: AMQ_KEYSTORE
    value: {{ .Values.tls.keystore }}
  - name: AMQ_KEYSTORE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ tpl .Values.templates.app_certificates . }}
        key: AMQ_KEYSTORE_PASSWORD
  - name: AMQ_SSL_PROVIDER
    value: {{ tpl .Values.parameters.ssl_provider . }}
  {{- end }}
  - name: AMQ_GLOBAL_MAX_SIZE
    value: "{{ .Values.parameters.amq_global_max_size }}"
  - name: AMQ_REQUIRE_LOGIN
    value: "{{ .Values.parameters.amq_require_login }}"
  {{- if .Values.application.persistent }}
  - name: AMQ_DATA_DIR
    value: "{{ .Values.parameters.amq_data_dir }}"
  {{- end }}
  - name: AMQ_EXTRA_ARGS
    value: {{ if .Values.parameters.amq_extra_args }} "{{ .Values.parameters.amq_extra_args }}" {{ else }} "" {{ end }}
  - name: AMQ_ANYCAST_PREFIX
    value: {{ if .Values.parameters.amq_anycast_prefix }} "{{ .Values.parameters.amq_anycast_prefix }}" {{ else }} "jms.queue." {{ end }}
  - name: AMQ_MULTICAST_PREFIX
    value: {{ if .Values.parameters.amq_multicast_prefix }} "{{ .Values.parameters.amq_multicast_prefix }}" {{ else }} "jms.topic." {{ end }}
  - name: AMQ_ENABLE_METRICS_PLUGIN
    value: {{ .Values.metrics.enabled | quote }}
  - name: AMQ_JOURNAL_TYPE
    value: "{{ .Values.parameters.amq_journal_type }}"
  image: {{ tpl .Values.templates.broker_image . }}
  {{- with .Values.resources }}
  resources:
  {{- toYaml . | nindent 4 -}}
  {{- end }}
  imagePullPolicy: {{ .Values.application.pullPolicy }}
  readinessProbe:
    exec:
      command:
      - "/bin/bash"
      - "-c"
      - "/opt/amq/bin/readinessProbe.sh"
  name: {{ tpl .Values.templates.deployment . }}
  ports:
  {{- range .Values.service.acceptors }}
  - containerPort: {{ .port }}
    name: {{ .name }}
    protocol: {{ .protocol }}
  {{- end }}
  {{- range .Values.service.console }}
  - containerPort: {{ .port }}
    name: {{ .name }}
    protocol: {{ .protocol }}
  {{- end }}
  volumeMounts:
  {{- if .Values.application.persistent }}
    - name: {{ tpl .Values.templates.pvc_name . }}
      mountPath: {{ .Values.parameters.amq_data_dir }}
  {{- end }}
    - name: broker-config-script-custom
      mountPath: /opt/amq/bin/configure_custom_config.sh
      subPath: configure_custom_config.sh
      readOnly: true
    - name: broker-config-script-custom
      mountPath: /opt/amq/bin/launch.sh
      subPath: launch.sh
      readOnly: true
  {{- if .Values.clustered }}
    - name: broker-config-script-custom
      mountPath: /opt/amq/bin/drain.sh
      subPath: drain.sh
      readOnly: true
  {{- end }}
    - name: broker-config-volume
      mountPath: "/opt/amq/conf"
      readOnly: true
    {{- if .Values.parameters.tls_enabled }}
    - mountPath: {{ .Values.tls.secret_mount_path }}
      name: broker-secret-volume
      readOnly: true
    {{- end }}
terminationGracePeriodSeconds: 60
volumes:
  {{- if .Values.parameters.tls_enabled }}
  - name: broker-secret-volume
    secret:
      secretName: {{ tpl .Values.templates.app_certificates . }}
  {{- end }}
  - name: broker-config-script-custom
    configMap:
      name: {{ tpl .Values.templates.override_cm . }}
      items:
        - key: configure_custom_config.sh
          path: configure_custom_config.sh
        - key: launch.sh
          path: launch.sh
      {{- if .Values.clustered }}
        - key: drain.sh
          path: drain.sh
      {{- end }}
      defaultMode: 0550
  - name: broker-config-volume
    projected:
      sources:
        - configMap:
            name: {{ tpl .Values.templates.config_cm . }}
        {{- range .Values.security.secrets }}
        - secret:
            name: {{ . }}
        {{- end }}
  {{- if and (eq .Values.kind "Deployment") (.Values.application.persistent) }}
  - name: {{ tpl .Values.templates.pvc_name . }}
    persistentVolumeClaim:
      claimName: {{ tpl .Values.templates.pvc_name . }}
  {{- end }}
{{- end }}
