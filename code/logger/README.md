# Service Name : Logger
### Purpose
This service is used to capture the events that happens across other services with in the application

### Tables Associated with this Service in DyanamoDB
Logger

### Operations

1. `Create(clogger)`- 
Use this operation to log an event into the logger table. A sample input message shall be below. 

  ~~~
  {\
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
~~~

To test this please use the below 
  
  ~~~
  $ make -f api.mak clogger
  ~~~  

2. `Query(rlogger)` - 
Use this operation to query the logs based on user_id and timestamp. A sample input message shall be below.

  ~~~
  {\
	"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
	"beg_date": "2021-03-20T22:35:06", \
	"end_date": "2021-03-20T23:37:28" \
  }
  ~~~
  
  To test this please use the below 
  
  ~~~
  $ make -f api.mak rlogger
  ~~~  
  
### Port number exposed for this service : `30003`
