#
# Front-end to bring some sanity to the litany of tools and switches
# for working with a k8s cluster. Note that this file exercise core k8s
# commands that's independent of the cluster vendor.
#
# All vendor-specific commands are in the make file for that vendor:
# az.mak, eks.mak, gcp.mak, mk.mak
#
# This file addresses APPPLing the Deployment, Service, Gateway, and VirtualService
#
# Be sure to set your context appropriately for the log monitor.
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.

# These will be filled in by template processor
CREG=ZZ-CR-ID
REGID=ZZ-REG-ID
AWS_REGION=ZZ-AWS-REGION
JAVA_HOME=ZZ-JAVA-HOME
GAT_DIR=ZZ-GAT-DIR

# Keep all the logs out of main directory
LOG_DIR=logs

# These should be in your search path
KC=kubectl
DK=docker
AWS=aws
IC=istioctl

# Application versions
# Override these by environment variables and `make -e`
APP_VER_TAG=v1
S2_VER=v1
LOADER_VER=v1

# Gatling parameters to be overridden by environment variables and `make -e`
SIM_NAME=ReadUserSim
USERS=1

# Gatling parameters that most of the time will be unchanged
# but which you might override as projects become sophisticated
SIM_FILE=ReadTables.scala
SIM_PACKAGE=proj756
GATLING_OPTIONS=

# Other Gatling parameters---you should not have to change these
GAT=$(GAT_DIR)/bin/gatling.sh
SIM_DIR=gatling/simulations
RES_DIR=gatling/resources
SIM_PACKAGE_DIR=$(SIM_DIR)/$(SIM_PACKAGE)
SIM_FULL_NAME=$(SIM_PACKAGE).$(SIM_NAME)

# Kubernetes parameters that most of the time will be unchanged
# but which you might override as projects become sophisticated
APP_NS=c756ns
ISTIO_NS=istio-system

# ----------------------------------------------------------------------------------------
# -------  Targets to be invoked directly from command line                        -------
# ----------------------------------------------------------------------------------------

# ---  templates:  Instantiate all template files
#
# This is the only entry that *must* be run from k8s-tpl.mak
# (because it creates k8s.mak)
templates:
	tools/process-templates.sh

# --- provision: Provision the entire stack
# This typically is all you need to do to install the sample application and
# all its dependencies
#
# Preconditions:
# 1. Templates have been instantiated (make -f k8s-tpl.mak templates)
# 2. Current context is a running Kubernetes cluster (make -f {az,eks,gcp,mk}.mak start)
#
provision: istio prom kiali deploy

# --- deploy: Deploy and monitor the three microservices
# Use `provision` to deploy the entire stack (including Istio, Prometheus, ...).
# This target only deploys the sample microservices
deploy: appns gw logger product cart customer db monitoring
	$(KC) -n $(APP_NS) get gw,vs,deploy,svc,pods

# --- rollout: Rollout new deployments of all microservices
rollout: rollout-logger rollout-product rollout-cart rollout-db rollout-customer

# --- rollout-logger: Rollout a new deployment of logger
rollout-logger: logger
	$(KC) rollout -n $(APP_NS) restart deployment/logger

# --- rollout-product: Rollout a new deployment of product
rollout-product: product
	$(KC) rollout -n $(APP_NS) restart deployment/product

# --- rollout-cart: Rollout a new deployment of cart
rollout-cart: cart
	$(KC) rollout -n $(APP_NS) restart deployment/cart

# --- rollout-customer: Rollout a new deployment of customer
rollout-customer: customer
	$(KC) rollout -n $(APP_NS) restart deployment/customer

# --- rollout-db: Rollout a new deployment of DB
rollout-db: db
	$(KC) rollout -n $(APP_NS) restart deployment/cyberdb

