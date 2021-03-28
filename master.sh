#!/usr/bin/env bash

function quitar_keepalived(){
	docker rm keepalived --force
}

function obtener_ips(){
	ip_tierra=$(ssh root@192.168.88.55 ifconfig eno1 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -n 1)
	ip_mercurio=$(ifconfig eno1 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -n 1)
	echo "tierra: $ip_tierra, mercurio: $ip_mercurio"
	exit;
	#despliegue_keepalived $ip_tierra $ip_mercurio
}

function despligue_keepalived(){
	docker run -d --name keepalived --restart=always \
  		--cap-add=NET_ADMIN --cap-add=NET_BROADCAST --cap-add=NET_RAW --net=host \
  		-e KEEPALIVED_INTERFACE=enp0s20u1 \
  		-e KEEPALIVED_UNICAST_PEERS="#PYTHON2BASH:[$1,$2]" \
  		-e KEEPALIVED_VIRTUAL_IPS=148.226.80.34 \
  		-e KEEPALIVED_PRIORITY=200 \
  		osixia/keepalived
	exit;
}

function comprobar(){
	while $True; do
		ping -c 1 192.168.88.55 >/dev/null && obtener_ips
		sleep 10
	done
}

function main(){
  sleep 70
	#quitar_keepalived
	comprobar
}

sleep 50
dhclient enp0s8

main