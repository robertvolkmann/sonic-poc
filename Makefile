.DEFAULT_GOAL := up

.PHONY: up
up:
	sudo containerlab deploy --topo topology.yaml

.PHONY: down
down:
	sudo containerlab destroy --cleanup --topo topology.yaml

.PHONY: restart
restart: down up

.PHONY: inspect
inspect:
	sudo containerlab inspect --topo topology.yaml

.PHONY: pingtest
pingtest:
	set -o xtrace
	docker exec leaf01 ping -c3 10.0.0.12 || docker exec leaf01 ip r
	docker exec leaf02 ping -c3 10.0.0.11 || docker exec leaf02 ip r
	docker exec server01 ping -c3 10.0.0.2 || docker exec server01 ip r
	docker exec server02 ping -c3 10.0.0.1 || docker exec server02 ip r
