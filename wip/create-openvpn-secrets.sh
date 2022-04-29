#!/bin/sh

HOSTED_ZONE_NAME=""
ENVIRONMENT=""
COLOUR=""

KEY_PASSWORD=""
KEYSTORE_PASSWORD=""
TRUSTSTORE_PASSWORD=""

POSITIONAL_ARGS=()

for i in "$@"; do
  case $i in
    --environment=*)
      ENVIRONMENT="${i#*=}"
      shift
      ;;
    --colour=*)
      COLOUR="${i#*=}"
      shift
      ;;
    --hosted-zone-name=*)
      HOSTED_ZONE_NAME="${i#*=}"
      shift
      ;;
    --key-password=*)
      KEY_PASSWORD="${i#*=}"
      shift
      ;;
    --keystore-password=*)
      KEYSTORE_PASSWORD="${i#*=}"
      shift
      ;;
    --truststore-password=*)
      TRUSTSTORE_PASSWORD="${i#*=}"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $ENVIRONMENT ]]; then
  echo "Missing required parameter --environment"
  exit 1
fi

if [[ -z $COLOUR ]]; then
  echo "Missing required parameter --colour"
  exit 1
fi

if [[ -z $HOSTED_ZONE_NAME ]]; then
  echo "Missing required parameter --hosted-zone-name"
  exit 1
fi

if [[ -z $KEY_PASSWORD ]]; then
  echo "Missing required parameter --key-password"
  exit 1
fi

if [[ -z $KEYSTORE_PASSWORD ]]; then
  echo "Missing required parameter --keystore-password"
  exit 1
fi

if [[ -z $TRUSTSTORE_PASSWORD ]]; then
  echo "Missing required parameter --truststore-password"
  exit 1
fi

OUTPUT_GEN=secrets/generated/$ENVIRONMENT/$COLOUR
OUTPUT_ENV=secrets/environments/$ENVIRONMENT/$COLOUR

echo "Generating secrets for environment ${ENVIRONMENT} of colour ${COLOUR} into directory ${OUTPUT_ENV}"

if [ ! -d "$OUTPUT_GEN" ]; then

mkdir -p $OUTPUT_GEN

# echo '[extended]\nextendedKeyUsage=serverAuth,clientAuth\nkeyUsage=digitalSignature,keyAgreement' > $OUTPUT_GEN/openssl.cnf

## Create openvpn certificate authority (CA)
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_ca.jks -genkeypair -alias ca -dname "CN=openvpn" -ext KeyUsage=digitalSignature,keyCertSign -ext BasicConstraints=ca:true,PathLen:3 -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEY_PASSWORD -keypass $KEY_PASSWORD
openssl pkcs12 -in $OUTPUT_GEN/openvpn_ca.jks -nocerts -nodes -passin pass:$KEY_PASSWORD -out $OUTPUT_GEN/openvpn_ca_key.pem
openssl pkcs12 -in $OUTPUT_GEN/openvpn_ca.jks -nokeys -nodes -passin pass:$KEY_PASSWORD -out $OUTPUT_GEN/openvpn_ca_cert.pem
# openssl req -new -x509 -keyout $OUTPUT_GEN/openvpn_ca_key.pem -out $OUTPUT_GEN/openvpn_ca_cert.pem -days 365 -passin pass:$KEY_PASSWORD -passout pass:$KEY_PASSWORD -subj "/CN=openvpn"

## Create openvpn-server keystore
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_server_keystore.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

## Create openvpn-client keystore
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_client_keystore.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

## Sign openvpn-server certificate
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_server_keystore.jks -alias selfsigned -certreq -file $OUTPUT_GEN/openvpn_server_csr.pem -storepass $KEYSTORE_PASSWORD
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_ca.jks -alias ca -gencert -infile $OUTPUT_GEN/openvpn_server_csr.pem -outfile $OUTPUT_GEN/openvpn_server_cert.pem -sigalg SHA256withRSA -ext KeyUsage=digitalSignature,keyAgreement -ext ExtendedKeyUsage=serverAuth,clientAuth -rfc -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD
# openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/openvpn_ca_cert.pem -CAkey $OUTPUT_GEN/openvpn_ca_key.pem -in $OUTPUT_GEN/openvpn_server_csr.pem -out $OUTPUT_GEN/openvpn_server_cert.pem -days 365 -CAcreateserial -passin pass:$KEYSTORE_PASSWORD

