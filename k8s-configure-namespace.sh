#!/bin/sh

set -e

PROFILE=""
ACCOUNT=""
REGION=""
CLUSTER=""
NAMESPACE=""

for i in "$@"; do
  case $i in
    --profile=*)
      PROFILE="${i#*=}"
      shift
      ;;
    --account=*)
      ACCOUNT="${i#*=}"
      shift
      ;;
    --region=*)
      REGION="${i#*=}"
      shift
      ;;
    --cluster=*)
      CLUSTER="${i#*=}"
      shift
      ;;
    --namespace=*)
      NAMESPACE="${i#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $PROFILE ]]; then
  echo "Missing required parameter --profile"
  exit 1
fi

if [[ -z $ACCOUNT ]]; then
  echo "Missing required parameter --account"
  exit 1
fi

if [[ -z $REGION ]]; then
  echo "Missing required parameter --region"
  exit 1
fi

if [[ -z $CLUSTER ]]; then
  echo "Missing required parameter --cluster"
  exit 1
fi

if [[ -z $NAMESPACE ]]; then
  echo "Missing required parameter --namespace"
  exit 1
fi

export $(./assume-role.sh --profile=${PROFILE} --account=${ACCOUNT} --role=Terraform-Manage-Clusters)

if [[ -z $AWS_ACCESS_KEY_ID ]]; then
  echo "Missing required access key id"
  exit 1
fi

if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
  echo "Missing required secret access key"
  exit 1
fi

if [[ -z $AWS_SESSION_TOKEN ]]; then
  echo "Missing required session token"
  exit 1
fi

mkdir -p resources

aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER}

cat <<EOF >resources/${NAMESPACE}-namespace.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: ${NAMESPACE}
EOF

kubectl apply -f resources/${NAMESPACE}-namespace.yaml

cat <<EOF >resources/${NAMESPACE}-role.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: k8s-${NAMESPACE}-developer
  namespace: ${NAMESPACE}
rules:
  - apiGroups:
      - ""
      - "apps"
      - "batch"
      - "extensions"
    resources:
      - "configmaps"
      - "cronjobs"
      - "deployments"
      - "events"
      - "ingresses"
      - "jobs"
      - "pods"
      - "pods/attach"
      - "pods/exec"
      - "pods/log"
      - "pods/portforward"
      - "secrets"
      - "services"
    verbs:
      - "create"
      - "delete"
      - "describe"
      - "get"
      - "list"
      - "patch"
      - "update"
EOF

kubectl apply -f resources/${NAMESPACE}-role.yaml

cat <<EOF >resources/${NAMESPACE}-rolebinding.yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: k8s-${NAMESPACE}-developer
  namespace: ${NAMESPACE}
subjects:
- kind: User
  name: k8s-${NAMESPACE}-developer
roleRef:
  kind: Role
  name: k8s-${NAMESPACE}-developer
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f resources/${NAMESPACE}-rolebinding.yaml
