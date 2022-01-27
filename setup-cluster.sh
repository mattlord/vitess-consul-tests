#!/bin/bash
set -euo pipefail

minikube delete
minikube start

kubectl create ns vitess

kubectl apply -f consul.yaml

sleep 10

minikube service consul-ui -n vitess

sleep 10

kubectl apply -f vtctld.yaml

sleep 100

VTCTLD_POD=$(kubectl -n vitess get pods | awk '$1 ~ "vtctld.*" {print $1; exit}')

sleep 30

kubectl apply -f mysql.yaml
kubectl apply -f mysql2.yaml
kubectl apply -f mysql3.yaml

sleep 10

kubectl -n vitess exec -it ${VTCTLD_POD} -c vtctld -- /vt/bin/vtctlclient -server localhost:15999 AddCellInfo -server_address localhost:8500 -root vitess/us_east_1 us_east_1

sleep 10

kubectl apply -f vtgate.yaml

sleep 25

kubectl -n vitess exec -it ${VTCTLD_POD} -c vtctld -- /vt/bin/vtctlclient -server localhost:15999 InitShardPrimary -force vitess-test/0 us_east_1-1126369102

VTGATE_POD=$(minikube kubectl -- -n vitess get pods | awk '$1 ~ "vtgate.*" {print $1; exit}')

kubectl port-forward pod/${VTGATE_POD} 33306:3306 -n vitess > /dev/null

exit 0
