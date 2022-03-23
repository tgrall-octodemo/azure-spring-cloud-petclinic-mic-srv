---
page_type: sample
languages:
- java
products:
- Azure Spring Cloud
description: "Deploy Spring Boot apps using Azure Spring Cloud and MySQL"
urlFragment: "spring-petclinic-microservices"
---

# Deploy Spring Boot apps using Azure Spring Cloud and MySQL 

Azure Spring Cloud enables you to easily run a Spring Boot applications on Azure.

This quickstart shows you how to deploy an existing Java Spring Cloud application to Azure. When 
you're finished, you can continue to manage the application via the Azure CLI or switch to using the 
Azure Portal.

* [Deploy Spring Boot apps using Azure Spring Cloud and MySQL](#deploy-spring-boot-apps-using-azure-spring-cloud-and-mysql)
  * [What will you experience](#what-will-you-experience)
  * [What you will need](#what-you-will-need)
  * [Install the Azure CLI extension](#install-the-azure-cli-extension)
  * [Clone and build the repo](#clone-and-build-the-repo)
  * [Unit 1 - Deploy and monitor Spring Boot apps](#unit-1---deploy-and-monitor-spring-boot-apps)
  * [Unit 2 - AUTOMATE deployments using GitHub Actions](#unit-2---automate-deployments-using-github-actions)
  * [Unit 3 - Manage application secrets using Azure KeyVault](#unit-3---manage-application-secrets-using-azure-keyvault)
  * [Next Steps](#next-steps)

## What will you experience
You will:
- Build existing Spring Boot applications
- Provision an Azure Spring Cloud service instance. If you prefer Terraform, you may also provision using Terraform, see [`README-terraform`](./terraform/README-terraform.md) or [Bicep](./iac/bicep/README.md)
- Deploy applications to Azure
- Bind applications to Azure Database for MySQL
- Open the application
- Monitor applications
- Automate deployments using GitHub Actions
- Manage application secrets using Azure KeyVault

## What you will need

In order to deploy a Java app to cloud, you need 
an Azure subscription. If you do not already have an Azure 
subscription, you can activate your 
[MSDN subscriber benefits](https://azure.microsoft.com/pricing/member-offers/msdn-benefits-details/) 
or sign up for a 
[free Azure account]((https://azure.microsoft.com/free/)).

In addition, you will need the following:

| [Azure CLI version 2.17.1 or higher](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) 
| [Java 8](https://www.azul.com/downloads/azure-only/zulu/?version=java-8-lts&architecture=x86-64-bit&package=jdk) 
| [Maven](https://maven.apache.org/download.cgi) 
| [MySQL CLI](https://dev.mysql.com/downloads/shell/)
| [Git](https://git-scm.com/)
| [`jq` utility](https://stedolan.github.io/jq/download/)
|

Note -  The [`jq` utility](https://stedolan.github.io/jq/download/). On Windows, download [this Windows port of JQ](https://github.com/stedolan/jq/releases) and add the following to the `~/.bashrc` file: 
           ```bash
           alias jq=<JQ Download location>/jq-win64.exe
           ```

Note - The Bash shell. While Azure CLI should behave identically on all environments, shell 
semantics vary. Therefore, only bash can be used with the commands in this repo. 
To complete these repo steps on Windows, use Git Bash that accompanies the Windows distribution of 
Git. Use only Git Bash to complete this training on Windows. Do not use WSL.

### OR Use Azure Cloud Shell

Or, you can use the Azure Cloud Shell. Azure hosts Azure Cloud Shell, an interactive shell 
environment that you can use through your browser. You can use the Bash with Cloud Shell 
to work with Azure services. You can use the Cloud Shell pre-installed commands to run the 
code in this README without having to install anything on your local environment. To start Azure 
Cloud Shell: go to [https://shell.azure.com](https://shell.azure.com), or select the 
Launch Cloud Shell button to open Cloud Shell in your browser.

To run the code in this article in Azure Cloud Shell:

1. Start Cloud Shell.

1. Select the Copy button on a code block to copy the code.

1. Paste the code into the Cloud Shell session by selecting Ctrl+Shift+V on Windows and Linux or by selecting Cmd+Shift+V on macOS.

1. Select Enter to run the code.

## Install the Azure CLI extension

Install the Azure Spring Cloud extension for the Azure CLI using the following command

```bash
    az extension add --name spring-cloud
```
Note - `spring-cloud` CLI extension `2.1.0` or later is a pre-requisite to enable the
latest Java in-process agent for Application Insights. If you already 
have the CLI extension, you may need to upgrade to the latest using --

```bash
    az extension update --name spring-cloud
```

## Clone and build the repo

### Create a new folder and clone the sample app repository to your Azure Cloud account  

```bash
    mkdir source-code
    git clone https://github.com/azure-samples/spring-petclinic-microservices
```

### Change directory and build the project

```bash
    cd spring-petclinic-microservices
    mvn clean package -DskipTests -Denv=cloud
```
This will take a few minutes.

## Unit-1 - Deploy and monitor Spring Boot apps

### Prepare your environment for deployments

Create a bash script with environment variables by making a copy of the supplied template:

```bash
    cp .scripts/setup-env-variables-azure-template.sh .scripts/setup-env-variables-azure.sh
```

Open `.scripts/setup-env-variables-azure.sh` and enter the following information:

```bash

    export SUBSCRIPTION=subscription-id # customize this
    export RESOURCE_GROUP=resource-group-name # customize this
    ...
    export SPRING_CLOUD_SERVICE=azure-spring-cloud-name # customize this
    ...
    export MYSQL_SERVER_NAME=mysql-servername # customize this
    ...
    export MYSQL_SERVER_ADMIN_NAME=admin-name # customize this
    ...
    export MYSQL_SERVER_ADMIN_PASSWORD=SuperS3cr3t # customize this
    ...
```

Then, set the environment:
```bash
    source .scripts/setup-env-variables-azure.sh
```

### Login to Azure 
Login to the Azure CLI and choose your active subscription. Be sure to choose the active subscription that is whitelisted for Azure Spring Cloud

```bash
    az login
    az account list -o table
    az account set --subscription ${SUBSCRIPTION}
```

### Create Azure Spring Cloud service instance
Prepare a name for your Azure Spring Cloud service.  The name must be between 4 and 32 characters long and can contain only lowercase letters, numbers, and hyphens.  The first character of the service name must be a letter and the last character must be either a letter or a number.

Create a resource group to contain your Azure Spring Cloud service.

```bash
    az group create --name ${RESOURCE_GROUP} \
        --location ${REGION}
```

Create an instance of Azure Spring Cloud.

```bash
    az spring-cloud create --name ${SPRING_CLOUD_SERVICE} \
            --sku standard \
            --sampling-rate 100 \
            --resource-group ${RESOURCE_GROUP} \
            --location ${REGION}
```

The service instance will take around five minutes to deploy.

Set your default resource group name and cluster name using the following commands:

```bash
    az configure --defaults \
        group=${RESOURCE_GROUP} \
        location=${REGION} \
        spring-cloud=${SPRING_CLOUD_SERVICE}
```

### Create and configure Log Analytics Workspace

Create a Log Analytics Workspace using Azure CLI:

```bash
    az monitor log-analytics workspace create \
        --workspace-name ${LOG_ANALYTICS} \
        --resource-group ${RESOURCE_GROUP} \
        --location ${REGION}

    export LOG_ANALYTICS_RESOURCE_ID=$(az monitor log-analytics workspace show \
        --resource-group ${RESOURCE_GROUP} \
        --workspace-name ${LOG_ANALYTICS} | jq -r '.id')

    export SPRING_CLOUD_RESOURCE_ID=$(az spring-cloud show \
        --name ${SPRING_CLOUD_SERVICE} \
        --resource-group ${RESOURCE_GROUP} | jq -r '.id')
```

Setup diagnostics and publish logs and metrics from Spring Boot apps to Azure Log Analytics:

```bash
    az monitor diagnostic-settings create --name "send-logs-and-metrics-to-log-analytics" \
        --resource ${SPRING_CLOUD_RESOURCE_ID} \
        --workspace ${LOG_ANALYTICS_RESOURCE_ID} \
        --logs '[
             {
               "category": "ApplicationConsole",
               "enabled": true,
               "retentionPolicy": {
                 "enabled": false,
                 "days": 0
               }
             },
             {
                "category": "SystemLogs",
                "enabled": true,
                "retentionPolicy": {
                  "enabled": false,
                  "days": 0
                }
              },
             {
                "category": "IngressLogs",
                "enabled": true,
                "retentionPolicy": {
                  "enabled": false,
                  "days": 0
                 }
               }
           ]' \
           --metrics '[
             {
               "category": "AllMetrics",
               "enabled": true,
               "retentionPolicy": {
                 "enabled": false,
                 "days": 0
               }
             }
           ]'
```

### Load Spring Cloud Config Server

Use the `application.yml` in the root of this project to load configuration into the Config Server in Azure Spring Cloud.

```bash
    az spring-cloud config-server set \
        --config-file application.yml \
        --name ${SPRING_CLOUD_SERVICE}
```

### Create applications in Azure Spring Cloud

Create 5 apps.

```bash
    az spring-cloud app create --name ${API_GATEWAY} --instance-count 1 --assign-endpoint true \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${ADMIN_SERVER} --instance-count 1 --assign-endpoint true \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${CUSTOMERS_SERVICE} --instance-count 1 \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${VETS_SERVICE} --instance-count 1 \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${VISITS_SERVICE} --instance-count 1 \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
```

### Create MySQL Database

Create a MySQL database in Azure Database for MySQL.

```bash
    // create mysql server
    az mysql server create --resource-group ${RESOURCE_GROUP} \
     --name ${MYSQL_SERVER_NAME}  --location ${REGION} \
     --admin-user ${MYSQL_SERVER_ADMIN_NAME} \
     --admin-password ${MYSQL_SERVER_ADMIN_PASSWORD} \
     --sku-name GP_Gen5_2 \
     --ssl-enforcement Disabled \
     --version 5.7
    
    // allow access from Azure resources
    az mysql server firewall-rule create --name allAzureIPs \
     --server ${MYSQL_SERVER_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
    
    // allow access from your dev machine for testing
    az mysql server firewall-rule create --name devMachine \
     --server ${MYSQL_SERVER_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --start-ip-address <ip-address-of-your-dev-machine> \
     --end-ip-address <ip-address-of-your-dev-machine>
    
    // increase connection timeout
    az mysql server configuration set --name wait_timeout \
     --resource-group ${RESOURCE_GROUP} \
     --server ${MYSQL_SERVER_NAME} --value 2147483
    
    // SUBSTITUTE values
    mysql -u ${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
     -h ${MYSQL_SERVER_FULL_NAME} -P 3306 -p
    
    Enter password:
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 64379
    Server version: 5.6.39.0 MySQL Community Server (GPL)
    
    Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    mysql> CREATE DATABASE petclinic;
    Query OK, 1 row affected (0.10 sec)
    
    mysql> CREATE USER 'root' IDENTIFIED BY 'petclinic';
    Query OK, 0 rows affected (0.11 sec)
    
    mysql> GRANT ALL PRIVILEGES ON petclinic.* TO 'root';
    Query OK, 0 rows affected (1.29 sec)
    
    mysql> CALL mysql.az_load_timezone();
    Query OK, 3179 rows affected, 1 warning (6.34 sec)
    
    mysql> SELECT name FROM mysql.time_zone_name;
    ...
    
    mysql> quit
    Bye
    
    
    az mysql server configuration set --name time_zone \
     --resource-group ${RESOURCE_GROUP} \
     --server ${MYSQL_SERVER_NAME} --value "US/Pacific"
```

## Deploy a Self-Hosted Runner in the VNet

### VM
```sh
az network nsg rule create --access Allow --destination-port-range 22 --source-address-prefixes "Your IP Adress" --name "Allow SSH from local dev station" --nsg-name $nsg -g ${YOUR_RG} --priority 142

# az vm list-sizes --location $location --output table
# az vm image list-publishers --location $location --output table | grep -i "Microsoft"
# az vm image list-offers --publisher MicrosoftWindowsServer --location $location --output table
# az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --location $location --output table

# az vm image list-publishers --location $location --output table | grep -i Canonical
# az vm image list-offers --publisher Canonical --location $location --output table
# az vm image list --publisher Canonical --offer UbuntuServer --location $location --output table
# az vm image list --publisher Canonical --offer 0001-com-ubuntu-server-focal --location northeurope --output table --all

# az vm image list-publishers --location northeurope --output table | grep -i "Mariner"
# az vm image list-offers --publisher MicrosoftCBLMariner --location $location --output table
# az vm image list --publisher MicrosoftCBLMariner --offer cbl-mariner --location $location --output table --all

ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"

# --image The name of the operating system image as a URN alias, URN, custom image name or ID, custom image version ID, or VHD blob URI. In addition, it also supports shared gallery image. This parameter is required unless using `--attach-os-disk.`  Valid URN format: "Publisher:Offer:Sku:Version". For more information, see https: //docs.microsoft.com/azure/virtual-machines/linux/cli-ps-findimage.  Values from: az vm image list, az vm image show, az sig image-version show-shared.
# --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202203220

az vm create --name $self_hosted_runner_vm_name \
    --image UbuntuLTS \
    --admin-username adm_run \
    --resource-group $rg_name \
    --vnet-name $vnet_name \
    --subnet $appSubnet \
    --nsg $nsg \
    --size Standard_B1s \
    --zone 1 \
    --location $location \
    --ssh-key-values ~/.ssh/$ssh_key.pub
    # --generate-ssh-keys

network_interface_id=$(az vm show --name $self_hosted_runner_vm_name -g $rg_name --query 'networkProfile.networkInterfaces[0].id' -o tsv)
echo "Self-hosted Runner VM Network Interface ID :" $network_interface_id

network_interface_private_ip=$(az resource show --ids $network_interface_id \
  --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
echo "Network Interface private IP :" $network_interface_private_ip

network_interface_pub_ip_id=$(az resource show --ids $network_interface_id \
  --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.publicIPAddress.id' -o tsv)

network_interface_pub_ip=$(az network public-ip show -g $rg_name --id $network_interface_pub_ip_id --query "ipAddress" -o tsv)
echo "Network Interface public  IP :" $network_interface_pub_ip

# test
ssh -i ~/.ssh/$ssh_key $admin_username@$network_interface_pub_ip

# Once you have successfully connected to the VM, install the DevTools

# AZ CLI + AzureSpring Cloud extension
sudo apt-get install -y apt-transport-https
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | 
    sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update
sudo apt-get install azure-cli
az upgrade
az version

az bicep install
az bicep upgrade
az bicep version
az bicep --help

az login
az account set --subscription "<your subscription name>"
az provider register --namespace 'Microsoft.AppPlatform'
az extension add --name spring-cloud

# Java
# https://docs.microsoft.com/en-us/java/openjdk/containers
# https://docs.microsoft.com/en-us/java/openjdk/install#install-on-ubuntu 
# Valid values are only '18.04' and '20.04'
# For other versions of Ubuntu, please use the tar.gz package
ubuntu_release=`lsb_release -rs`
wget https://packages.microsoft.com/config/ubuntu/${ubuntu_release}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install msopenjdk-11 --yes
java -version

# jq
sudo apt-get install jq --yes

# Maven
sudo apt install maven --yes
mvn -version

# Git
git clone https://github.com/ezYakaEagle442/azure-spring-cloud-petclinic-mic-srv

# Maven Build
cd azure-spring-cloud-petclinic-mic-srv
mvn clean package -DskipTests -Denv=cloud

# Self-hosted Runner requires Docker
# see also https://docs.github.com/en/actions/hosting-your-own-runners/monitoring-and-troubleshooting-self-hosted-runners#troubleshooting-containers-in-self-hosted-runners
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

 sudo apt-get update
 sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io --yes
sudo docker --version

service --status-all
sudo service docker start
sudo service docker status

sudo systemctl is-active docker.service

# If your job fails with the following error:https://docs.github.com/en/actions/hosting-your-own-runners/monitoring-and-troubleshooting-self-hosted-runners#checking-the-docker-permissions
# dial unix /var/run/docker.sock: connect: permission denied
# https://gist.github.com/didof/be97b600ba3f9d1725b8c6d1c643c745

# https://docs.github.com/en/actions/hosting-your-own-runners/configuring-the-self-hosted-runner-application-as-a-service#installing-the-service
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status

# To view the systemd configuration, you can locate the service file here: /etc/systemd/system/actions.runner.<org>-<repo>.<runnerName>.service
ll /etc/systemd/system/actions.runner*
sudo systemctl show -p User actions.runner.octo-org-octo-repo.runner01.service
sudo systemctl show -p User actions.runner.ezYakaEagle442-azure-spring-cloud-petclinic-mic-srv.gh-action-runner.service

systemctl --type=service | grep actions.runner
sudo journalctl -u actions.runner.octo-org-octo-repo.runner01.service -f

```

```sh
ll /var/run/docker.sock
```

```console
srw-rw---- 1 root docker 0 Mar 23 17:10 /var/run/docker.sock=
```

```sh
less /etc/passwd | grep -i "<your username>"
less /etc/group | grep -i "docker"
sudo usermod -a -G docker <your username>

# https://gist.github.com/didof/be97b600ba3f9d1725b8c6d1c643c745
# to apply changes, log in and out
sudo su
sudo su [USER]

# and restart docker
sudo systemctl restart docker

#4. Give read and write permissions to docker socket
sudo chmod 666 /var/run/docker.sock

id
```


Read [https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners)

- Downloading and extracting the self-hosted runner application.
- Running the config script to configure the self-hosted runner application and register it with GitHub Actions. The config script requires the destination URL and an automatically-generated time-limited token to authenticate the request.
- Check your [Limits & Runner quotas](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits) 
```console

--------------------------------------------------------------------------------
|        ____ _ _   _   _       _          _        _   _                      |
|       / ___(_) |_| | | |_   _| |__      / \   ___| |_(_) ___  _ __  ___      |
|      | |  _| | __| |_| | | | | '_ \    / _ \ / __| __| |/ _ \| '_ \/ __|     |
|      | |_| | | |_|  _  | |_| | |_) |  / ___ \ (__| |_| | (_) | | | \__ \     |
|       \____|_|\__|_| |_|\__,_|_.__/  /_/   \_\___|\__|_|\___/|_| |_|___/     |
|                                                                              |
|                       Self-hosted runner registration                        |
|                                                                              |
--------------------------------------------------------------------------------

# Authentication


√ Connected to GitHub

# Runner Registration

Enter the name of the runner group to add this runner to: [press Enter for Default]

Enter the name of runner: [press Enter for gh-action-runner]

This runner will have the following labels: 'self-hosted', 'Linux', 'X64'
Enter any additional labels (ex. label-1,label-2): [press Enter to skip]

√ Runner successfully added
√ Runner connection is good

# Runner settings

Enter name of work folder: [press Enter for _work]

√ Settings Saved.

```

The self-hosted runner application must be active for the runner to accept jobs. When the runner application is connected to GitHub and ready to receive jobs, you will see the following message on the machine's terminal.
```console
√ Connected to GitHub

Current runner version: '2.288.1'
2022-03-23 16:37:04Z: Listening for Jobs
```

You can monitor the status of the self-hosted runner application and its activities. Log files are kept in the _diag directory


After completing the steps to add a self-hosted runner, the runner and its status are now listed under "Runners".
#### CleanUp: Remove the self-hosted Runner
Read [https://docs.github.com/en/actions/hosting-your-own-runners/removing-self-hosted-runners#removing-a-runner-from-a-repository](https://docs.github.com/en/actions/hosting-your-own-runners/removing-self-hosted-runners#removing-a-runner-from-a-repository)


### Container
TODO

### Deploy Spring Boot applications and set environment variables

Deploy Spring Boot applications to Azure from the VM created previously in the VNet

```bash
# https://github.com/MicrosoftDocs/azure-docs/issues/90220 : production deployment must be created first

az spring-cloud app deployment create --name production --app admin-server -s asc-petcliasc --artifact-path  spring-petclinic-admin-server/target/spring-petclinic-admin-server-2.6.3.jar -g rg-iac-asc-petclinic-mic-srv --version 2.6.3 --runtime-version Java_11 --cpu 500m --memory 512Mi --instance-count 3 --disable-probe false 

# This query is wrong but should returns as many instance-count as decleared at app deployment creation : 3
appInstances="$(az spring-cloud app show --name admin-server -g rg-iac-asc-petclinic-mic-srv --service asc-petcliasc --query "[?properties.activeDeployment.name=='production'].properties.activeDeployment.properties.instances.name" -o tsv | head -1)"

az spring-cloud app logs --name api-gateway \
                         --resource-group rg-iac-asc-petclinic-mic-srv \
                         --service asc-petcliasc \
                         --deployment production \
                         --instance api-gateway-production-11-6d868bb6fd-k5jzt \
                         --limit 2048 \
                         --lines 100 \
                         --since 60m


az spring-cloud app deploy --name admin-server --artifact-path spring-petclinic-admin-server/target/spring-petclinic-admin-server-2.6.3.jar --jvm-options="-Xms512m -Xmx512m -Dspring.profiles.active=mysql" -g rg-iac-asc-petclinic-mic-srv --service asc-petcliasc --verbose

az spring-cloud app show --name api-gateway -g rg-iac-asc-petclinic-mic-srv --service asc-petcliasc

az spring-cloud app logs --name admin-server --resource-group rg-iac-asc-petclinic-mic-srv --service asc-petcliasc --deployment production --instance admin-server-production-12-7c4c79b658-8bvfb --limit 2048 --lines 100 --since 60m

az spring-cloud app show-deploy-log --deployment production --name admin-server -g rg-iac-asc-petclinic-mic-srv --service asc-petcliasc

az spring-cloud app set-deployment --deployment production --name admin-server -s asc-petcliasc -g rg-iac-asc-petclinic-mic-srv 

    az spring-cloud app deploy --name ${API_GATEWAY} \
        --jar-path ${API_GATEWAY_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql'
    
    az spring-cloud app deploy --name ${ADMIN_SERVER} \
        --jar-path ${ADMIN_SERVER_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql'
    
    
    az spring-cloud app deploy --name ${CUSTOMERS_SERVICE} \
        --jar-path ${CUSTOMERS_SERVICE_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
        --env MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_FULL_NAME} \
              MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
              MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
              MYSQL_SERVER_ADMIN_PASSWORD=${MYSQL_SERVER_ADMIN_PASSWORD}
    
    
    az spring-cloud app deploy --name ${VETS_SERVICE} \
        --jar-path ${VETS_SERVICE_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
        --env MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_FULL_NAME} \
              MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
              MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
              MYSQL_SERVER_ADMIN_PASSWORD=${MYSQL_SERVER_ADMIN_PASSWORD}
              
    
    az spring-cloud app deploy --name ${VISITS_SERVICE} \
        --jar-path ${VISITS_SERVICE_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
        --env MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_FULL_NAME} \
              MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
              MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
              MYSQL_SERVER_ADMIN_PASSWORD=${MYSQL_SERVER_ADMIN_PASSWORD}
```

```bash
    az spring-cloud app show --name ${API_GATEWAY} | grep url
```

Navigate to the URL provided by the previous command to open the Pet Clinic application.
    
![](./media/petclinic.jpg)

### Monitor Spring Boot applications

#### Use the Petclinic application and make a few REST API calls

Open the Petclinic application and try out a few tasks - view pet owners and their pets, 
vets, and schedule pet visits:

```bash
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/
```

You can also `curl` the REST API exposed by the Petclinic application. The admin REST
API allows you to create/update/remove items in Pet Owners, Pets, Vets and Visits.
You can run the following curl commands:

```bash
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/4
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/ 
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/petTypes
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/3/pets/4
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/6/pets/8/
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/vet/vets
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
```

#### Get the log stream for API Gateway and Customers Service

Use the following command to get the latest 100 lines of app console logs from Customers Service. 
```bash
az spring-cloud app logs -n ${CUSTOMERS_SERVICE} --lines 100
```
By adding a `-f` parameter you can get real-time log streaming from the app. Try log streaming for the API Gateway app.
```bash
az spring-cloud app logs -n ${API_GATEWAY} -f
```
You can use `az spring-cloud app logs -h` to explore more parameters and log stream functionalities.

#### Open Actuator endpoints for API Gateway and Customers Service apps

Spring Boot includes a number of additional features to help you monitor and manage your application when you push it to production ([Spring Boot Actuator: Production-ready Features](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#actuator)). You can choose to manage and monitor your application by using HTTP endpoints or with JMX. Auditing, health, and metrics gathering can also be automatically applied to your application.

Actuator endpoints let you monitor and interact with your application. By default, Spring Boot application exposes `health` and `info` endpoints to show arbitrary application info and health information. Apps in this project are pre-configured to expose all the Actuator endpoints.

You can try them out by opening the following app actuator endpoints in a browser:

```bash
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/env
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/configprops

open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/env
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/configprops
```

#### Start monitoring Spring Boot apps and dependencies - in Application Insights

Open the Application Insights created by Azure Spring Cloud and start monitoring 
Spring Boot applications. You can find the Application Insights in the same Resource Group where
you created an Azure Spring Cloud service instance.

Navigate to the `Application Map` blade:
![](./media/distributed-tracking-new-ai-agent.jpg)

Navigate to the `Performance` blade:
![](./media/petclinic-microservices-performance.jpg)

Navigate to the `Performance/Dependenices` blade - you can see the performance number for dependencies, 
particularly SQL calls:
![](./media/petclinic-microservices-insights-on-dependencies.jpg)

Click on a SQL call to see the end-to-end transaction in context:
![](./media/petclinic-microservices-end-to-end-transaction-details.jpg)

Navigate to the `Failures/Exceptions` blade - you can see a collection of exceptions:
![](./media/petclinic-microservices-failures-exceptions.jpg)

Click on an exception to see the end-to-end transaction and stacktrace in context:
![](./media/end-to-end-transaction-details.jpg)

Navigate to the `Metrics` blade - you can see metrics contributed by Spring Boot apps, 
Spring Cloud modules, and dependencies. 
The chart below shows `gateway-requests` (Spring Cloud Gateway), `hikaricp_connections`
 (JDBC Connections) and `http_client_requests`.
 
![](./media/petclinic-microservices-metrics.jpg)

Spring Boot registers a lot number of core metrics: JVM, CPU, Tomcat, Logback... 
The Spring Boot auto-configuration enables the instrumentation of requests handled by Spring MVC.
All those three REST controllers `OwnerResource`, `PetResource` and `VisitResource` have been instrumented by the `@Timed` Micrometer annotation at class level.

* `customers-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.owner`
  * @Timed: `petclinic.pet`
* `visits-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.visit`

You can see these custom metrics in the `Metrics` blade:
![](./media/petclinic-microservices-custom-metrics.jpg)

You can use the Availability Test feature in Application Insights and monitor 
the availability of applications:
![](./media/petclinic-microservices-availability.jpg)

Navigate to the `Live Metrics` blade - you can see live metrics on screen with low latencies < 1 second:
![](./media/petclinic-microservices-live-metrics.jpg)

#### Start monitoring Petclinic logs and metrics in Azure Log Analytics

Open the Log Analytics that you created - you can find the Log Analytics in the same 
Resource Group where you created an Azure Spring Cloud service instance.

In the Log Analyics page, selects `Logs` blade and run any of the sample queries supplied below 
for Azure Spring Cloud.

Type and run the following Kusto query to see application logs:
```sql
    AppPlatformLogsforSpring 
    | where TimeGenerated > ago(24h) 
    | limit 500
    | sort by TimeGenerated
```

Type and run the following Kusto query to see `customers-service` application logs:
```sql
    AppPlatformLogsforSpring 
    | where AppName has "customers"
    | limit 500
    | sort by TimeGenerated
```

Type and run the following Kusto query  to see errors and exceptions thrown by each app:
```sql
    AppPlatformLogsforSpring 
    | where Log contains "error" or Log contains "exception"
    | extend FullAppName = strcat(ServiceName, "/", AppName)
    | summarize count_per_app = count() by FullAppName, ServiceName, AppName, _ResourceId
    | sort by count_per_app desc 
    | render piechart
```

Type and run the following Kusto query to see all in the inbound calls into Azure Spring Cloud:
```sql
    AppPlatformIngressLogs
    | project TimeGenerated, RemoteAddr, Host, Request, Status, BodyBytesSent, RequestTime, ReqId, RequestHeaders
    | sort by TimeGenerated
```

Type and run the following Kusto query to see all the logs from the managed Spring Cloud
Config Server managed by Azure Spring Cloud:
```sql
    AppPlatformSystemLogs
    | where LogType contains "ConfigServer"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

Type and run the following Kusto query to see all the logs from the managed Spring Cloud
Service Registry managed by Azure Spring Cloud:
```sql
    AppPlatformSystemLogs
    | where LogType contains "ServiceRegistry"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

## Unit-2 - Automate deployments using GitHub Actions
### Prerequisites 
To get started with deploying this sample app from GitHub Actions, please:
1. Complete the sections above with your MySQL, Azure Spring Cloud instances and apps created.
2. Fork this repository and turn on GitHub Actions in your fork

Read :
- [https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
- [https://github.com/actions/virtual-environments](https://github.com/actions/virtual-environments)
- [https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-java-with-maven](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-java-with-maven)
- []()

### Prepare secrets in your Key Vault
If you do not have a Key Vault yet, run the following commands to provision a Key Vault:
```bash
    az keyvault create --name ${KEY_VAULT} -g ${RESOURCE_GROUP}
```

Add the MySQL secrets to your Key Vault:
```bash
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-FULL-NAME" --value ${MYSQL_SERVER_FULL_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-DATABASE-NAME" --value ${MYSQL_DATABASE_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-ADMIN-LOGIN-NAME" --value ${MYSQL_SERVER_ADMIN_LOGIN_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-ADMIN-PASSWORD" --value ${MYSQL_SERVER_ADMIN_PASSWORD}
```

Create a service principle with enough scope/role to manage your Azure Spring Cloud instance:
```bash
    az ad sp create-for-rbac --role contributor --scopes /subscriptions/${SUBSCRIPTION} --sdk-auth > spn.txt

    #  For GitHub Action Runner: https://aka.ms/azadsp-cli
    appName="gha_run"
    # other way to create the SPN :
    SP_PWD=$(az ad sp create-for-rbac --name $appName --role contributor --scopes /subscriptions/${SUBSCRIPTION} --query password --output tsv)
    #SP_ID=$(az ad sp show --id http://$appName --query objectId -o tsv)
    #SP_ID=$(az ad sp list --all --query "[?appDisplayName=='${appName}'].{appId:appId}" --output tsv)
    SP_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}'].{id:appId}" --output tsv)
    TENANT_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}'].{t:appOwnerTenantId}" --output tsv)
```
With results:
```json
    {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>",
        "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
        "resourceManagerEndpointUrl": "https://management.azure.com/",
        "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
        "galleryEndpointUrl": "https://gallery.azure.com/",
        "managementEndpointUrl": "https://management.core.windows.net/"
    }
```
Add them as secrets to your Key Vault:
```bash
    az keyvault secret set --vault-name ${KEY_VAULT} --name "AZURE-CREDENTIALS-FOR-SPRING" --file spn.txt # --value "<results above>"

    az keyvault secret set --vault-name ${KEY_VAULT} --name "GHA-RUN-SPN-APP" --value $SP_ID
    az keyvault secret set --vault-name ${KEY_VAULT} --name "GHA-RUN-SPN-PWD" --value $SP_PWD
    az keyvault secret set --vault-name ${KEY_VAULT} --name "GHA-RUN-SPN-TNT" --value $TENANT_ID
```

### Grant access to Key Vault with Service Principal
To generate a key to access the Key Vault, execute command below:
```bash
    az ad sp create-for-rbac --role contributor --scopes /subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT} --sdk-auth
```
Then, follow [the steps here](https://docs.microsoft.com/azure/spring-cloud/spring-cloud-github-actions-key-vault#add-access-policies-for-the-credential) to add access policy for the Service Principal.

```sh
az keyvault set-policy -n $KV_NAME --secret-permissions get list --spn <clientId from the Azure SPN JSON>
```

In the end, add this service principal as secret named "AZURE_CREDENTIALS" in your forked GitHub repo following [the steps here](https://docs.microsoft.com/azure/spring-cloud/how-to-github-actions?pivots=programming-language-java#set-up-github-repository-and-authenticate-1).

You can also read [Use GitHub Actions to connect to Azure documentation](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows) to add the AZURE_CREDENTIALS to your repo.

Also add your AZURE_SUBSCRIPTION to your GH repo secrets / Actions secrets / Repository secrets

### Customize your workflow
Read [GitHub Action for deploying to Azure Spring Cloud](https://github.com/marketplace/actions/azure-spring-cloud)
Finally, edit the workflow file `.github/workflows/action.yml` in your forked repo to fill in the Azure Spring Cloud instance name, and Key Vault name that you just created:
```yml
env:
  SPRING_CLOUD_SERVICE: azure-spring-cloud-name # name of your Azure Spring Cloud instance
  KEYVAULT: your-keyvault-name # customize this
```


Once you push this change, you will see GitHub Actions triggered to build and deploy all the apps in the repo to your Azure Spring Cloud instance.
![](./media/automate-deployments-using-github-actions.png)

## Unit-3 - Manage application secrets using Azure KeyVault

Use Azure Key Vault to store and load secrets to connect to MySQL database.

### Create Azure Key Vault and store secrets

If you skipped the [Automation step](#automate-deployments-using-github-actions), create an Azure Key Vault and store database connection secrets.

```bash
    az keyvault create --name ${KEY_VAULT} -g ${RESOURCE_GROUP}
    export KEY_VAULT_URI=$(az keyvault show --name ${KEY_VAULT} | jq -r '.properties.vaultUri')
```

Store database connection secrets in Key Vault.

```bash
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-FULL-NAME" --value ${MYSQL_SERVER_FULL_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-DATABASE-NAME" --value ${MYSQL_DATABASE_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-ADMIN-LOGIN-NAME" --value ${MYSQL_SERVER_ADMIN_LOGIN_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-ADMIN-PASSWORD" --value ${MYSQL_SERVER_ADMIN_PASSWORD}
```                      

### Enable Managed Identities for applications in Azure Spring Cloud

Enable System Assigned Identities for applications and export identities to environment.

```bash
    az spring-cloud app identity assign --name ${CUSTOMERS_SERVICE}
    export CUSTOMERS_SERVICE_IDENTITY=$(az spring-cloud app show --name ${CUSTOMERS_SERVICE} | jq -r '.identity.principalId')
    
    az spring-cloud app identity assign --name ${VETS_SERVICE}
    export VETS_SERVICE_IDENTITY=$(az spring-cloud app show --name ${VETS_SERVICE} | jq -r '.identity.principalId')
    
    az spring-cloud app identity assign --name ${VISITS_SERVICE}
    export VISITS_SERVICE_IDENTITY=$(az spring-cloud app show --name ${VISITS_SERVICE} | jq -r '.identity.principalId')
```

### Grant Managed Identities with access to Azure Key Vault

Add an access policy to Azure Key Vault to allow Managed Identities to read secrets.

```bash
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${CUSTOMERS_SERVICE_IDENTITY} --secret-permissions get list
        
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${VETS_SERVICE_IDENTITY} --secret-permissions get list
        
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${VISITS_SERVICE_IDENTITY} --secret-permissions get list
```

### Activate applications to load secrets from Azure Key Vault

Activate applications to load secrets from Azure Key Vault.

```bash
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI
    az spring-cloud app update --name ${CUSTOMERS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
    
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI    
    az spring-cloud app update --name ${VETS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
    
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI       
    az spring-cloud app update --name ${VISITS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
```

## Next Steps

In this quickstart, you've deployed an existing Spring Boot-based app using Azure CLI, Terraform and GitHub Actions. To learn more about Azure Spring Cloud, go to:

- [Azure Spring Cloud](https://azure.microsoft.com/en-us/services/spring-cloud/)
- [Azure Spring Cloud docs](https://docs.microsoft.com/en-us/azure/java/)
- [Deploy Spring microservices from scratch](https://github.com/microsoft/azure-spring-cloud-training)
- [Deploy existing Spring microservices](https://github.com/Azure-Samples/azure-spring-cloud)
- [Azure for Java Cloud Developers](https://docs.microsoft.com/en-us/azure/java/)
- [Spring Cloud Azure](https://cloud.spring.io/spring-cloud-azure/)
- [Spring Cloud](https://spring.io/projects/spring-cloud)

## Credits

This Spring microservices sample is forked from 
[Azure Samples spring-petclinic/spring-petclinic-microservices](https://github.com/Azure-Samples/spring-petclinic-microservices) - see [Petclinic README](./README-petclinic.md). 

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
