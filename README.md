# vitess-consul-poc

This repo has resources to create a proof of concept showing that when Consul leader node is unreachable, Vitess pauses serving to clients

Resources are intended to be used in kubernetes, tests are done using minikube:

After cloning this repo, create a minikube cluster and a namespace:

```bash
minikube start
kubectl create ns vitess
```

Deployment:

- Apply `consul.yaml` file, it will create a consul client pod and 3 server nodes in cluster. Once it is ready you can get URL for consul UI from minikube
```
kubectl apply -f consul.yaml
minikube service consul-ui -n vitess

|-----------|-----------|-------------|---------------------------|
🏃  Starting tunnel for service consul-ui.
|-----------|-----------|-------------|------------------------|
| NAMESPACE |   NAME    | TARGET PORT |          URL           |
|-----------|-----------|-------------|------------------------|
| vitess     | consul-ui |             | http://127.0.0.1:59911 |
|-----------|-----------|-------------|------------------------|
```

- Apply `vtctld.yaml` file to deploy vtctld pod. It has a nginx sidecar to proxy consul requests (localhost:8500) to consul client:

```bash
kubectl apply -f vtctld.yaml
```

- Exec into vtctld container and run following commands:

```
kubectl exec --namespace vitess --stdin --tty $VTCTLD_POD_NAME -- /bin/sh
/vt/bin/vtctlclient -server localhost:15999 AddCellInfo -server_address localhost:8500 -root vitess/us_east_1 us_east_1
```

- Apply `mysql.yaml` file to create vttablet and mysql services (it takes 20-30 seconds for mysql to be up and running, so vttablet container might get restarted 1-2 times until then):

```bash
kubectl apply -f mysql.yaml
```

- Apply `vtgate.yaml` to create vtgate service:

```bash
kubectl apply -f vtgate.yaml
```

- Exec into vtctld container to init shard master:

```bash
kubectl exec --namespace vitess --stdin --tty $VTCTLD_POD_NAME -- /bin/sh
/vt/bin/vtctlclient -server localhost:15999 InitShardMaster -force vitess-test/0 us_east_1-1126369102
```

At this step after making sure every pod is up and running we port-forward `:3306` from vtgate pod to our local and test connection:

```bash
kubectl port-forward pod/$VTGATE_POD_NAME 3306:3306 -n vitess
Forwarding from 127.0.0.1:3306 -> 3306
Forwarding from [::1]:3306 -> 3306
```

```bash
➜  ~ mysql -h127.0.0.1 -uroot -ppassw0rd
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.29-32 Percona Server (GPL), Release 32, Revision 56bce88

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

Now the setup is complete , you should set replica count of consul-server statefullset to 0 , while test below is running

```bash
bash test.sh
```