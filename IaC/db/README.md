# Service Name : Cyberdb
### Purpose
This service act as a middleware between all other application service and dynamodb. 

### Tables Associated with this Service in DyanamoDB
Interface to all tables - customer, product, cart, logger

### Operations

1. `Read`- 
Use this operation to perform a read operation from any table. Associated with GET operation. A sample input message to db from eg: logger shall be below. 

    ~~~
    payload = {"objtype": "logger", "objkey": 'customer_id'}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, 
                            params=payload,
                            json={"sort_key": "op_date",
                                  "table_key": customer_id,
                                  "beg_date": beg_date,
                                  "end_date": end_date}
                           )
      ~~~
You may use any service to test the db service 
 

2. `Write` - 
Use this operation to write the values into db.Associated with POST operation. A sample input message to db from eg: logger shall be below

      ~~~
            {"objtype": "logger",
              "objkey":"customer_id",
              "customer_id": customer_id,
              "service_name": service_name,
              "operation_name": operation_name,
              "op_date": datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
              "status_code":status_code,
              "message":message,
              "request_message":request_message,
              "response_message":response_message
              }
      ~~~
  
You may use any service to test the db service 

3. `Update`
Use this operation to update the values into db.Associated with PUT operation. A sample input message to db from eg: customer shall be below 
   ~~~
    response = requests.put(
				url,
				params={"objtype": "customer", "objkey": customer_id},
				json={"objtype": "customer",
						"objkey": "customer_id",
						"lname": lname,
						"email": email,
						"fname": fname,
						"address1": address1,
						"address2": address2,
						"password":password,
						"context_id":context_id })
    ~~~

You may use any service to test the db service 

5. `Delete`
Use this operation to update the values into db.Associated with DELETE operation. A sample input message to db from eg: customer shall be below 
   ~~~
				response = requests.delete(url,
								params={"objtype": "customer", "objkey": customer_id})
    ~~~

You may use any service to test the db service
  
  
### Port number exposed for this service : `30004`






