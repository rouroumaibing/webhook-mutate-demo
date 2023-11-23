#!/bin/bash 

WORKPATH=`pwd`
CERTPATH=${WORKPATH}/certs
TMPPATH=${WORKPATH}/certs/tmp

mkdir -p ${TMPPATH}

set -ex

usage() {
    cat <<EOF

usage: ${0} [OPTIONS]

The following flags are required.

       --service          Service name of webhook.
       --namespace        Namespace where webhook service and secret reside.
       --secret           Secret name for CA certificate and server certificate/key pair.
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case ${1} in
        --service)
            service="$2"
            shift
            ;;
        --secret)
            secret="$2"
            shift
            ;;
        --namespace)
            namespace="$2"
            shift
            ;;
        *)
            usage
            ;;
    esac
    shift
done

[ -z ${service} ] && echo "ERROR: --service flag is required" && exit 1
[ -z ${secret} ] && echo "ERROR: --secret flag is required" && exit 1
[ -z ${namespace} ] && namespace=default

if [ ! -x "$(command -v openssl)" ]; then
    echo "openssl not found"
    exit 1
fi

# [alt_names][IP.1] IP address to access the webhook service
cat <<EOF >> ${TMPPATH}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
O = dev/serving
CN = ${service}.${namespace}.svc

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${service}
DNS.2 = ${service}.${namespace}
DNS.3 = ${service}.${namespace}.svc
IP.1 = 192.168.0.1
EOF


# 1. Create CA key and CA cert
openssl genrsa -out ${CERTPATH}/ca.key 2048
openssl req -x509 -new -nodes -key ${CERTPATH}/ca.key -subj "/CN=${service}.${namespace}.svc" -days 10000 -out ${CERTPATH}/ca.crt 


# 2. Create server key, server csr, sign the server csr, and save the signed server cert
openssl genrsa -out ${CERTPATH}/${service}.key 2048 
openssl req -new -key ${CERTPATH}/${service}.key -subj "/CN=${service}.${namespace}.svc" -out ${TMPPATH}/${service}.csr -config ${TMPPATH}/csr.conf
openssl x509 -req -CA ${CERTPATH}/ca.crt -CAkey ${CERTPATH}/ca.key -CAcreateserial -in ${TMPPATH}/${service}.csr  -days 10000  -out ${CERTPATH}/${service}.crt  -extfile ${TMPPATH}/csr.conf -extensions v3_req 

# 3. create a secret with signed server cert and server key
kubectl delete secret ${secret} -n ${namespace} 2>/dev/null || true
kubectl create secret generic ${secret} \
        --from-file=tls.key=${CERTPATH}/${service}.key \
        --from-file=tls.crt=${CERTPATH}/${service}.crt \
        --dry-run=client -o yaml |
    kubectl -n ${namespace} apply -f -

