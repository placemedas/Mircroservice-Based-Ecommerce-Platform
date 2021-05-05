# DBStack - DynamoDB schema creation

Using this file, the table stack in dynamodb which are used by the application can be created.

The application has four tables with which the different services interact with, which are as follows:

| Table Name | Primary Key | Functionality |
| -----------|-------------|---------------|
| Customer | customer_id | To store the information about the customer |
| Product | product_id | To store the information about different kinds of products that platform offers |
| Cart | customer_id | To store all the products that a customer adds |
| Logger | customer_id, op_date | To log all the activities that user performs on the platform |
