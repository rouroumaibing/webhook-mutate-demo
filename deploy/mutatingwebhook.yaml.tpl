apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: ${PACKAGE}-webhook.slok.dev
  labels:
    app: ${PACKAGE}-webhook.slok.dev
webhooks:
  - name: ${PACKAGE}-webhook.slok.dev
    admissionReviewVersions: [ "v1" ]
    sideEffects: None
    timeoutSeconds: 5
    #If there is a problem with admission that does not affect the creation of a business pod, reject the request if the value is failed.
    failurePolicy: Ignore
    clientConfig:
      service:
        name: ${PACKAGE}-webhook-svc
        namespace: ${NAMESPACED}
        path: "/mutate"
      # nodeport/loadbalance service IP address, The certificate must contain the IP address.
      # ex. https://ip:port/mutate
      # url: https://${SERVICE_ADDR}/mutate
      caBundle: ${CA_BUNDLE}
    rules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: [ "CREATE" ]
        resources: ["pods"]
        # "Namespaced","Cluster", "*"
        scope: "Namespaced"
      # "namespaceSelector","objectSelector"
    namespaceSelector:
      matchLabels:
        # Labeled namespaces are in effect
        ${PACKAGE}-webhook: enabled