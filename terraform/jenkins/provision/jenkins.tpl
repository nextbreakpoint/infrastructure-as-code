#!/bin/bash
set -e

sudo service jenkins stop

sudo mkdir -p ${pipeline_data_dir}/jenkins

sudo mount ${volume_name}1 ${pipeline_data_dir}
echo "${volume_name}1 ${pipeline_data_dir} ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab >/dev/null

sudo rm -fR /var/lib/jenkins

sudo ln -s ${pipeline_data_dir}/jenkins /var/lib/jenkins

sudo chown -R jenkins:jenkins /var/lib/jenkins/

sudo -u jenkins docker run hello-world

sudo service jenkins start

sudo curl -L -o sonarqube.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.zip

sudo unzip -d /opt sonarqube.zip 

sudo cat <<EOF >/tmp/nginx.conf
user www-data www-data;

worker_processes 5;
worker_rlimit_nofile 8192;

events {
  worker_connections 4096;
}

http {
  server {
    listen *:80;

    server_name jenkins.dev.nextbreakpoint.com;

    location / {
        proxy_pass http://${jenkins_host}:8080;
    }
  }
  server {
    listen *:80;

    server_name sonarqube.dev.nextbreakpoint.com;

    location / {
        proxy_pass http://${sonarqube_host}:9000;
    }
  }
}
EOF
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf

sudo service nginx restart

echo "Done"