# --- health-off: Turn off the health monitoring for the three microservices
# If you don't know exactly why you want to do this---don't
health-off:
	$(KC) -n $(APP_NS) apply -f cluster/logger-nohealth.yaml
	$(KC) -n $(APP_NS) apply -f cluster/cart-nohealth.yaml
	$(KC) -n $(APP_NS) apply -f cluster/customer-nohealth.yaml	
	$(KC) -n $(APP_NS) apply -f cluster/product-nohealth.yaml
	$(KC) -n $(APP_NS) apply -f cluster/customer-nohealth.yaml
	$(KC) -n $(APP_NS) apply -f cluster/db-nohealth.yaml

# --- scratch: Delete the microservices and everything else in application NS
scratch: clean
	$(KC) delete -n $(APP_NS) deploy --all
	$(KC) delete -n $(APP_NS) svc    --all
	$(KC) delete -n $(APP_NS) gw     --all
	$(KC) delete -n $(APP_NS) dr     --all
	$(KC) delete -n $(APP_NS) vs     --all
	$(KC) delete -n $(APP_NS) se     --all
	$(KC) delete -n $(ISTIO_NS) vs monitoring --ignore-not-found=true
	$(KC) get -n $(APP_NS) deploy,svc,pods,gw,dr,vs,se
	$(KC) get -n $(ISTIO_NS) vs

# --- clean: Delete all the application log files
clean:
	/bin/rm -f $(LOG_DIR)/{logger,product,cart,customer,db,gw,monvs}*.log $(LOG_DIR)/rollout*.log

# --- dashboard: Start the standard Kubernetes dashboard
# NOTE:  Before invoking this, the dashboard must be installed and a service account created
dashboard: showcontext
	echo Please follow instructions at https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
	echo Remember to 'pkill kubectl' when you are done!
	$(KC) proxy &
	open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login

# --- extern: Display status of Istio ingress gateway
# Especially useful for Minikube, if you can't remember whether you invoked its `lb`
# target or directly ran `minikube tunnel`
extern: showcontext
	$(KC) -n $(ISTIO_NS) get svc istio-ingressgateway

# --- log-X: show the log of a particular service
log-logger:
	$(KC) -n $(APP_NS) logs deployment/logger --container logger

log-product:
	$(KC) -n $(APP_NS) logs deployment/product --container product

log-cart:
	$(KC) -n $(APP_NS) logs deployment/cart --container cart
log-customer:
	$(KC) -n $(APP_NS) logs deployment/customer --container customer


log-db:
	$(KC) -n $(APP_NS) logs deployment/cyberdb --container cyberdb


# --- shell-X: hint for shell into a particular service
shell-logger:
	@echo Use the following command line to drop into the logger service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/logger --container logger -- bash

shell-product:
	@echo Use the following command line to drop into the product service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/product --container product -- bash

shell-cart:
	@echo Use the following command line to drop into the cart service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/cart --container cart -- bash
shell-customer:
	@echo Use the following command line to drop into the customer service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/customer --container customer -- bash


shell-db:
	@echo Use the following command line to drop into the db service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/cyberdb --container cyberdb -- bash

# --- lsa: List services in all namespaces
lsa: showcontext
	$(KC) get svc --all-namespaces

# --- ls: Show deploy, pods, vs, and svc of application ns
ls: showcontext
	$(KC) get -n $(APP_NS) gw,vs,svc,deployments,pods

# --- lsd: Show containers in pods for all namespaces
lsd:
	$(KC) get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort

# --- reinstate: Reinstate provisioning on a new set of worker nodes
# Do this after you do `up` on a cluster that implements that operation.
# AWS implements `up` and `down`; other cloud vendors may not.
reinstate: istio
	$(KC) create ns $(APP_NS) | tee $(LOG_DIR)/reinstate.log
	$(KC) label ns $(APP_NS) istio-injection=enabled | tee -a $(LOG_DIR)/reinstate.log

# --- showcontext: Display current context
showcontext:
	$(KC) config get-contexts

# --- dynamodb-init: set up our DynamoDB tables
#
dynamodb-init: $(LOG_DIR)/dynamodb-init.log

# --- dynamodb-stop: Stop the AWS DynamoDB service
#
dynamodb-clean:
	$(AWS) cloudformation delete-stack --stack-name db-ZZ-REG-ID || true | tee $(LOG_DIR)/dynamodb-clean.log
	@# Rename DynamoDB log so dynamodb-init will force a restart but retain the log
	/bin/mv -f $(LOG_DIR)/dynamodb-init.log $(LOG_DIR)/dynamodb-init-old.log