## Sign openvpn-client certificate
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_client_keystore.jks -alias selfsigned -certreq -file $OUTPUT_GEN/openvpn_client_csr.pem -storepass $KEYSTORE_PASSWORD
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_ca.jks -alias ca -gencert -infile $OUTPUT_GEN/openvpn_client_csr.pem -outfile $OUTPUT_GEN/openvpn_client_cert.pem -sigalg SHA256withRSA -ext KeyUsage=digitalSignature,keyAgreement -ext ExtendedKeyUsage=serverAuth,clientAuth -rfc -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD
# openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/openvpn_ca_cert.pem -CAkey $OUTPUT_GEN/openvpn_ca_key.pem -in $OUTPUT_GEN/openvpn_client_csr.pem -out $OUTPUT_GEN/openvpn_client_cert.pem -days 365 -CAcreateserial -passin pass:$KEYSTORE_PASSWORD

## Import CA and openvpn-server signed certificate into openvpn keystore
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_server_keystore.jks -alias CARoot -import -file $OUTPUT_GEN/openvpn_ca_cert.pem -storepass $KEYSTORE_PASSWORD
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_server_keystore.jks -alias selfsigned -import -file $OUTPUT_GEN/openvpn_server_cert.pem -storepass $KEYSTORE_PASSWORD

## Import CA and openvpn-client signed certificate into openvpn keystore
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_client_keystore.jks -alias CARoot -import -file $OUTPUT_GEN/openvpn_ca_cert.pem -storepass $KEYSTORE_PASSWORD
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_client_keystore.jks -alias selfsigned -import -file $OUTPUT_GEN/openvpn_client_cert.pem -storepass $KEYSTORE_PASSWORD

### Extract signed openvpn-server certificate
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_server_keystore.jks -exportcert -alias selfsigned -rfc -storepass $KEYSTORE_PASSWORD -file $OUTPUT_GEN/openvpn_server_cert.pem

### Extract openvpn-server key
keytool -noprompt -srckeystore $OUTPUT_GEN/openvpn_server_keystore.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/openvpn_server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD
openssl pkcs12 -in $OUTPUT_GEN/openvpn_server_cert_and_key.p12 -nocerts -nodes -passin pass:$KEYSTORE_PASSWORD -out $OUTPUT_GEN/openvpn_server_key.pem

### Extract signed openvpn-client certificate
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_client_keystore.jks -exportcert -alias selfsigned -rfc -storepass $KEYSTORE_PASSWORD -file $OUTPUT_GEN/openvpn_client_cert.pem

### Extract openvpn-client key
keytool -noprompt -srckeystore $OUTPUT_GEN/openvpn_client_keystore.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/openvpn_client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD
openssl pkcs12 -in $OUTPUT_GEN/openvpn_client_cert_and_key.p12 -nocerts -nodes -passin pass:$KEYSTORE_PASSWORD -out $OUTPUT_GEN/openvpn_client_key.pem

### Extract openvpn CA certificate
keytool -noprompt -keystore $OUTPUT_GEN/openvpn_server_keystore.jks -exportcert -alias CARoot -rfc -storepass $KEYSTORE_PASSWORD -file $OUTPUT_GEN/openvpn_ca_cert.pem

openssl x509 -noout -text -in $OUTPUT_GEN/openvpn_ca_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/openvpn_server_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/openvpn_client_cert.pem

openssl dhparam -out $OUTPUT_GEN/openvpn_dh2048.pem 2048
# openvpn --genkey --secret $OUTPUT_GEN/openvpn_ta.pem

else

echo "Secrets folder already exists. Just copying files..."

fi

### Copy certificates and keys

DST=$OUTPUT_ENV/openvpn

mkdir -p $DST

cp $OUTPUT_GEN/openvpn_ca_cert.pem $DST/ca_cert.pem
cp $OUTPUT_GEN/openvpn_server_cert.pem $DST/server_cert.pem
cp $OUTPUT_GEN/openvpn_server_key.pem $DST/server_key.pem
cp $OUTPUT_GEN/openvpn_client_cert.pem $DST/client_cert.pem
cp $OUTPUT_GEN/openvpn_client_key.pem $DST/client_key.pem
cp $OUTPUT_GEN/openvpn_dh2048.pem $DST/dh2048.pem
# cp $OUTPUT_GEN/openvpn_ta.pem $DST/ta.pem
