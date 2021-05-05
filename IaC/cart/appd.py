"""
SFU CMPT 756
Sample application---user service.
"""

# Standard library modules
import logging
import sys
import time

# Installed packages
from flask import Blueprint
from flask import Flask
from flask import request
from flask import Response

import jwt

from prometheus_flask_exporter import PrometheusMetrics

import requests

import simplejson as json

# The application

app = Flask(__name__)

metrics = PrometheusMetrics(app)
metrics.info('app_info', 'User process')

bp = Blueprint('app', __name__)

db = {
    "name": "http://172.17.0.1:30004/api/v1/datastore",
    "endpoint": [
        "read",
        "write",
        "delete",
        "update"
    ]
}


@bp.route('/', methods=['GET'])
@metrics.do_not_track()
def hello_world():
    return ("If you are reading this in a browser, your service is "
            "operational. Switch to curl/Postman/etc to interact using the "
            "other HTTP verbs.")


@bp.route('/health')
@metrics.do_not_track()
def health():
    return Response("", status=200, mimetype="application/json")


@bp.route('/readiness')
@metrics.do_not_track()
def readiness():
    return Response("", status=200, mimetype="application/json")


@bp.route('/customer_id', methods=['GET'])
def get_customer(customer_id):
    print("coming inside get_customer")
    print(customer_id)
    headers = request.headers
    payload = {"objtype": "customer", "objkey": "customer_id"}
    url = db['name'] + '/' + db['endpoint'][0]
    print(url)
    print(payload)
    response = requests.get(url, params=payload, json={"table_key":customer_id})
    print('this is response')
    print(response.json())
    return (response.json())

@bp.route('/cart_id', methods=['GET'])
def get_cart():
    headers = request.headers
    print(headers)
    print("inside get_cart function")
    content = request.get_json()
    cart_id = content['cart_id']
    customer_id = content['customer_id']
    payload = {"objtype": "cart", "objkey": "customer_id"}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, params=payload, json={"table_key":customer_id})
    print(response.json())
    return (response.json())

def get_cart_internal(cart_id):
    headers = request.headers
    print(headers)
    payload = {"objtype": "cart", "objkey": cart_id}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, params=payload, json={"table_key":cart_id})
    print(response.json())
    return (response.json())

@bp.route('/<product_id>', methods=['GET'])
def get_product(product_id):
    headers = request.headers
    payload = {"objtype": "product", "objkey": "product_id"}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, params=payload, json={"table_key":product_id})
    return (response.json())

@bp.route('/', methods=['POST'])
def add_product_to_cart():
    #defining log variables
    service_name = "cart"
    operation_name = "add_to_cart"

    #checking if autorization is present in the headers or not.
    #if 'Authorization' not in headers:
    #    return Response(json.dumps({"error": "missing auth"}),
    #                    status=401,
    #                    mimetype='application/json')

    try:
        content = request.get_json()
        customer_id = content['customer_id']
        context_id = content['context_id']
        product_id = content['product_id']
        product_name = content['product_name']
        cost = content['cost']
        quantity = content['quantity']
        print(customer_id)
        print(context_id)
        print(product_id)
        print(product_name)
        print(cost)
        print(quantity)

    except Exception:
        status_code = "500"
        message = "error reading arguments"
        request_message = request.get_json()
        response_message = json.dumps({"message": message, "status_code":status_code})
        return response_message

    #checking for admin context_id match
    get_customer_response = get_customer(customer_id)
    customer_context_id = get_customer_response['Items'][0]['context_id']

    if customer_context_id != context_id:
        return Response(json.dumps({"Error": "need admin privileges to perform this opeartion."}),
                        status=401,
                        mimetype='application/json')

    url = db['name'] + '/' + db['endpoint'][1]

    response = requests.post(
        url,
        json={"objtype": "cart",
              "objkey": "customer_id",
              "customer_id": customer_id,
              "product_id": product_id,
              "product_name": product_name,
              "cost": cost,
              "quantity": quantity})

    return (response.json())

#remove product from the cart
@bp.route('/', methods=['DELETE'])
def delete_product_from_cart():
    #defining log variables
    service_name = "cart"
    operation_name = "delete_product_from_cart"
    customer_id = None
    content = None

    headers = request.headers

    #reading the input json
    try:
        content = request.get_json()
        # cart_id = content['cart_id']
        customer_id = content['customer_id']
        context_id = content['context_id']
        # product_id = content['product_id']

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "error reading arguments"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return response_message

    #calling the get_customer funtion to get the admins contect id
    try:
        get_customer_response = get_customer(customer_id)
        customer_context_id = get_customer_response['Items'][0]['context_id']
    except Exception:
        #retreiving admin context id falied
        #logging into logger table
        #declaring logger parameters
        status_code = "500"
        message = "error : reteiving admin credentials failed."
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=500,
                        mimetype='application/json')

    #checking for admin privileges
    if customer_context_id != context_id:
        #logging into logger table
        #declaring logger parameters
        status_code = "401"
        message = "error : need admin privileges to perform this opeartion."
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=401,
                        mimetype='application/json')

    try:
        #setting db variables and endpoint
        url = db['name'] + '/' + db['endpoint'][2]

        #deleting the product
        response = requests.delete(
                                    url,
                                    params={"objtype": "cart", 
                                            "objkey": customer_id},
                                    json={"table_id": "customer_id"}
                                    )

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "deleting the product from the product db failed"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling the logger function to write into logger table
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return response_message

    #declaring logger parameters
    # response_message = response.json()
    # status_code = response_message["ResponseMetadata"]["HTTPStatusCode"]
    # message = "product has been deleted from the cart table."
    # request_message = content
    # #calling the logger function to write into logger table
    # # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)

    # #checking if the writing into logger was successful
    # if log_response.json()['status_code'] == 200:
    #     #returning the response of delete product
    #     return (response_message)
    # else:
    #     #error in wrtiting to the logger table
    #     print("Product deleted but writing into logger failed")
    #     return log_response
    return (response.json())

