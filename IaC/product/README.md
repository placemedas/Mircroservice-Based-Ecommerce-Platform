# Service Name : product
### Purpose
This service is used to add, update and delete products from the product table. 

### Tables Associated with this Service in DyanamoDB
product, customer

### Operations

1. `add_product`- 
Use this operation to add a product to the product table. You need to have admin privilleges to perform this operation. A sample input message to this operation is:

    ~~~
    {\
    "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf", \
    "product_name": "phone", \
    "cost": 750, \
    "quantity": 1, \
    "context_id": "abcdefghisdsa8664654646" \
    }
    ~~~

To test this please use the below 
  
  ~~~
  $ make -f api.mak cproduct
  ~~~  
 
2. `update_product`- 
Use this operation to update a product in the product table. You need to have admin privilleges to perform this operation. A sample input message to this operation is:

    ~~~
    {\
    "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf", \
    "product_id": "7d636347-5b2a-4967-b15c-10fa6068a6d8", \
    "cost": 750, \
    "quantity": 1, \
    "context_id": "abcdefghisdsa8664654646", \
    "order_id":"6079f4a1-c165-4d25-ad44"
    }
    ~~~

To test this please use the below 
  
  ~~~
  $ make -f api.mak uproduct
  ~~~  
 
 3. `delete_product`- 
Use this operation to delete a product from the product table. You need to have admin privilleges to perform this operation. A sample input message to this operation is:

    ~~~
    {\
    "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592a56mdsf", \
    "context_id": "abcdefghisdsa8664654646" \
    "product_id": "7d636347-5b2a-4967-b15c-10fa6068a6d8" \
    }
    ~~~

To test this please use the below 
  
  ~~~
  $ make -f api.mak dproduct
  ~~~  
  
### Port number exposed for this service : `30001`



