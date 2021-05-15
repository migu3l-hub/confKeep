#!/usr/bin/bash

function keepalived_is_active(){
  KEP=""
  CONT=0
  until [ "$KEP" != "" ] || [ $CONT -eq 10 ]; do
      KEP=$(docker ps -qf name=keepalived)
      echo "En espera de keepalived.."
      let $CONT=$CONT+1
      sleep 5
  done
  if [ $CONT -lt 10 ]; then
      echo "keepalived esta activo, eliminando..."
	    docker rm keepalived --force
  fi
}


function obtener_ips(){
  ip_tierra=""
  ip_mercurio=""
  until [ "$ip_tierra" != "" ] && [ "$ip_mercurio" != "" ]; do
      ip_tierra=$(ssh root@192.168.88.4 ifconfig enp0s8 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -n 1)
	    ip_mercurio=$(ifconfig enp0s8 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -n 1)
	    echo "tierra: $ip_tierra, mercurio: $ip_mercurio"
  done
	despliegue_keepalived $ip_tierra $ip_mercurio
}

function despliegue_keepalived(){
	docker run -d --name keepalived --restart=always \
  		--cap-add=NET_ADMIN --cap-add=NET_BROADCAST --cap-add=NET_RAW --net=host \
  		-e KEEPALIVED_INTERFACE=enp0s20u1 \
  		-e KEEPALIVED_UNICAST_PEERS="#PYTHON2BASH:[$1,$2]" \
  		-e KEEPALIVED_VIRTUAL_IPS=148.226.80.34 \
  		-e KEEPALIVED_PRIORITY=200 \
  		osixia/keepalived
	exit;
}


function configurarInterfaces() {
  INTERFACE1=""
  INTERFACE2=0
  CONT=0
  until [ $INTERFACE1 != "" ] && [ $INTERFACE2 -eq 1 ] || [ $CONT -eq 15 ]; do
      dhclient -v enp0s3
      sleep 10
      dhclient -v enp0s8
      INTERFACE1=$(ifconfig enp0s8 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -n 1)
      INTERFACE2=$(ip addr show dev enp0s3 | grep -c 192.168.88.5)
      let $CONT=$CONT+1
      sleep 10
  done
}


function main(){
  sleep 80
  keepalived_is_active
  configurarInterfaces
  obtener_ips
}

sleep 50
main