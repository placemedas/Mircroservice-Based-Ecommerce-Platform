# SFU CMPT 756 project unit test directory

## Creating a unit test environment

To create a unit test environment locally using docker, please perform the following steps:

### 1. Fill in the required changes to the variables in the docker.mak file 

* Put your GitHub register ID in the variable REGID:

  ~~~
  REGID= <your_GitHub_registration_ID>
  ~~~

* Replace AWS credential variables with your AWS credentials:

~~~
AWS_REGION="us-west-2"
AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY"
AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY"
AWS_SESSION_TOKEN="AWS_SESSION_TOKEN" (leave blank if you are using a personnal account)
~~~


### 2. Build images for all the required services

~~~
$ make -f docker.mak all
~~~

### 3. Deploy the sample application

Deploy the sample application for the course:

~~~
$ make -f docker.mak deploy
~~~

Wait until the all the services are deployed.


### 4. List all the containers in the sample application

You can use the below command to examine your running containers:

~~~
$ docker container ls
~~~

### 5. Coverage simulation

Use the api.mak file to run all the services in the local environment.

(Example usage: using api.mak file to create a new customer)
~~~
$ make -f api.mak ccustomer
~~~

### 6. Stopping the containers

Use scratch to stop the containers. (You still need to docker rm to dispose of the containers.)

~~~
$ make -f docker.mak scratch
~~~


