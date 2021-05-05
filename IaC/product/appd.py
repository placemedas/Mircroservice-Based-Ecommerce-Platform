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
    "name": "http://cyberdb:30004/api/v1/datastore",
    "endpoint": [
        "read",
        "write",
        "delete",
        "update"
    ]
}

db_logger = {
    "name": "http://logger:30003/api/v1/logger",
    "endpoint": [
        "create"
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


@bp.route('/<customer_id>', methods=['GET'])
def get_customer(customer_id):
    headers = request.headers
    payload = {"objtype": "customer", "objkey": "customer_id"}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, params=payload, json={"table_key":customer_id})
    return (response.json())


@bp.route('/<product_id>', methods=['GET'])
def get_product(product_id):
    headers = request.headers
    payload = {"objtype": "product", "objkey": "product_id"}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, params=payload, json={"table_key":product_id})
    return (response.json())


def log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message):
    #writing into the logger db
    url_logger = db_logger['name'] + '/' + db_logger['endpoint'][0]
    response_logger = requests.post(
        url_logger,
        json={"customer_id": customer_id,
              "service_name": service_name,
              "operation_name": operation_name,
              "status_code": status_code,
              "message": message,
              "request_message":request_message,
              "response_message":response_message})

    return response_logger


@bp.route('/', methods=['POST'])
def add_product():
    #defining logger parameters
    service_name = "product"
    operation_name = "add_product"
    customer_id = None
    content = None

    #reading the input json
    try:
        content = request.get_json()
        customer_id = content['customer_id']
        context_id = content['context_id']
        product_name = content['product_name']
        cost = content['cost']
        quantity = content['quantity']

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "error reading arguments"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=401,
                        mimetype='application/json')

    try:
        url = db['name'] + '/' + db['endpoint'][1]
        response = requests.post(
            url,
            json={"objtype": "product",
                  "objkey": "product_id",
                  "product_name": product_name,
                  "cost": cost,
                  "quantity": quantity})

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "Writing into the product db failed"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling the logger function to write into logger table
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return response_message

    #declaring logger parameters
    response_message = response.json()
    status_code = response_message["status_code"]
    message = response_message["message"]
    request_message = content
    #calling the logger function to write into logger table
    log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)

    #checking if the writing into logger was successful
    if log_response.json()['status_code'] == 200:
        #returning the response of create product
        return (response_message)
    else:
        #error in wrtiting to the logger table
        print("Product created but writing into logger failed")
        return log_response



@bp.route('/', methods=['DELETE'])
def delete_product():
    #defining log variables
    service_name = "product"
    operation_name = "delete_product"
    customer_id = None
    content = None

    headers = request.headers

    #reading the input json
    try:
        content = request.get_json()
        customer_id = content['customer_id']
        context_id = content['context_id']
        product_id = content['product_id']

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "error reading arguments"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=401,
                        mimetype='application/json')

    try:
        #setting db variables and endpoint
        url = db['name'] + '/' + db['endpoint'][2]

        #deleting the product
        response = requests.delete(
            url,
            params={"objtype": "product", "objkey": product_id})

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "deleting the product from the product db failed"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling the logger function to write into logger table
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return response_message

    #declaring logger parameters
    response_message = response.json()
    status_code = response_message["ResponseMetadata"]["HTTPStatusCode"]
    message = "product has been deleted from the product table."
    request_message = content
    #calling the logger function to write into logger table
    log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)

    #checking if the writing into logger was successful
    if log_response.json()['status_code'] == 200:
        #returning the response of delete product
        return (response_message)
    else:
        #error in wrtiting to the logger table
        print("Product deleted but writing into logger failed")
        return log_response



@bp.route('/', methods=['PUT'])
def update_product():
    #defining logger parameters
    service_name = "product"
    operation_name = "update_product"
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
        order_id = content['order_id']

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "error reading arguments"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=500,
                        mimetype='application/json')

    #checking if the required product exists or not
    if check_product['Count'] == 0:
        #declaring logger parameters
        response_message = json.dumps({"message": "The requested product is not present in the database.", "status_code":"200"})
        status_code = "200"
        message = "The requested product is not present in the database."
        request_message = content
        #calling the logger function to write into logger table
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
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
                params={"objtype": "product", "objkey": product_id},
                json={"cost": cost, "quantity": quantity})

        except Exception:
            #declaring logger parameters
            status_code = "500"
            message = "Updating the product db failed"
            request_message = content
            response_message = json.dumps({"message": message, "status_code":status_code})
            #calling the logger function to write into logger table
            log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
            return response_message

        #declaring logger parameters
        response_message = response.json()
        status_code = response_message["ResponseMetadata"]["HTTPStatusCode"]
        message = "product has been updated."
        request_message = content
        #calling the logger function to write into logger table
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)

        #checking if the writing into logger was successful
        if log_response.json()['status_code'] == 200:
            #returning the response of create product
            return (response_message)
        else:
            #error in wrtiting to the logger table
            print("Product updated but writing into logger failed")
            return log_response





@bp.route('/read_product', methods=['GET'])
def read_product():
    #defining logger parameters
    service_name = "product"
    operation_name = "read_product"
    customer_id = None
    content = None
    headers = request.headers

    #reading input json parameters
    try:
        content = request.get_json()
        customer_id = content['customer_id']
        context_id = content['context_id']
        product_id = content['product_id']

    except Exception:
        #declaring logger parameters
        status_code = "500"
        message = "error reading arguments"
        request_message = content
        response_message = json.dumps({"message": message, "status_code":status_code})
        #calling logger functino to log the error
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return response_message

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
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=500,
                        mimetype='application/json')

    #checking if the required product exists or not
    if check_product['Count'] == 0:
        #declaring logger parameters
        response_message = json.dumps({"message": "The requested product is not present in the database.", "status_code":"200"})
        status_code = "200"
        message = "The requested product is not present in the database."
        request_message = content
        #calling the logger function to write into logger table
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)
        return Response(response_message,
                        status=200,
                        mimetype='application/json')
  
    else:
        #declaring logger parameters
        response_message = check_product
        status_code = response_message["ResponseMetadata"]["HTTPStatusCode"]
        message = "product has been retrieved."
        request_message = content
        #calling the logger function to write into logger table
        log_response = log_writer(customer_id, service_name, operation_name, status_code, message, request_message, response_message)

        #checking if the writing into logger was successful
        if log_response.json()['status_code'] == 200:
            #returning the response of create product
            return (response_message)
        else:
            #error in wrtiting to the logger table
            print("Product retrieved but writing into logger failed")
            return log_response










# All database calls will have this prefix.  Prometheus metric
# calls will not---they will have route '/metrics'.  This is
# the conventional organization.
app.register_blueprint(bp, url_prefix='/api/v1/product/')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error("Usage: app.py <service-port>")
        sys.exit(-1)

    p = int(sys.argv[1])
    # Do not set debug=True---that will disable the Prometheus metrics
    app.run(host='0.0.0.0', port=p, threaded=True)
