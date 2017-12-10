#!/bin/sh

docker run --rm -t -v $(pwd):/terraform -v $1/.aws:/root/.aws -e ROOT=/terraform terraform bash -c "./scripts/create_all.sh"
