#
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# in setting up, tearing down and validating your Minikube cluster for working
# with k8s and istio.
#
# This file covers off building the Docker images and optionally running them
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#
# Switch to alternate container registry by setting CREG accordingly.
#
# This script is set up for Github's newly announced (and still beta) container
# registry to side-step DockerHub's throttling of their free accounts.
# If you wish to switch back to DockerHub, CREG=docker.io
#
# TODO: You must run the template processor to fill in the template variables "ZZ-*"
#

CREG=ghcr.io
REGID=kennychakola

DK=docker

# Keep all the logs out of main directory
LOG_DIR=logs

all: product db logger cart customer

deploy: product db logger
	$(DK) run -t --publish 30001:30001 --detach --name product $(CREG)/$(REGID)/team-j-product:e3 | tee product.svc.log
	$(DK) run -t --publish 30003:30003 --detach --name logger $(CREG)/$(REGID)/team-j-logger:e3 | tee logger.svc.log
	$(DK) run -t --publish 30002:30002 --detach --name cart $(CREG)/$(REGID)/team-j-cart:e3 | tee cart.svc.log
	$(DK) run -t --publish 30000:30000 --detach --name customer $(CREG)/$(REGID)/team-j-customer:e3 | tee customer.svc.log
	$(DK) run -t \
		-e AWS_REGION="us-west-2" \
		-e AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY" \
		-e AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY" \
		-e AWS_SESSION_TOKEN="" \
            --publish 30004:30004 --detach --name db $(CREG)/$(REGID)/team-j-cyberdb:e3 | tee db.svc.log

scratch:
	$(DK) stop `$(DK) ps -a -q --filter name="db"` | tee db.stop.log
	$(DK) stop `$(DK) ps -a -q --filter name="logger"` | tee logger.stop.log
	$(DK) stop `$(DK) ps -a -q --filter name="product"` | tee product.stop.log
	$(DK) stop `$(DK) ps -a -q --filter name="cart"` | tee cart.stop.log
	$(DK) stop `$(DK) ps -a -q --filter name="customer"` | tee customer.stop.log

clean:
	rm $(LOG_DIR)/{product,db,logger,cart,customer}.{img,repo,svc}.log

product: $(LOG_DIR)/product.repo.log

logger: $(LOG_DIR)/logger.repo.log

db: $(LOG_DIR)/db.repo.log

cart: $(LOG_DIR)/cart.repo.log

customer: $(LOG_DIR)/customer.repo.log

$(LOG_DIR)/product.repo.log: product/appd.py product/Dockerfile
	cp product/appd.py product/app.py
	$(DK) build -t $(CREG)/$(REGID)/team-j-product:e3 product | tee $(LOG_DIR)/product.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-product:e3 | tee $(LOG_DIR)/product.repo.log

$(LOG_DIR)/logger.repo.log: logger/appd.py logger/Dockerfile
	cp logger/appd.py logger/app.py
	$(DK) build -t $(CREG)/$(REGID)/team-j-logger:e3 logger | tee $(LOG_DIR)/logger.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-logger:e3 | tee $(LOG_DIR)/logger.repo.log

$(LOG_DIR)/db.repo.log: db/Dockerfile
	$(DK) build -t $(CREG)/$(REGID)/team-j-cyberdb:e3 db | tee $(LOG_DIR)/db.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-cyberdb:e3 | tee $(LOG_DIR)/db.repo.log

$(LOG_DIR)/cart.repo.log: cart/appd.py cart/Dockerfile
	cp cart/appd.py cart/app.py
	$(DK) build -t $(CREG)/$(REGID)/team-j-cart:e3 cart | tee $(LOG_DIR)/cart.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-cart:e3 | tee $(LOG_DIR)/cart.repo.log

$(LOG_DIR)/customer.repo.log: customer/appd.py customer/Dockerfile
	cp customer/appd.py customer/app.py
	$(DK) build -t $(CREG)/$(REGID)/team-j-customer:e3 customer | tee $(LOG_DIR)/customer.img.log
	$(DK) push $(CREG)/$(REGID)/team-j-customer:e3 | tee $(LOG_DIR)/customer.repo.log
