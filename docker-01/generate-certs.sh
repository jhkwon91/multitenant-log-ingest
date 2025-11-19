#!/bin/bash
set -e

mkdir -p certs
cd certs

echo "📌 Generate Root CA"
openssl genrsa -out root-ca.key 4096
openssl req -x509 -new -nodes -key root-ca.key -sha256 -days 3650 \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=Example/CN=root-ca" \
  -out root-ca.pem

echo "📌 Generate Node Certificate"
openssl genrsa -out node.key 4096
openssl req -new -key node.key \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=Example/CN=opensearch-node" \
  -out node.csr

openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca.key \
  -CAcreateserial -out node.pem -days 1000 -sha256

echo "📌 Generate Admin Certificate"
openssl genrsa -out admin.key 4096
openssl req -new -key admin.key \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=Example/CN=admin" \
  -out admin.csr

openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca.key \
  -CAcreateserial -out admin.pem -days 1000 -sha256

chmod 644 *.pem
chmod 600 *.key

echo "🎉 Done! certs generated under ./certs"

