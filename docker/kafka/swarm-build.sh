
#!/bin/sh

eval $(docker-machine env docker-master)
sh docker-build.sh

eval $(docker-machine env docker-worker1)
sh docker-build.sh

eval $(docker-machine env docker-worker2)
sh docker-build.sh

eval $(docker-machine env docker-worker3)
sh docker-build.sh
