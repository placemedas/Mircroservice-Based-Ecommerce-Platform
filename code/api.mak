#
# Front-end to bring some sanity to the litany of tools and switches
# in calling the sample application from the command line.
#
# This file covers off driving the API independent of where the cluster is
# running.
# Be sure to set your context appropriately for the log monitor.
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#


KC=kubectl
CURL=curl

# Keep all the logs out of main directory
LOG_DIR=logs

# look these up with 'make ls'
# You need to specify the container because istio injects side-car container
# into each pod.
# customer: service1; s2: service2; db: cyberdb
PODLOGGER=pod/customer-8557865b4b-jnwrj
PODCONT=service1

# show deploy and pods in current ns; svc of cyber ns
ls: showcontext
	$(KC) get gw,deployments,pods
	$(KC) -n $(NS) get svc

logs:
	$(KC) logs $(PODLOGGER) -c $(PODCONT)

#
# Replace this with the external IP/DNS name of your cluster
#
# In all cases, look up the external IP of the istio-ingressgateway LoadBalancer service
# You can use either 'make -f eks.m extern' or 'make -f mk.m extern' or
# directly 'kubectl -n istio-system get service istio-ingressgateway'
#
#IGW=172.16.199.128:31413
#IGW=10.96.57.211:80
#IGW=a98fea4076a3a4627bf939196800825d-1772569567.us-west-2.elb.amazonaws.com:80
IGW=localhost


## Body for PRODUCT opertations
# Add Product
ADD_PRODUCT = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"product_name": "phone", \
"cost": 750, \
"quantity": 1, \
"context_id": "abcdefghijk123456789" \
}

BODY_UID= { \
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"password": "flash" \
}


ADD_CUSTOMER = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d21", \
"lname": "Barry", \
"email": "barry_allen@starlabs.com", \
"fname": "Allen", \
"address1": "Earth 1", \
"address2": "Earth-Prime", \
"password": "flash" \
}


UPDATE_CUSTOMER = {\
"customer_id": "qw567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"lname": "Larry", \
"email": "larry_allen@starlabs.com", \
"fname": "Allen", \
"address1": "Earth 1", \
"address2": "Earth-Prime", \
"password": "flash" \
}

DELETE_CUSTOMER = {\
"customer_id": "qw567dce7f-b7b4-4efd-b75e-2b98592abe6d" \
}
#Update Product
UPDATE_PRODUCT = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"product_id": "7d636347-5b2a-4967-b15c-10fa6068a6d8", \
"cost": 2000, \
"quantity": 20, \
"context_id": "abcdefghijk123456789", \
"order_id":"6079f4a1-c165-4d25-ad44" \
}


#Read Product
READ_PRODUCT = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"product_id": "143e143f-f47d-4c29-b523-0d3a1f58c09d", \
"context_id": "abcdefghijk123456789" \
}


#Delete Product
DELETE_PRODUCT = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",\
"context_id": "abcdefghijk123456789",\
"product_id": "7d636347-5b2a-4967-b15c-10fa6068a6d8" \
}

### stock body & fragment for API requests
## Body for LOGGER opertations
# Add Logs
ADD_LOGGER= {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",\
"service_name": "product",\
"operation_name": "add",\
"status_code": 200,\
"message": "New product created",\
"request_message": { \
	   "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",\
	   "product_name": "phone",\
	   "cost": 750,\
	   "quantity": 1,\
	   "context_id": "abcdefghijk123456789"\
	   },\
"response_message": {\
		"product_id": "6079f4a1-c165-4d25-ad44-4cbc7c196d2d", \
		"message": "Product successfully created", \
		"status_code": 200 \
	} \
}

#Get Logs
GET_LOGGER= {\
	"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
	"beg_date": "2021-03-20T22:35:06", \
	"end_date": "2021-03-20T23:37:28" \
}

## Body for CART opertations
# Add Product
ADD_PRODUCT_TO_CART = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"product_id": "7d636347-5b2a-4967-b15c-10fa6068a6d8", \
"product_name": "phone", \
"cost": "100", \
"quantity": "1", \
"context_id": "abcdefghijk123456789" \
}

