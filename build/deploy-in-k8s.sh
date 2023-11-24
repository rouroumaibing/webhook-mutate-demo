#!/bin/bash
WORKPATH=`pwd`
PACKAGE=${1:-pod-annotate}
VERSION=${2:-v0.0.1}
NAMESPACED=${3:-default}
SERVICE=${PACKAGE}-webhook-svc
SECRET=${PACKAGE}-webhook-certs
REGISTRY=${4:-REGISTRY}
SERVICE_ADDR=${5:-192.168.0.1}

#update template
cp -rf deploy/mutatingwebhook.yaml.tpl deploy/mutatingwebhook.yaml
cp -rf deploy/webhookserver.yaml.tpl deploy/webhookserver.yaml

sed -i "s|\${PACKAGE}|${PACKAGE}|g" deploy/mutatingwebhook.yaml
sed -i "s|\${SERVICE_ADDR}|${SERVICE_ADDR}|g" deploy/mutatingwebhook.yaml
sed -i "s/namespace:.*/namespace: ${NAMESPACED}/g" deploy/mutatingwebhook.yaml

sed -i "s|\${PACKAGE}|${PACKAGE}|g" deploy/webhookserver.yaml
sed -i "s/namespace:.*/namespace: ${NAMESPACED}/g" deploy/webhookserver.yaml
sed -i "s|\${VERSION}|${VERSION}|g" deploy/webhookserver.yaml
sed -i "s|\${REGISTRY}|${REGISTRY}|g" deploy/webhookserver.yaml

#create secret
bash build/webhook-create-self-signed-ca-cert.sh --service ${SERVICE} --secret ${SECRET} --namespace ${NAMESPACED} --ip ${SERVICE_ADDR}

export CA_BUNDLE=$(cat certs/ca.crt | base64 -w0)
sed -i "s|\${CA_BUNDLE}|${CA_BUNDLE}|g" deploy/mutatingwebhook.yaml
#deploy webhook


kubectl apply -f deploy/mutatingwebhook.yaml 2>/dev/null || true
kubectl apply -f deploy/webhookserver.yaml 2>/dev/null || true
