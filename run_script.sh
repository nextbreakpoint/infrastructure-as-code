#!/bin/sh

docker run --rm -t -v $(pwd):/terraform -v $1/.aws:/root/.aws -e ROOT=/terraform terraform bash -c "./scripts/"$2".sh "$3" "$4" "$5