# --- ls-tables: List the tables and their read/write units for all DynamodDB tables
ls-tables:
	@tools/list-dynamodb-tables.sh $(AWS) $(AWS_REGION)

# --- registry-login: Login to the container registry
#
registry-login:
	# Use '@' to suppress echoing the $CR_PAT to screen
	@/bin/sh -c 'echo ${CR_PAT} | $(DK) login $(CREG) -u $(REGID) --password-stdin'

# --- Variables defined for URL targets
# Utility to get the hostname (AWS) or ip (everyone else) of a load-balanced service
# Must be followed by a service
IP_GET_CMD=tools/getip.sh $(KC) $(ISTIO_NS)

# This expression is reused several times
# Use back-tick for subshell so as not to confuse with make $() variable notation
INGRESS_IP=`$(IP_GET_CMD) svc/istio-ingressgateway`

# --- kiali-url: Print the URL to browse Kiali in current cluster
kiali-url:
	@/bin/sh -c 'echo http://$(INGRESS_IP)/kiali'

# --- grafana-url: Print the URL to browse Grafana in current cluster
grafana-url:
	@# Use back-tick for subshell so as not to confuse with make $() variable notation
	@/bin/sh -c 'echo http://`$(IP_GET_CMD) svc/grafana-ingress`:3000/'

# --- prometheus-url: Print the URL to browse Prometheus in current cluster
prometheus-url:
	@# Use back-tick for subshell so as not to confuse with make $() variable notation
	@/bin/sh -c 'echo http://`$(IP_GET_CMD) svc/prom-ingress`:9090/'

# --- Variables defined for Gatling targets
#
# Suffix to all Gatling commands
# 2>&1:       Redirect stderr to stdout. This ensures the long errors from a
#             misnamed Gatling script are clipped
# | head -18: Display first 18 lines, discard the rest
# &:          Run in background
GAT_SUFFIX=2>&1 | head -18 &

# --- gatling-command: Print the bash command to run a Gatling simulation
# Less convenient than gatling-music or gatling-user (below) but the resulting commands
# from this target are listed by `jobs` and thus easy to kill.
gatling-command:
	@/bin/sh -c 'echo "CLUSTER_IP=$(INGRESS_IP) USERS=1 SIM_NAME=ReadMusicSim make -e -f k8s.mak run-gatling $(GAT_SUFFIX)"'

# ----------------------------------------------------------------------------------------
# ------- Targets called by above. Not normally invoked directly from command line -------
# ------- Note that some subtargets are in `obs.mak`                               -------
# ----------------------------------------------------------------------------------------

# Install Prometheus stack by calling `obs.mak` recursively
prom:
	make -f obs.mak init-helm
	make -f obs.mak install-prom

# Install Kiali operator and Kiali by calling `obs.mak` recursively
# Waits for Kiali to be created and begin running. This wait is required
# before installing the three microservices because they
# depend upon some Custom Resource Definitions (CRDs) added
# by Kiali
kiali:
	make -f obs.mak install-kiali
	# Kiali operator can take awhile to start Kiali
	tools/waiteq.sh 'app=kiali' '{.items[*]}'              ''        'Kiali' 'Created'
	tools/waitne.sh 'app=kiali' '{.items[0].status.phase}' 'Running' 'Kiali' 'Running'

# Install Istio
istio:
	$(IC) install --set profile=demo --set hub=gcr.io/istio-release | tee -a $(LOG_DIR)/mk-reinstate.log

# Create and configure the application namespace
appns:
	# Appended "|| true" so that make continues even when command fails
	# because namespace already exists
	$(KC) create ns $(APP_NS) || true
	$(KC) label namespace $(APP_NS) --overwrite=true istio-injection=enabled

# Update monitoring virtual service and display result
monitoring: monvs
	$(KC) -n $(ISTIO_NS) get vs

