#!/bin/sh -e

ROOT=${ROOT:-/ssl}
SERVERNAME=${SERVERNAME:-$(uname -n)}
CERT_TYPE=${CERT_TYPE:-rsa:4096}

gen_ssl_config() {
    destfile=$1
    cat <<EOF >"$destfile"
[ req ]
distinguished_name = req_dn
x509_extensions = server_cert
[ req_dn ]
[ server_cert ]
basicConstraints=CA:FALSE
nsCertType = server
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
subjectAltName=DNS:$SERVERNAME
EOF
}

gen_ec_param() {
    out_file=$1
    openssl genpkey -genparam -algorithm ec -pkeyopt ec_paramgen_curve:P-256 -out "$out_file"
}

# generate certs if /ssl/${SERVERNAME}.crt and /ssl/${SERVERNAME}.key do not exist
if [ ! -d "$ROOT" ]; then
    mkdir "$ROOT" || exit 1
fi

config=$(mktemp)
nukefiles="$config"

trap 'rm -f $nukefiles' EXIT HUP
gen_ssl_config "$config"

if [ ! -f "$ROOT/$SERVERNAME.crt" ] || [ ! -f "$ROOT/$SERVERNAME.key" ]; then
    if [ "$CERT_TYPE" = ec ]; then
        ecpk=$(mktemp)
        nukefiles="$nukefiles $ecpk"
        gen_ec_param "$ecpk"
        CERT_TYPE=$CERT_TYPE:$ecpk
    fi
    openssl req -newkey "$CERT_TYPE" -x509 -sha256 -days 389 -nodes \
        -out "$ROOT/$SERVERNAME.crt" -keyout "$ROOT/$SERVERNAME.key" \
        -subj "/C=IE/L=Dublin/O=Me/OU=Developer/CN=$SERVERNAME" \
        -config "$config"
fi

