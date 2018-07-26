#!/bin/sh

docker run --rm -it -v $(pwd):/workdir -v $HOME/.aws:/root/.aws -e ROOT=/workdir terraform bash -c "sh scripts/"$1".sh "$2" "$3" "$4
