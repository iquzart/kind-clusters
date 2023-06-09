# Go Web application

[![Build Status](https://dev.azure.com/iquzart/iquzart/_apis/build/status/Go%20App?branchName=master)](https://dev.azure.com/iquzart/iquzart/_build/latest?definitionId=7&branchName=master) [![Go Report Card](https://goreportcard.com/badge/github.com/iquzart/go-app)](https://goreportcard.com/report/github.com/iquzart/go-app)
![Docker Pulls](https://img.shields.io/docker/pulls/diquzart/go-app) ![GitHub](https://img.shields.io/github/license/iquzart/go-app) ![Metrics Support](https://img.shields.io/badge/Metrics%20Support-Prometheus-blue)

The application is created to test container infrastructure. 


Features
--------
1. Health check for Kubernetes
2. Prometheus Metrics
3. HashiCorp Vault integration in Helm chart

Environment Veriables
---------------------

| Variable | Description | Default |
| --- | --- | --- |
| PORT | Application port | 8080 |
| GIN_MODE | Gin Modes - debug, release, test | release |
| BANNER | Banner to be displayed on App Home page | "Hello from Go App" |


App Screenshot
--------------

![Image of GA-Home](https://github.com/iquzart/go-app/blob/master/doc/GA-Home.png)


License
-------

MIT


Author Information
------------------

Muhammed Iqbal <iquzart@hotmail.com>
