.DEFAULT_GOAL := up

.PHONY: up
up:
	sudo containerlab deploy

.PHONY: down
down:
	sudo containerlab destroy --cleanup

.PHONY: restart
restart: down up

.PHONY: inspect
inspect:
	sudo containerlab inspect

.PHONY: pingtest
pingtest:
	set -o xtrace
	docker exec sonic-poc-leaf01 ping -c3 10.0.0.12 || docker exec sonic-poc-leaf01 ip r
	docker exec sonic-poc-leaf02 ping -c3 10.0.0.11 || docker exec sonic-poc-leaf02 ip r
	docker exec sonic-poc-server01 ping -c3 10.0.0.2 || docker exec sonic-poc-server01 ip r
	docker exec sonic-poc-server02 ping -c3 10.0.0.1 || docker exec sonic-poc-server02 ip r
