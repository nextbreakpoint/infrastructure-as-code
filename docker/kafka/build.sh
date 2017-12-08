docker build -t nextbreakpoint/kafka .
docker tag nextbreakpoint/kafka nextbreakpoint/kafka:0.11.0.0
docker push nextbreakpoint/kafka:0.11.0.0
