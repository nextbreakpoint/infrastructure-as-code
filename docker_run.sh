#!/bin/sh

docker run --rm -it -v $(pwd):/infrastructure -v $HOME/.aws:/root/.aws -e ROOT=/infrastructure terraform bash -c "sh scripts/"$1".sh "$2" "$3" "$4