# Update monitoring virtual service
monvs: cluster/monitoring-virtualservice.yaml
	$(KC) -n $(ISTIO_NS) apply -f $< > $(LOG_DIR)/monvs.log

# Update service gateway
gw: cluster/service-gateway.yaml
	$(KC) -n $(APP_NS) apply -f $< > $(LOG_DIR)/gw.log

# Start DynamoDB at the default read and write rates
$(LOG_DIR)/dynamodb-init.log: cluster/cloudformationdynamodb.json
	@# "|| true" suffix because command fails when stack already exists
	@# (even with --on-failure DO_NOTHING, a nonzero error code is returned)
	$(AWS) cloudformation create-stack --stack-name db-ZZ-REG-ID --template-body file://$< || true | tee $(LOG_DIR)/dynamodb-init.log

# Update logger and associated monitoring, rebuilding if necessary
logger: $(LOG_DIR)/logger.repo.log cluster/logger.yaml cluster/logger-sm.yaml cluster/logger-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/logger.yaml | tee $(LOG_DIR)/logger.log
	$(KC) -n $(APP_NS) apply -f cluster/logger-sm.yaml | tee -a $(LOG_DIR)/logger.log
	$(KC) -n $(APP_NS) apply -f cluster/logger-vs.yaml | tee -a $(LOG_DIR)/logger.log

# Update product and associated monitoring, rebuilding if necessary
product: $(LOG_DIR)/product.repo.log cluster/product.yaml cluster/product-sm.yaml cluster/product-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/product.yaml | tee $(LOG_DIR)/product.log
	$(KC) -n $(APP_NS) apply -f cluster/product-sm.yaml | tee -a $(LOG_DIR)/product.log
	$(KC) -n $(APP_NS) apply -f cluster/product-vs.yaml | tee -a $(LOG_DIR)/product.log

# Update cart and associated monitoring, rebuilding if necessary
cart: $(LOG_DIR)/cart.repo.log cluster/cart.yaml cluster/cart-sm.yaml cluster/cart-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/cart.yaml | tee $(LOG_DIR)/cart.log
	$(KC) -n $(APP_NS) apply -f cluster/cart-sm.yaml | tee -a $(LOG_DIR)/cart.log
	$(KC) -n $(APP_NS) apply -f cluster/cart-vs.yaml | tee -a $(LOG_DIR)/cart.log

# Update customer and associated monitoring, rebuilding if necessary
customer: $(LOG_DIR)/customer.repo.log cluster/customer.yaml cluster/customer-sm.yaml cluster/customer-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/customer.yaml | tee $(LOG_DIR)/customer.log
	$(KC) -n $(APP_NS) apply -f cluster/customer-sm.yaml | tee -a $(LOG_DIR)/customer.log
	$(KC) -n $(APP_NS) apply -f cluster/customer-vs.yaml | tee -a $(LOG_DIR)/customer.log



# Update DB and associated monitoring, rebuilding if necessary
db: $(LOG_DIR)/db.repo.log cluster/awscred.yaml cluster/dynamodb-service-entry.yaml cluster/db.yaml cluster/db-sm.yaml cluster/db-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/awscred.yaml | tee $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/dynamodb-service-entry.yaml | tee -a $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/db.yaml | tee -a $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/db-sm.yaml | tee -a $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/db-vs.yaml | tee -a $(LOG_DIR)/db.log

# Build & push the images up to the CR
cri: $(LOG_DIR)/logger.repo.log $(LOG_DIR)/product.repo.log $(LOG_DIR)/cart.repo.log $(LOG_DIR)/db.repo.log

# Build the logger service
$(LOG_DIR)/logger.repo.log: logger/Dockerfile logger/app.py logger/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/team-j-logger:$(APP_VER_TAG) logger | tee $(LOG_DIR)/logger.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-logger:$(APP_VER_TAG) | tee $(LOG_DIR)/logger.repo.log

# Build the product service
$(LOG_DIR)/product.repo.log: product/Dockerfile product/app.py product/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/team-j-product:$(APP_VER_TAG) product | tee $(LOG_DIR)/product.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-product:$(APP_VER_TAG) | tee $(LOG_DIR)/product.repo.log

