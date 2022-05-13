.DEFAULT_GOAL := up

.PHONY: up
up:
	sudo containerlab deploy --topo topology.yaml

.PHONY: down
down:
	sudo containerlab destroy --cleanup --topo topology.yaml

.PHONY: restart
restart: down up

