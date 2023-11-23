apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${PACKAGE}-webhook
  labels:
    app: ${PACKAGE}-webhook
  namespace: ${NAMESPACED}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${PACKAGE}-webhook
  template:
    metadata:
      labels:
        app: ${PACKAGE}-webhook
    spec:
      containers:
        - name: ${PACKAGE}-webhook
          image: ${REGISTRY}/${PACKAGE}-webhook:${VERSION}
          imagePullPolicy: IfNotPresent
          command:
            - /${PACKAGE}
          args:
            - -tls-cert-file=/etc/webhook/certs/tls.crt
            - -tls-key-file=/etc/webhook/certs/tls.key
          volumeMounts:
            - name: webhook-certs
              mountPath: /etc/webhook/certs
              readOnly: true
      volumes:
        - name: webhook-certs
          secret:
            secretName: ${PACKAGE}-webhook-certs
      imagePullSecrets:
        - name: default-secret
---
apiVersion: v1
kind: Service
metadata:
  name: ${PACKAGE}-webhook-svc
  labels:
    app: ${PACKAGE}-webhook
  namespace: ${NAMESPACED}
spec:
  selector:
    app: ${PACKAGE}-webhook
  externalTrafficPolicy: Cluster
  ports:
  - port: 443
    targetPort: 8080
    nodePort: 0
    protocol: TCP
  type: NodePort

