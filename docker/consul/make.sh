docker build -t configure-consul .
docker run -t -v $(pwd)/output:/output configure-consul 
docker run -t -v $(pwd)/output:/output configure-consul openssl x509 -noout -text -in /output/consul_server.pem
