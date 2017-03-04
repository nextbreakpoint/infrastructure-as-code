#!/usr/bin/expect -f
set timeout -1
spawn sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2

expect "\[y\/N\]"
send "y\r"
expect "$ "

