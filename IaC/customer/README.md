# Service Name : customer
### Purpose
This service is used to add new customers to Cybershop, update and delete their profiles plus give them a login and logout mechanism to interact with other services like product. 

### Tables Associated with this Service in DyanamoDB
customer, logger

### Operations

1. `add_customer`- 
Use this operation to add a customer to the customer table. 

    ~~~
    {\
    "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d21", \
    "lname": "Barry", \
    "email": "barry_allen@starlabs.com", \
    "fname": "Allen", \
    "address1": "Earth 1", \
    "address2": "Earth-Prime", \
    "password": "flash" \
    }
    ~~~

To test this please use the below 
  
  ~~~
  $ make -f api.mak ccustomer
  ~~~  
 
2. `update_customer`- 
Use this operation to update a customer in the customer table. You need to have admin privilleges to perform this operation. A sample input message to this operation is:

    ~~~
    {\
    "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d", \
     "lname": "Larry", \
     "email": "larry_allen@starlabs.com", \
     "fname": "Allen", \
     "address1": "Earth 1", \
     "address2": "Earth-Prime", \
     "password": "flash" \
}
    
To test this please use the below 
  
  ~~~
  $ make -f api.mak ucustomer
  ~~~  
 
 3. `delete_customer`- 
Use this operation to delete a customer from the customer table. You need to have admin privilleges to perform this operation. A sample input message to this operation is:

    ~~~
   {\
   "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d" \
   }
    

To test this please use the below 
  
  ~~~
  $ make -f api.mak dcustomer
  ~~~  

4. `login`- 
Use this operation to login to application. A sample input message to this operation is:

    ~~~
    {\
    "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf", \
    "password": "abcdefghisdsa8664654646" \
    }
To test this please use the below 
  
  ~~~
  $ make -f api.mak apilogin
  ~~~   

5. `logout`-
Use this operation to logout of application. A sample input message to this operation is:
  
    ~~~
    {\
    "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf", \
    "context_id": "abcdefghisdsa8664654646" \
    }
To test this please use the below
 
  ~~~
  $ make -f api.mak apilogoff
  ~~~
 
### Port number exposed for this service : `30000`
