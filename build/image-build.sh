#!bin/bash
WORKPATH=`pwd`
PACKAGE=${1:-pod-annotate}
VERSION=${2:-v0.0.1}

cat > ${WORKPATH}/Dockerfile <<EOF
FROM golang:1.21.4 as build-stage

COPY cmd go.mod /workdir/
WORKDIR /workdir

RUN go mod tidy \\
    && GOOS=linux go build -o /${PACKAGE} ${PACKAGE}/main.go
    
CMD ["/${PACKAGE}"]
EOF

docker build --network host . -t ${PACKAGE}-webhook:${VERSION}
