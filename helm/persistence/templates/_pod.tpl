{{- define "amq.pod" -}}
containers:
- env:
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
    value: "{{ .Values.parameters.amq_admin_role }}"
  - name: AMQ_NAME
    value: "{{ .Values.parameters.amq_broker_name }}"
  - name: AMQ_TRANSPORTS
    value: "{{ .Values.parameters.amq_protocols }}"
  - name: AMQ_GLOBAL_MAX_SIZE
    value: "{{ .Values.parameters.amq_global_max_size }}"
  - name: AMQ_DATA_DIR
    value: "{{ .Values.parameters.amq_data_dir }}"
  - name: AMQ_REQUIRE_LOGIN
    value: "{{ .Values.parameters.amq_require_login }}"
  - name: AMQ_EXTRA_ARGS
    value: {{ if .Values.parameters.amq_extra_args }} "{{ .Values.parameters.amq_extra_args }}" {{ else }} "" {{ end }}
  - name: AMQ_ANYCAST_PREFIX
    value: {{ if .Values.parameters.amq_anycast_prefix }} "{{ .Values.parameters.amq_anycast_prefix }}" {{ else }} "jms.queue." {{ end }}
  - name: AMQ_MULTICAST_PREFIX
    value: {{ if .Values.parameters.amq_multicast_prefix }} "{{ .Values.parameters.amq_multicast_prefix }}" {{ else }} "jms.topic." {{ end }}
  - name: AMQ_ENABLE_METRICS_PLUGIN
    value: {{ .Values.parameters.amq_enable_metrics_plugin | quote }}
  - name: AMQ_JOURNAL_TYPE
    value: "{{ .Values.parameters.amq_journal_type }}"
  - name: BROKER_XML
    valueFrom:
      configMapKeyRef:
        name: {{ tpl .Values.templates.config_cm . }}
        key: broker.xml
  image: {{ tpl .Values.templates.broker_image . }}
  imagePullPolicy: {{ .Values.application.pullPolicy }}
  readinessProbe:
    exec:
      command:
      - "/bin/bash"
      - "-c"
      - "/opt/amq/bin/readinessProbe.sh"
  name: {{ tpl .Values.templates.deployment . }}
  ports:
  {{- range .Values.service }}
  - containerPort: {{ .port }}
    name: {{ .name }}
    protocol: {{ .protocol }}
  {{- end }}
  volumeMounts:
    - name: {{ tpl .Values.templates.pvc_name . }}
      mountPath: {{ .Values.parameters.amq_data_dir }}
    - name: broker-config-script-custom
      mountPath: /opt/amq/bin/configure_custom_config.sh
      subPath: configure_custom_config.sh
      readOnly: true
    - name: broker-config-volume
      mountPath: "/opt/amq/conf"
      readOnly: true
terminationGracePeriodSeconds: 60
volumes:
  - name: broker-config-script-custom
    configMap:
      name: {{ tpl .Values.templates.override_cm . }}
      items:
        - key: configure_custom_config.sh
          path: configure_custom_config.sh
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
  {{- if eq .Values.kind "Deployment" }}
  - name: {{ tpl .Values.templates.pvc_name . }}
    persistentVolumeClaim:
      claimName: {{ tpl .Values.templates.pvc_name . }}
  {{- end }}
{{- end }}