# Build the cart service
$(LOG_DIR)/cart.repo.log: product/Dockerfile cart/app.py cart/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/team-j-cart:$(APP_VER_TAG) cart | tee $(LOG_DIR)/cart.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-cart:$(APP_VER_TAG) | tee $(LOG_DIR)/cart.repo.log

# Build the customer service
$(LOG_DIR)/customer.repo.log: product/Dockerfile customer/app.py customer/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/team-j-customer:$(APP_VER_TAG) customer | tee $(LOG_DIR)/customer.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-customer:$(APP_VER_TAG) | tee $(LOG_DIR)/customer.repo.log

# Build the db service
$(LOG_DIR)/db.repo.log: db/Dockerfile db/app.py db/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/team-j-cyberdb:$(APP_VER_TAG) db | tee $(LOG_DIR)/db.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-cyberdb:$(APP_VER_TAG) | tee $(LOG_DIR)/db.repo.log

# Build the loader
$(LOG_DIR)/loader.repo.log: loader/app.py loader/requirements.txt loader/Dockerfile
	$(DK) image build -t $(CREG)/$(REGID)/team-j-cyberloader:$(LOADER_VER) loader  | tee $(LOG_DIR)/loader.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-cyberloader:$(LOADER_VER) | tee $(LOG_DIR)/loader.repo.log

# Push all the container images to the container registry
# This isn't often used because the individual build targets also push
# the updated images to the registry
cr:
	$(DK) push $(CREG)/$(REGID)/team-j-logger:$(APP_VER_TAG) | tee $(LOG_DIR)/logger.repo.log
	$(DK) push $(CREG)/$(REGID)/team-j-product:$(APP_VER_TAG) | tee $(LOG_DIR)/product.repo.log
	$(DK) push $(CREG)/$(REGID)/team-j-cart:$(APP_VER_TAG) | tee $(LOG_DIR)/cart.repo.log
	$(DK) push $(CREG)/$(REGID)/team-j-customer:$(APP_VER_TAG) | tee $(LOG_DIR)/customer.repo.log	
	$(DK) push $(CREG)/$(REGID)/team-j-cyberdb:$(APP_VER_TAG) | tee $(LOG_DIR)/db.repo.log

#
# Other attempts at Gatling commands. Target `gatling-command` is preferred.
# The following may not even work.
#
# General Gatling target: Specify CLUSTER_IP, USERS, and SIM_NAME as environment variables. Full output.
run-gatling:
	JAVA_HOME=$(JAVA_HOME) $(GAT) -rsf $(RES_DIR) -sf $(SIM_DIR) -bf $(GAT_DIR)/target/test-classes -s $(SIM_FULL_NAME) -rd "Simulation $(SIM_NAME)" $(GATLING_OPTIONS)

# The following should probably not be used---it starts the job but under most shells
# this process will not be listed by the `jobs` command. This makes it difficult
# to kill the process when you want to end the load test
gatling-music:
	@/bin/sh -c 'CLUSTER_IP=$(INGRESS_IP) USERS=$(USERS) SIM_NAME=ReadMusicSim JAVA_HOME=$(JAVA_HOME) $(GAT) -rsf $(RES_DIR) -sf $(SIM_DIR) -bf $(GAT_DIR)/target/test-classes -s $(SIM_FULL_NAME) -rd "Simulation $(SIM_NAME)" $(GATLING_OPTIONS) $(GAT_SUFFIX)'

# Different approach from gatling-music but the same problems. Probably do not use this.
gatling-user:
	@/bin/sh -c 'CLUSTER_IP=$(INGRESS_IP) USERS=$(USERS) SIM_NAME=ReadUserSim make -e -f k8s.mak run-gatling $(GAT_SUFFIX)'


# ---------------------------------------------------------------------------------------
# Handy bits for exploring the container images... not necessary
image: showcontext
	$(DK) image ls | tee __header | grep $(REGID) > __content
	head -n 1 __header
	cat __content
	rm __content __header
