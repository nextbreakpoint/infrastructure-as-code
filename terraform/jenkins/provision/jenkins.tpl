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

echo "Done"