@bp.route('/', methods=['PUT'])
def update_product_on_cart():
    #defining logger parameters
    service_name = "cart"
    operation_name = "update_product_on_cart"
    customer_id = None
    content = None
    headers = request.headers

    #reading input json parameters
    try:
        content = request.get_json()
        customer_id = content['customer_id']
        context_id = content['context_id']
        product_id = content['product_id']
        cost = content['cost']
        quantity = content['quantity']        
        # order_id = content['order_id']

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "error reading arguments"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return response_message

    #calling the get_customer funtion to get the admins contect id
    try:
        get_customer_response = get_customer(customer_id)
        customer_context_id = get_customer_response['Items'][0]['context_id']
    except Exception:
        #retreiving admin context id falied
        #logging into logger table
        #declaring logger parameters
        status_code = "500"
        message = "error : reteiving admin credentials failed."
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=500,
                        mimetype='application/json')


    #checking for admin privileges
    if customer_context_id != context_id:
        #logging into logger table
        #declaring logger parameters
        status_code = "401"
        message = "error : need admin privileges to perform this opeartion."
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=401,
                        mimetype='application/json')

    #in future add the logic to give access if order_id is in order table


    #retreiving product details from the product table
    try:
        check_product = get_product(product_id)
    except Exception:
        #retreiving product falied
        #logging into logger table
        #declaring logger parameters
        status_code = "500"
        message = "error : reteiving product from the product table failed."
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=500,
                        mimetype='application/json')

    #checking if the required product exists or not
    if check_product['Count'] == 0:
        #declaring logger parameters
        response_message = json.dumps({"message": "The requested product is not present in the database.", "status_code":"200"})
        status_code = response_message["status_code"]
        message = response_message["message"]
        request_message = content
        #calling the logger function to write into logger table
        # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=200,
                        mimetype='application/json')
  
    else:
        try:
            #setting db variables and endpoint
            url = db['name'] + '/' + db['endpoint'][3]

            #updating the product table
            response = requests.put(
                url,
                params={"objtype": "cart", "objkey": customer_id},
                json={"cost": cost, "quantity": quantity, "table_id":"customer_id"})

        except Exception:
            #declaring logger parameters
            status_code = "500"
            message = "Updating the product db failed"
            request_message = content
            response_message = json.dumps({"message": message, "status_code":status_code})
            #calling the logger function to write into logger table
            # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
            return response_message

        #declaring logger parameters
        response_message = response.json()
        status_code = response_message["ResponseMetadata"]["HTTPStatusCode"]
        message = "product has been updated."
        request_message = content
        # #calling the logger function to write into logger table
        # # log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)

        # #checking if the writing into logger was successful
        # if log_response.json()['status_code'] == 200:
        #     #returning the response of create product
        #     return (response_message)
        # else:
        #     #error in wrtiting to the logger table
        #     print("Product updated but writing into logger failed")
        #     return log_response
        return response.json()

@bp.route('/list', methods=['GET'])
def list_event():
    """
    List the logs based on customer_id and op_date.
    """
    print("Test check inside the list events") 
    headers = request.headers
    # check header here
    try:
       content = request.get_json()
       customer_id = content["customer_id"]
       beg_date = content["beg_date"]
       end_date = content["end_date"]
    except Exception:
       return json.dumps({"message": "error reading arguments","status_code":"500"})

    payload = {"objtype": "logger", "objkey": 'customer_id'}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, 
                            params=payload,
                            json={"sort_key": "op_date",
                                  "table_key": customer_id,
                                  "beg_date": beg_date,
                                  "end_date": end_date}
                           )
    return (response.json())


# All database calls will have this prefix.  Prometheus metric
# calls will not---they will have route '/metrics'.  This is
# the conventional organization.
app.register_blueprint(bp, url_prefix='/api/v1/cart/')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error("Usage: app.py <service-port>")
        sys.exit(-1)

    p = int(sys.argv[1])
    # Do not set debug=True---that will disable the Prometheus metrics
    app.run(host='0.0.0.0', port=p, threaded=True)
