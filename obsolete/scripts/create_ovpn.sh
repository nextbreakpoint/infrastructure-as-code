#!/bin/sh

echo "Generating OpenVPN client configuration..."

ENVIRONMENT=$(cat $ROOT/config/main.json | jq -r ".environment")
COLOUR=$(cat $ROOT/config/main.json | jq -r ".colour")

KEY_PASSWORD=$(cat $ROOT/config/main.json | jq -r ".keystore_password")
KEYSTORE_PASSWORD=$(cat $ROOT/config/main.json | jq -r ".keystore_password")
TRUSTSTORE_PASSWORD=$(cat $ROOT/config/main.json | jq -r ".truststore_password")

OUTPUT=$ROOT/secrets/openvpn/$ENVIRONMENT/$COLOUR
SOURCE=$ROOT/secrets/generated/$ENVIRONMENT/$COLOUR

if [ ! -z "$1" ]; then

echo "Client name $1"

mkdir -p $OUTPUT

rm $SOURCE/keystore-openvpn-client-$1.jks $SOURCE/openvpn_client_cert_and_key_$1.p12

## Create openvpn-client keystore
keytool -noprompt -keystore $SOURCE/keystore-openvpn-client-$1.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 360 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

## Sign openvpn-client certificate
keytool -noprompt -keystore $SOURCE/keystore-openvpn-client-$1.jks -alias selfsigned -certreq -file $SOURCE/openvpn_client_csr_$1.pem -storepass $KEYSTORE_PASSWORD
openssl x509 -extfile $SOURCE/openssl.cnf -extensions extended -req -CA $SOURCE/openvpn_ca_cert.pem -CAkey $SOURCE/openvpn_ca_key.pem -in $SOURCE/openvpn_client_csr_$1.pem -out $SOURCE/openvpn_client_cert_$1.pem -days 360 -CAcreateserial -passin pass:$KEY_PASSWORD

## Import CA and openvpn-client signed certificate into openvpn keystore
keytool -noprompt -keystore $SOURCE/keystore-openvpn-client-$1.jks -alias CARoot -import -file $SOURCE/openvpn_ca_cert.pem -storepass $KEYSTORE_PASSWORD
keytool -noprompt -keystore $SOURCE/keystore-openvpn-client-$1.jks -alias selfsigned -import -file $SOURCE/openvpn_client_cert_$1.pem -storepass $KEYSTORE_PASSWORD

### Extract signed openvpn-client certificate
keytool -noprompt -keystore $SOURCE/keystore-openvpn-client-$1.jks -exportcert -alias selfsigned -rfc -storepass $KEYSTORE_PASSWORD -file $SOURCE/openvpn_client_cert_$1.pem

### Extract openvpn-client key
keytool -noprompt -srckeystore $SOURCE/keystore-openvpn-client-$1.jks -importkeystore -srcalias selfsigned -destkeystore $SOURCE/openvpn_client_cert_and_key_$1.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD
openssl pkcs12 -in $SOURCE/openvpn_client_cert_and_key_$1.p12 -nocerts -nodes -passin pass:$KEY_PASSWORD -out $SOURCE/openvpn_client_key_$1.pem

cat $SOURCE/openvpn_base.conf > ${OUTPUT}/openvpn_$1.ovpn
echo '' >> ${OUTPUT}/openvpn_$1.ovpn
echo '<ca>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${SOURCE}/openvpn_ca_cert.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</ca>\n<cert>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${SOURCE}/openvpn_client_cert_$1.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</cert>\n<key>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${SOURCE}/openvpn_client_key_$1.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</key>\n<tls-auth>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${SOURCE}/openvpn_ta.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</tls-auth>' >> ${OUTPUT}/openvpn_$1.ovpn

echo "done."

else

  echo "Missing client name. Skipping!"

fi
