#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo modprobe ip_vs
  - sudo usermod -aG docker ubuntu
  - sudo sysctl net.bridge.bridge-nf-call-iptables=1
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /consul/config
  - sudo chmod -R ubuntu.ubuntu /nginx
  - sudo chmod -R ubuntu.ubuntu /consul
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=kubernetes-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter}
  - sudo mkdir -p /etc/cni/net.d/
  - sudo wget -O /etc/cni/net.d/10-kuberouter.conf https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/cni/10-kuberouter.conf
  - sudo kubeadm init --token ${kubernetes_token} --pod-network-cidr="${pod_network_cidr}" --apiserver-advertise-address=HOST_IP_ADDRESS --skip-preflight-checks
  - sudo -u ubuntu mkdir -p /home/ubuntu/.kube
  - sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  - sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
  - bash -c "sleep 30"
  - echo "source <(kubectl completion bash)" >> ~/.bashrc
  - sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
  - sudo -u ubuntu kubectl apply -f /tmp/kubernetes-dashboard.yaml
  - sudo -u ubuntu kubectl create clusterrolebinding dashboard-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
  - sudo -u ubuntu kubectl get pods --all-namespaces
  - sudo -u ubuntu kubectl get secrets -n kube-system kubernetes-dashboard-token-5x65d -o 'jsonpath={.data.token}'
write_files:
  - path: /consul/config/consul.json
    permissions: '0644'
    content: |
        {
          "enable_script_checks": true,
          "leave_on_terminate": true,
          "dns_config": {
            "allow_stale": true,
            "max_stale": "1s",
            "service_ttl": {
              "*": "5s"
            }
          }
        }
  - path: /etc/docker/daemon.json
    permissions: '0644'
    content: |
        {
          "log-driver": "syslog",
          "log-opts": {
            "tag": "docker"
          }
        }
  - path: /tmp/kubernetes-dashboard.yaml
    permissions: '0644'
    content: |
        # Copyright 2017 The Kubernetes Authors.
        #
        # Licensed under the Apache License, Version 2.0 (the "License");
        # you may not use this file except in compliance with the License.
        # You may obtain a copy of the License at
        #
        #     http://www.apache.org/licenses/LICENSE-2.0
        #
        # Unless required by applicable law or agreed to in writing, software
        # distributed under the License is distributed on an "AS IS" BASIS,
        # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        # See the License for the specific language governing permissions and
        # limitations under the License.

        # Configuration to deploy head version of the Dashboard UI compatible with
        # Kubernetes 1.7.
        #
        # Example usage: kubectl create -f <this_file>

        # ------------------- Dashboard Secret ------------------- #

        #apiVersion: v1
        #kind: Secret
        #metadata:
        #  labels:
        #    k8s-app: kubernetes-dashboard
        #  name: kubernetes-dashboard-certs
        #  namespace: kube-system
        #type: Opaque

        ---
        # ------------------- Dashboard Service Account ------------------- #

        apiVersion: v1
        kind: ServiceAccount
        metadata:
          labels:
            k8s-app: kubernetes-dashboard
          name: kubernetes-dashboard
          namespace: kube-system

        ---
        # ------------------- Dashboard Role & Role Binding ------------------- #

        kind: Role
        apiVersion: rbac.authorization.k8s.io/v1beta1
        metadata:
          name: kubernetes-dashboard-minimal
          namespace: kube-system
        rules:
          # Allow Dashboard to create and watch for changes of 'kubernetes-dashboard-key-holder' secret.
        - apiGroups: [""]
          resources: ["secrets"]
          verbs: ["create", "watch"]
        - apiGroups: [""]
          resources: ["secrets"]
          # Allow Dashboard to get, update and delete 'kubernetes-dashboard-key-holder' and 'kubernetes-dashboard-certs' secrets.
          #resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
          resourceNames: ["kubernetes-dashboard-key-holder"]
          verbs: ["get", "update", "delete"]
          # Allow Dashboard to get metrics from heapster.
        - apiGroups: [""]
          resources: ["services"]
          resourceNames: ["heapster"]
          verbs: ["proxy"]
        ---
        apiVersion: rbac.authorization.k8s.io/v1beta1
        kind: RoleBinding
        metadata:
          name: kubernetes-dashboard-minimal
          namespace: kube-system
        roleRef:
          apiGroup: rbac.authorization.k8s.io
          kind: Role
          name: kubernetes-dashboard-minimal
        subjects:
        - kind: ServiceAccount
          name: kubernetes-dashboard
          namespace: kube-system

        ---
        # ------------------- Dashboard Deployment ------------------- #

        kind: Deployment
        apiVersion: extensions/v1beta1
        metadata:
          labels:
            k8s-app: kubernetes-dashboard
          name: kubernetes-dashboard
          namespace: kube-system
        spec:
          replicas: 1
          revisionHistoryLimit: 10
          selector:
            matchLabels:
              k8s-app: kubernetes-dashboard
          template:
            metadata:
              labels:
                k8s-app: kubernetes-dashboard
            spec:
              #initContainers:
              #- name: kubernetes-dashboard-init
              #  image: kubernetesdashboarddev/kubernetes-dashboard-init-amd64:v1.0.1
              #  volumeMounts:
              #  - name: kubernetes-dashboard-certs
              #    mountPath: /certs
              containers:
              - name: kubernetes-dashboard
                image: kubernetesdashboarddev/kubernetes-dashboard-amd64:head
                # Image is tagged and updated with :head, so always pull it.
                imagePullPolicy: Always
                ports:
                - containerPort: 9090
                  protocol: TCP
                args:
                  #- --tls-key-file=/certs/dashboard.key
                  #- --tls-cert-file=/certs/dashboard.crt
                  # Uncomment the following line to manually specify Kubernetes API server Host
                  # If not specified, Dashboard will attempt to auto discover the API server and connect
                  # to it. Uncomment only if the default does not work.
                  #- --apiserver-host=https://kubernetes.internal:6443
                volumeMounts:
                #- name: kubernetes-dashboard-certs
                #  mountPath: /certs
                #  readOnly: true
                # Create on-disk volume to store exec logs
                - mountPath: /tmp
                  name: tmp-volume
                livenessProbe:
                  httpGet:
                    scheme: HTTP
                    path: /
                    port: 9090
                  initialDelaySeconds: 30
                  timeoutSeconds: 30
              volumes:
              #- name: kubernetes-dashboard-certs
              #  secret:
              #    secretName: kubernetes-dashboard-certs
              - name: tmp-volume
                emptyDir: {}
              serviceAccountName: kubernetes-dashboard
              # Comment the following tolerations if Dashboard must not be deployed on master
              tolerations:
              - key: node-role.kubernetes.io/master
                effect: NoSchedule
              nodeSelector:
               node-role.kubernetes.io/master: ""

        ---
        # ------------------- Dashboard Service ------------------- #

        kind: Service
        apiVersion: v1
        metadata:
          labels:
            k8s-app: kubernetes-dashboard
          name: kubernetes-dashboard
          namespace: kube-system
        spec:
          ports:
          - port: 80
            targetPort: 9090
          selector:
            k8s-app: kubernetes-dashboard
