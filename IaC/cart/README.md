# Service Name : Cart
### Purpose
This service allows CRUD Operations on the Cart table in Dynamodb. 

### Tables Associated with this Service in DyanamoDB
Communicates with the tables - customer, product, cart, logger

### Operations

1. `Read`- 
Use this operation to perform a read operation from cart table. Associated with GET operation. A sample input message to db can be as follows: 

Code Snippet
~~~
payload = {"objtype": "cart", "objkey": 'customer_id'}
url = db['name'] + '/' + db['endpoint'][0]
response = requests.get(url, 
		    params=payload,
		    json={"table_key": customer_id}
		   )
~~~ 
Request Parameters
~~~
{\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf"\
}
~~~
To test this operation you can use the following command
~~~
 $ make -f api.mak gcart
~~~

2. `Write` - 
Use this operation to write the values into cart table with POST operation. A sample input message to db can be as follows:
	
Code Snippet
~~~
payload = {"objtype": "cart", "objkey": 'customer_id'}
url = db['name'] + '/' + db['endpoint'][1]
response = requests.post(url,
		       json={"objtype": "cart",
			     "objkey": "customer_id",
			     "customer_id": customer_id,
			     "product_id": product_id,
			     "product_name": product_name,
			     "cost": cost,
			     "quantity": quantity}
		      )
~~~
Request Parameters
~~~
{\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf",\
"product_name": "phone", \
"product_id": "7d636347-5b2a-4967-b15c-10fa6068a6d8", \
"cost": 750, \
"quantity": 1, \
"context_id": "abcdefghisdsa8664654646" \
}
~~~
To test this operation you can use the following command
~~~
 $ make -f api.mak ccart
~~~

3. `Update`-
Use this operation to update the values into cart table with PUT operation. A sample input message to db can be as follows:
Code Snippet
~~~
payload = {"objtype": "cart", "objkey": 'customer_id'}
url = db['name'] + '/' + db['endpoint'][3]
response = requests.put(url,
		    params=payload,
		    json={"cost": cost, "quantity": quantity, "table_id":"customer_id"})
~~~
Request Parameters
~~~
{\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf",\
"cost": 7500, \
"quantity": 10, \
}
~~~

To test this operation you can use the following command
~~~
 $ make -f api.mak ucart
~~~

4. `Delete`
Use this operation to update the values into cart table with DELETE operation. A sample input message to db can be as follows:
Code Snippet
~~~
payload = {"objtype": "cart", "objkey": 'customer_id'}
 url = db['name'] + '/' + db['endpoint'][2]
response = requests.delete(url,
		      params=payload,
		      json={"table_id": "customer_id"}
		      )

~~~
Request Parameters
~~~
{\
"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf"\
}
~~~
To test this operation you can use the following command
~~~
 $ make -f api.mak dcart
~~~
  
### Port number exposed for this service : `30002`