#Update Product
UPDATE_PRODUCT_IN_CART = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"product_id": "7d636347-5b2a-4967-b15c-10fa6068a6d8", \
"cost": 2000, \
"quantity": 20, \
"context_id": "abcdefghijk123456789", \
"order_id":"6079f4a1-c165-4d25-ad44" \
}

#Delete Product
DELETE_PRODUCT_FROM_CART = {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",\
"context_id": "abcdefghijk123456789",\
}

### stock body & fragment for API requests
## Body for LOGGER opertations
# Add Logs
ADD_LOGGER= {\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",\
"service_name": "product",\
"operation_name": "add",\
"status_code": 200,\
"message": "New product created",\
"request_message": { \
       "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",\
       "product_name": "phone",\
       "cost": 750,\
       "quantity": 1,\
       "context_id": "abcdefghijk123456789"\
       },\
"response_message": {\
        "product_id": "6079f4a1-c165-4d25-ad44-4cbc7c196d2d", \
        "message": "Product successfully created", \
        "status_code": 200 \
    } \
}

# this is a token for ???
TOKEN=Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiMDI3Yzk5ZWYtM2UxMi00ZmM5LWFhYzgtMTcyZjg3N2MyZDI0IiwidGltZSI6MTYwMTA3NDY0NC44MTIxNjg2fQ.hR5Gbw5t2VMpLcj8yDz1B6tcWsWCFNiHB_KHpvQVNls
BODY_TOKEN={ \
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
"context_id": "abcdefghijk123456789" \
}


# CUSTOMER
#Create
ccustomer:
	echo curl --location --request POST 'http://$(IGW):30000/api/v1/customer/' --header 'Content-Type: application/json' --data-raw '$(ADD_CUSTOMER)' > $(LOG_DIR)/ccustomer.out
	$(CURL) --location --request POST 'http://$(IGW):30000/api/v1/customer/' --header 'Content-Type: application/json' --data-raw '$(ADD_CUSTOMER)' | tee -a $(LOG_DIR)/ccustomer.out

ucustomer:
	echo curl --location --request PUT 'http://$(IGW):30000/api/v1/customer/' --header 'Content-Type: application/json' --data-raw '$(UPDATE_CUSTOMER)' > $(LOG_DIR)/ucustomer.out
	$(CURL) --location --request PUT 'http://$(IGW):30000/api/v1/customer/' --header 'Content-Type: application/json' --data-raw '$(UPDATE_CUSTOMER)' | tee -a $(LOG_DIR)/ucustomer.out

#Delete
dcustomer:
	echo curl --location --request DELETE 'http://$(IGW):30000/api/v1/customer/' --header 'Content-Type: application/json' --data-raw '$(DELETE_CUSTOMER)' > $(LOG_DIR)/dcustomer.out
	$(CURL) --location --request DELETE 'http://$(IGW):30000/api/v1/customer/' --header 'Content-Type: application/json' --data-raw '$(DELETE_CUSTOMER)' | tee -a $(LOG_DIR)/dcustomer.out



# PUT is used for login/logoff too
apilogin:
	echo curl --location --request PUT 'http://$(IGW):30000/api/v1/customer/login' --header 'Content-Type: application/json' --data-raw '$(BODY_UID)' > $(LOG_DIR)/apilogin.out
	$(CURL) --location --request PUT 'http://$(IGW):30000/api/v1/customer/login' --header 'Content-Type: application/json' --data-raw '$(BODY_UID)' | tee -a $(LOG_DIR)/apilogin.out

apilogoff:
	echo curl --location --request PUT 'http://$(IGW):30000/api/v1/customer/logoff' --header 'Content-Type: application/json' --data-raw '$(BODY_TOKEN)' > $(LOG_DIR)/apilogoff.out
	$(CURL) --location --request PUT 'http://$(IGW):30000/api/v1/customer/logoff' --header 'Content-Type: application/json' --data-raw '$(BODY_TOKEN)' | tee -a $(LOG_DIR)/apilogoff.out





# PRODUCT
#Create
cproduct:
	echo curl --location --request POST 'http://$(IGW):30001/api/v1/product/' --header 'Content-Type: application/json' --data-raw '$(ADD_PRODUCT)' > $(LOG_DIR)/cproduct.out
	$(CURL) --location --request POST 'http://$(IGW):30001/api/v1/product/' --header 'Content-Type: application/json' --data-raw '$(ADD_PRODUCT)' | tee -a $(LOG_DIR)/cproduct.out

#Read
rproduct:
	echo curl --location --request GET 'http://$(IGW):30001/api/v1/product/read_product' --header 'Content-Type: application/json' --data-raw '$(READ_PRODUCT)' > $(LOG_DIR)/rproduct.out
	$(CURL) --location --request GET 'http://$(IGW):30001/api/v1/product/read_product' --header 'Content-Type: application/json' --data-raw '$(READ_PRODUCT)' | tee -a $(LOG_DIR)/rproduct.out

#Update
uproduct:
	echo curl --location --request PUT 'http://$(IGW):30001/api/v1/product/' --header 'Content-Type: application/json' --data-raw '$(UPDATE_PRODUCT)' > $(LOG_DIR)/uproduct.out
	$(CURL) --location --request PUT 'http://$(IGW):30001/api/v1/product/' --header 'Content-Type: application/json' --data-raw '$(UPDATE_PRODUCT)' | tee -a $(LOG_DIR)/uproduct.out

#Delete
dproduct:
	echo curl --location --request DELETE 'http://$(IGW):30001/api/v1/product/' --header 'Content-Type: application/json' --data-raw '$(DELETE_PRODUCT)' > $(LOG_DIR)/dproduct.out
	$(CURL) --location --request DELETE 'http://$(IGW):30001/api/v1/product/' --header 'Content-Type: application/json' --data-raw '$(DELETE_PRODUCT)' | tee -a $(LOG_DIR)/dproduct.out


#LOGGER(Create,Read)
clogger:
	echo curl --location --request POST 'http://$(IGW):30003/api/v1/logger/' --header 'Content-Type: application/json' --data-raw '$(ADD_LOGGER)' > $(LOG_DIR)/clogger.out
	$(CURL) --location --request POST 'http://$(IGW):30003/api/v1/logger/' --header 'Content-Type: application/json' --data-raw '$(ADD_LOGGER)' | tee -a $(LOG_DIR)/clogger.out

rlogger:
	echo curl --location --request GET 'http://$(IGW):30003/api/v1/logger' --header 'Content-Type: application/json' --data-raw '$(GET_LOGGER)' > $(LOG_DIR)/rlogger.out
	$(CURL) --location --request GET 'http://$(IGW):30003/api/v1/logger' --header 'Content-Type: application/json' --data-raw '$(GET_LOGGER)' | tee -a $(LOG_DIR)/rlogger.out

showcontext:
	$(KC) config get-contexts

#COMMANDS FOR CART OERATIONS
#Create
ccart:
	echo curl --location --request POST 'http://$(IGW):30002/api/v1/cart/' --header 'Content-Type: application/json' --data-raw '$(ADD_PRODUCT_TO_CART)' > $(LOG_DIR)/ccart.out
	$(CURL) --location --request POST 'http://$(IGW):30002/api/v1/cart/' --header 'Content-Type: application/json' --data-raw '$(ADD_PRODUCT_TO_CART)' | tee -a $(LOG_DIR)/ccart.out

#Read
ucart:
	echo curl --location --request PUT 'http://$(IGW):30002/api/v1/cart/' --header 'Content-Type: application/json' --data-raw '$(UPDATE_PRODUCT_IN_CART)' > $(LOG_DIR)/ucart.out
	$(CURL) --location --request PUT 'http://$(IGW):30002/api/v1/cart/' --header 'Content-Type: application/json' --data-raw '$(UPDATE_PRODUCT_IN_CART)' | tee -a $(LOG_DIR)/ucart.out

#Delete
dcart:
	echo curl --location --request DELETE 'http://$(IGW):30002/api/v1/cart/' --header 'Content-Type: application/json' --data-raw '$(DELETE_PRODUCT_FROM_CART)' > $(LOG_DIR)/dcart.out
	$(CURL) --location --request DELETE 'http://$(IGW):30002/api/v1/cart/' --header 'Content-Type: application/json' --data-raw '$(DELETE_PRODUCT_FROM_CART)' | tee -a $(LOG_DIR)/dcart.out

