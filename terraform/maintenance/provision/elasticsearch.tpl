sudo parted ${elasticsearch_device_name} mklabel gpt
sudo parted --align optimal ${elasticsearch_device_name} mkpart primary ext4 0% 100%
sudo parted ${elasticsearch_device_name} print
sudo mkfs -t ext4 ${elasticsearch_device_name}1
