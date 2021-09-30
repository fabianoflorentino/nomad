#!/bin/bash

# 1. Generate CA private key
openssl genrsa -out ca.key 4096

# 3. Generate server certificate(Change the values accordingly)
openssl genrsa -out consul-registry.com.key 4096

# 2. Generate CA certificate (Change the values accordingly)
openssl req -x509 -new -nodes -sha512 -days 3650 \
    -subj "/C=CN/ST=Colombo/L=Colombo/O=Organization/OU=Personal/CN=consul-registry.com" \
    -key ca.key \
    -out ca.crt

# 4. Generate certificate signing request(Change the values accordingly)
openssl req -sha512 -new \
    -subj "/C=CN/ST=Colombo/L=Colombo/O=Organization/OU=Personal/CN=consul-registry.com" \
    -key consul-registry.com.key \
    -out consul-registry.com.csr

# 5. Generate an x509 v3 extension file.(Change the values accordingly)
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=consul-registry.com
DNS.2=consul-registry
DNS.3=host-name
EOF

# 6. Use above file to generate certificate.(Change the values accordingly)
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in consul-registry.com.csr \
    -out consul-registry.com.crt

# 7. Provide the certificates for consul.
cp consul-registry.com.crt /data/cert/
cp consul-registry.com.key /data/cert/

# 8. For docker to use this cert we need to convert .crt to .cert. Then we need to move them to the appropriate folder.
openssl x509 -inform PEM -in consul-registry.com.crt -out consul-registry.com.cert
cp consul-registry.com.cert /etc/docker/certs.d/consul-registry.com/
cp consul-registry.com.key /etc/docker/certs.d/consul-registry.com/
cp ca.crt /etc/docker/certs.d/yourdomain.com/

# 9. Restart docker
systemctl restart docker