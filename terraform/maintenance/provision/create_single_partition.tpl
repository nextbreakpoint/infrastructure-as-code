sudo parted ${device_name} mklabel gpt
sudo parted --align optimal ${device_name} mkpart primary ext4 0% 100%
sudo parted ${device_name} print
sudo mkfs -t ext4 ${device_name}1
