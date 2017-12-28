#!/bin/sh

docker run --rm -it -v $(pwd):/terraform -v $HOME/.aws:/root/.aws -e ROOT=/terraform terraform bash -c "./scripts/"$1".sh "$2" "$3" "$4
