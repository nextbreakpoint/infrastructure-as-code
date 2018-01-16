#!/bin/sh

echo "Generating OpenVPN client configuration..."

OUTPUT=$ROOT/secrets/openvpn
SOURCE=$ROOT/secrets

if [ ! -z "$1" ]; then

echo "Client name "$1

mkdir -p $OUTPUT

rm $OUTPUT/keystore-openvpn-client-$1.jks $OUTPUT/openvpn_client_cert_and_key_$1.p12

## Create openvpn-client keystore
keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client-$1.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 360 -storepass secret -keypass secret

## Sign openvpn-client certificate
keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client-$1.jks -alias selfsigned -certreq -file $OUTPUT/openvpn_client_csr_$1.pem -storepass secret
openssl x509 -extfile $SOURCE/openssl.cnf -extensions extended -req -CA $SOURCE/openvpn_ca_cert.pem -CAkey $SOURCE/openvpn_ca_key.pem -in $OUTPUT/openvpn_client_csr_$1.pem -out $OUTPUT/openvpn_client_cert_$1.pem -days 360 -CAcreateserial -passin pass:secret

## Import CA and openvpn-client signed certificate into openvpn keystore
keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client-$1.jks -alias CARoot -import -file $SOURCE/openvpn_ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client-$1.jks -alias selfsigned -import -file $OUTPUT/openvpn_client_cert_$1.pem -storepass secret

### Extract signed openvpn-client certificate
keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client-$1.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/openvpn_client_cert_$1.pem

### Extract openvpn-client key
keytool -noprompt -srckeystore $OUTPUT/keystore-openvpn-client-$1.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/openvpn_client_cert_and_key_$1.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT/openvpn_client_cert_and_key_$1.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/openvpn_client_key_$1.pem

cat $SOURCE/openvpn_base.conf > ${OUTPUT}/openvpn_$1.ovpn
echo '<ca>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${SOURCE}/openvpn_ca_cert.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</ca>\n<cert>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${OUTPUT}/openvpn_client_cert_$1.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</cert>\n<key>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${OUTPUT}/openvpn_client_key_$1.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</key>\n<tls-auth>' >> ${OUTPUT}/openvpn_$1.ovpn
cat ${SOURCE}/openvpn_ta.pem >> ${OUTPUT}/openvpn_$1.ovpn
echo '</tls-auth>' >> ${OUTPUT}/openvpn_$1.ovpn

echo "done."

else

  echo "Missing client name. Skipping!"

fi
