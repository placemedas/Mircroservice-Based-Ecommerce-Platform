"""
SFU CMPT756 Final Project.
This service is used to log the events performed by various services based on customer_id
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
from datetime import datetime

import jwt

from prometheus_flask_exporter import PrometheusMetrics

import requests

import simplejson as json

# The application

app = Flask(__name__)

metrics = PrometheusMetrics(app)
metrics.info('app_info', 'User process')

bp = Blueprint('app', __name__)

#172.17.0.1
#host.docker.internal

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


@bp.route('/create', methods=['POST'])
def create_event():
    """
    Insert every call the service into logger table .
    Each new entry will be tagged to a customer_id and based on timestamp.
    """
    print("Test check inside the create event") 
    try:
        content = request.get_json()
        customer_id = content['customer_id']
        service_name = content['service_name']
        operation_name = content['operation_name']
        status_code = content['status_code']
        message = content['message']
        request_message = content['request_message']
        response_message = content['response_message']
        
    except Exception:
        return json.dumps({"message": "error reading arguments","status_code":"500"})
    url = db['name'] + '/' + db['endpoint'][1]
    response = requests.post(
        url,
        json={"objtype": "logger",
              "objkey":"customer_id",
              "customer_id": customer_id,
              "service_name": service_name,
              "operation_name": operation_name,
              "op_date": datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
              "status_code":status_code,
              "message":message,
              "request_message":request_message,
              "response_message":response_message
              })
    return (response.json())


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
app.register_blueprint(bp, url_prefix='/api/v1/logger/')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error("Usage: app.py <service-port>")
        sys.exit(-1)

    p = int(sys.argv[1])
    # Do not set debug=True---that will disable the Prometheus metrics
    app.run(host='0.0.0.0', port=p, threaded=True)
