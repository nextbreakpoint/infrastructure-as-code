#!/bin/sh

. $ROOT/bash_aliases

MODULE=$1

if [ -z "$MODULE" ]; then
    exit 1
fi

ENVIRONMENT=$(cat $ROOT/config/main.json | jq -r ".environment")
COLOUR=$(cat $ROOT/config/main.json | jq -r ".colour")

cd $ROOT/terraform/$MODULE && tf_init

if [ $? -ne 0 ]; then
    exit 1
fi

cd $ROOT/terraform/$MODULE && terraform workspace select ${ENVIRONMENT}-${COLOUR}

if [ $? -ne 0 ]; then

cd $ROOT/terraform/$MODULE && terraform workspace new ${ENVIRONMENT}-${COLOUR}

if [ $? -ne 0 ]; then
    exit 1
fi

fi

cd $ROOT/terraform/$MODULE && tf_plan $2 $3 $4 $5 $6 $7 $8 $9

if [ $? -ne 0 ]; then
    exit 1
fi

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/$MODULE && tf_apply

  if [ $? -ne 0 ]; then
      exit 1
  fi
fi

cd $ROOT/terraform/$MODULE && terraform output -json
