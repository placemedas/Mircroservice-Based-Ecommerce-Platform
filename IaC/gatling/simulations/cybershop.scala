/*
 * Copyright 2011-2020 GatlingCorp (https://gatling.io)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package cybershop

import scala.concurrent.duration.DurationInt
import scala.concurrent.duration._
import scala.util.Random
import io.gatling.core.Predef._
import io.gatling.http.Predef._

class CyberShopTest extends Simulation {
  
  val rnd = new Random()

  val customer_feeder2 = csv("customer.csv").random

  val customer_feeder4 = csv("customer2.csv").circular

  def randomString(length: Int): String = {
        rnd.alphanumeric.filter(_.isLetter).take(length).mkString
        }

  
  val igw = "ac8438926b48342dda34c504419dedce-738312923.us-west-2.elb.amazonaws.com"

  val y = Iterator.continually(
    Map(
      
      "product_name" -> (Random.nextInt(99)),
      "new_product_name" -> (randomString(7)),
      "cost" -> (Random.nextInt(99)),
      "quantity" -> (Random.nextInt(99)),
      "new_quantity" -> (Random.nextInt(99)),
      "password_id" -> (randomString(10)),
      "customer_id" -> (randomString(16)),
      "IGW" -> (igw)
    ))


  /* ******* Product ******* */

  object CreateProductUpdate {

    def adminlogin = {
      exec(http("Request Name = Customer Login PUT (3)")
        .put("http://"+igw+":80/api/v1/customer/login")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",
          "password": "flash"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
    }

    def createproduct = { 
      feed(y)
      exec(http("Request Name = Create Product POST (3)")
        .post("http://"+igw+":80/api/v1/product/")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",
          "product_name": "${new_product_name}",
          "cost": "${cost}",
          "quantity": "${quantity}",
          "context_id": "abcdefghijk123456789"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..product_id").ofType[String].saveAs("product_id")))
        
        }

    def updateproduct = { 
      feed(y)
      exec(http("Request Name = Update Product PUT (3)")
        .put("http://"+igw+":80/api/v1/product/")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",
          "cost": "200",
          "quantity": "${new_quantity}",
          "context_id": "abcdefghijk123456789",
          "product_id": "${product_id}",
          "order_id":"6079f4a1-c165-4d25-ad44"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
        }

    def adminlogout = {
      feed(y)
      exec(http("Request Name = Customer Logoff PUT (3)")
        .put("http://"+igw+":80/api/v1/customer/logoff")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{
          "customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",
          "context_id": "abcdefghijk123456789" 
        }"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
            }

}
 
  object CreateCustomerLogin {


    def createcustomer = { 
      
      feed(y)
      exec(http("Request Name = Create Customer POST (1)")
        .post("http://"+igw+":80/api/v1/customer/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{"customer_id":"${customer_id}",
          "lname": "Barry",
          "email": "Barry_allen@starlabs.com",
          "fname": "Allen",
          "address1": "Earth 2",
          "address2": "Earth",
          "password": "${password_id}"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..customer_id").ofType[String].saveAs("customer_id")))
            }

    def customerlogin = {
      feed(y)
      exec(http("Request Name = Customer Login PUT (1)")
        .put("http://"+igw+":80/api/v1/customer/login")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "${customer_id}",
          "password": "${password_id}"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..context_id").ofType[String].saveAs("context_id"))) 
        /*.exec({session=>println(session("context_id").as[String])
          session})
        .exec({session=>println(session("product_id").as[String])
          session})*/

            }
   
    
    def updatecustomer = { 
      
      feed(y)
      exec(http("Request Name = Update Customer PUT (1)")
        .put("http://"+igw+":80/api/v1/customer/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{"customer_id":"${customer_id}",
          "lname": "Barry",
          "email": "Barry_allen@starlabs.com",
          "fname": "Allen",
          "address1": "Vancouver",
          "address2": "BC",
          "password": "${password_id}"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
            }

    def createcart = { 
      feed(y)
      exec(http("Request Name = Create Cart POST (1)")
        .post("http://"+igw+":80/api/v1/cart/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{
        "customer_id": "${customer_id}",
        "product_id": "${product_id}",
        "product_name": "${new_product_name}",
        "cost": "200",
        "quantity": "${new_quantity}", 
        "context_id": "${context_id}"} 
          """))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..customer_id").ofType[String].saveAs("customer_id")))

    }

    def updatecart = { 
      feed(y)
      exec(http("Request Name = Update Cart PUT (1)")
        .put("http://"+igw+":80/api/v1/cart/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{
          "customer_id": "${customer_id}",
          "product_id": "{product_id}",
          "cost": 200,
          "quantity": 1,
          "context_id": "${context_id}",
          "order_id":"6079f4a1-c165-4d25-ad44"} 
          """))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))

    }

    def deletecart = { 
      feed(y)
      exec(http("Request Name = Delete Cart DELETE (1)")
        .delete("http://"+igw+":80/api/v1/cart/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{
          "customer_id": "${customer_id}",
          "context_id": "${context_id}" 
          """))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))

    }

    def customerlogout = {
      feed(y)
      exec(http("Request Name = Customer Logoff PUT (1)")
        .put("http://"+igw+":80/api/v1/customer/logoff")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{
          "customer_id": "${customer_id}",
          "context_id": "${context_id}" 
        }"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
            }

  }


  object CartOperation {

    def cuslogin = {
      feed(customer_feeder4)
      exec(http("Request Name = Customer Login PUT (4)")
        .put("http://"+igw+":80/api/v1/customer/login")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "${customer_id}",
          "password": "${password_id}"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..context_id").ofType[String].saveAs("context_id"))) 
        /*.exec({session=>println(session("context_id").as[String])
          session})
        .exec({session=>println(session("product_id").as[String])
          session})*/

            }
   
    
    def ccart = { 

      feed(customer_feeder4)
      exec(http("Request Name = Create Cart POST (4)")
        .post("http://"+igw+":80/api/v1/cart/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{
        "customer_id": "${customer_id}",
        "product_id": "${product_id}",
        "product_name": "${product_name}",
        "cost": "200",
        "quantity": "2", 
        "context_id": "${context_id}"} 
          """))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..customer_id").ofType[String].saveAs("customer_id")))
    }

    def ucart = { 
      feed(customer_feeder4)
      exec(http("Request Name = Update Cart PUT (4)")
        .put("http://"+igw+":80/api/v1/cart/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{
          "customer_id": "${customer_id}",
          "product_id": "{product_id}",
          "cost": 200,
          "quantity": 1,
          "context_id": "${context_id}",
          "order_id":"6079f4a1-c165-4d25-ad44"} 
          """))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
    }

    def delcart = { 
      feed(customer_feeder4)
      exec(http("Request Name = Delete Cart DELETE (4)")
        .delete("http://"+igw+":80/api/v1/cart/")
        .header("content-type" , "application/json")

        .body(StringBody(string = """{
          "customer_id": "${customer_id}",
          "context_id": "${context_id}"} 
          """))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
//.exec({session=>println(session("customer_id").as[String]+"delcart")
//          session})
    }

    def cuslogout = {
      feed(customer_feeder4)
      exec(http("Request Name = Customer Logoff PUT (4)")
        .put("http://"+igw+":80/api/v1/customer/logoff")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{
          "customer_id": "${customer_id}",
          "context_id": "${context_id}" 
        }"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
            }

  }
 
 object ReadProduct {

    def clogin = {
      feed(customer_feeder2)
      exec(http("Request Name = Customer Login PUT (2)")
        .put("http://"+igw+":80/api/v1/customer/login")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "${customer_id}",
          "password": "${password_id}"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..context_id").ofType[String].saveAs("context_id"))) 
        /*.exec({session=>println(session("context_id").as[String])
          session})
        .exec({session=>println(session("product_id").as[String])
          session})*/
            }

    def rproduct = { 
      feed(customer_feeder2)
      exec(http("Request Name = Read Product GET (2)")
        .get("http://"+igw+":80/api/v1/product/read_product")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{
			"customer_id": "${customer_id}", 
			"product_id": "${product_id}", 
			"context_id": "${context_id}"
	}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
       )
        
            }


    def clogout = {
      feed(customer_feeder2)
      exec(http("Request Name = Customer Logoff PUT (2)")
        .put("http://"+igw+":80/api/v1/customer/logoff")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{
          "customer_id": "${customer_id}",
          "context_id": "${context_id}" 
        }"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
        /*.exec({session=>println(session("context_id").as[String])
          session})*/
            }

  }

  // Load Test

  val LoadTestScenario4 = scenario("Your Scenario Name is => LoadTest4")
              .forever(){
              feed(customer_feeder4)
              .exec(CartOperation.cuslogin)
              .exec(CartOperation.ccart)
              .exec(CartOperation.ucart)
              .exec(CartOperation.delcart)
              .exec(CartOperation.cuslogout)
              }

val LoadTestScenario0 = scenario("Your Scenario Name is => LoadTest0")
              .forever(){
              feed(y)
              .exec(CreateProductUpdate.createproduct)
              .exec(CreateProductUpdate.updateproduct)
              .exec(CreateCustomerLogin.createcustomer)
              .exec(CreateCustomerLogin.customerlogin)
              .exec(CreateCustomerLogin.updatecustomer)
              .exec(CreateCustomerLogin.createcart)
              .exec(CreateCustomerLogin.updatecart)
              .exec(CreateCustomerLogin.deletecart)
              .exec(CreateCustomerLogin.customerlogout)
              }

val LoadTestScenario3 = scenario("Your Scenario Name is => LoadTest3")
              .forever(){
              feed(y)
              .exec(CreateProductUpdate.createproduct)
              .pause(5)
              .exec(CreateProductUpdate.updateproduct)
              .pause(5)
              }


val LoadTestScenario2 = scenario("Your Scenario Name is => LoadTest2")
              .forever(){
              feed(customer_feeder2)
              .exec(ReadProduct.clogin)
              .pause(3)
              .exec(ReadProduct.rproduct)
              .pause(3)
              .exec(ReadProduct.clogout)
              }


  val LoadTestScenario1 = scenario("Your Scenario Name is => LoadTest1")
              .forever(){
              feed(y)
              .exec(CreateCustomerLogin.createcustomer)
              .exec(CreateCustomerLogin.customerlogin)
              .exec(CreateCustomerLogin.updatecustomer)
              .exec(CreateCustomerLogin.customerlogout)
              }


// Test all 4 scenarios with constant concurrent users
  setUp(LoadTestScenario1.inject(constantConcurrentUsers(10).during(20.seconds)),
        LoadTestScenario2.inject(constantConcurrentUsers(50).during(50.seconds)),
        LoadTestScenario3.inject(constantConcurrentUsers(20).during(30.seconds)),
        LoadTestScenario4.inject(constantConcurrentUsers(20).during(30.seconds))).maxDuration(30 minute)

// Test all 4 scenarios with ramp concurrent users
/*  setUp(LoadTestScenario1.inject(rampConcurrentUsers(0) to(10) during(50 seconds))),
        LoadTestScenario2.inject(rampConcurrentUsers(0) to(10) during(50 seconds))),
        LoadTestScenario3.inject(rampConcurrentUsers(0) to(10) during(50 seconds))),
        LoadTestScenario4.inject(rampConcurrentUsers(0) to(10) during(50 seconds))).maxDuration(30 minute) */

}
