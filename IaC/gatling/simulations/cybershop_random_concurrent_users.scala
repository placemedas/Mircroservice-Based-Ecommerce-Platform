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

  def randomString(length: Int): String = {
        rnd.alphanumeric.filter(_.isLetter).take(length).mkString
        }

  
  val igw = "a1e1a621e6ab3415698f1176e1a20606-1566962564.us-west-2.elb.amazonaws.com"

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

    def createproduct = { 
      feed(y)
      exec(http("Request Name = Create Product POST")
        .post("http://"+igw+":80/api/v1/product/")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",
          "product_name": "${new_product_name}",
          "cost": "${cost}",
          "quantity": "${quantity}",
          "context_id": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjdXN0b21lcl9pZCI6IjU2N2RjZTdmLWI3YjQtNGVmZC1iNzVlLTJiOTg1OTJhYmU2ZCIsInRpbWUiOjE2MTc0OTY2MjAuNTM0MzkzOH0.94ZQWznlV3I9w41gSu8cbXeRW2POw0BwYggnajDeZ6w"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..product_id").ofType[String].saveAs("product_id")))
 //       .exec({session=>println(session("product_id").as[String])
 //         session})

        
        }

    def updateproduct = { 
      feed(y)
      exec(http("Request Name = Update Product PUT")
        .put("http://"+igw+":80/api/v1/product/")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "567dce7f-b7b4-4efd-b75e-2b98592abe6d",
          "cost": "200",
          "quantity": "${new_quantity}",
          "context_id": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjdXN0b21lcl9pZCI6IjU2N2RjZTdmLWI3YjQtNGVmZC1iNzVlLTJiOTg1OTJhYmU2ZCIsInRpbWUiOjE2MTc0OTY2MjAuNTM0MzkzOH0.94ZQWznlV3I9w41gSu8cbXeRW2POw0BwYggnajDeZ6w",
          "product_id": "${product_id}",
          "order_id":"6079f4a1-c165-4d25-ad44"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200)))
        }

}
 
  object CreateCustomerLogin {


    def createcustomer = { 
      
      feed(y)
      exec(http("Request Name = Create Customer POST")
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
      exec(http("Request Name = Customer Login PUT")
        .put("http://"+igw+":80/api/v1/customer/login")
        .header("content-type" , "application/json")
        .body(StringBody(string = """{"customer_id": "${customer_id}",
          "password": "${password_id}"}"""))
        .check(status.not(404), status.not(500))
        .check(status.is(200))
        .check(jsonPath("$..context_id").ofType[String].saveAs("context_id"))) 
//        .exec({session=>println(session("context_id").as[String])
//          session})
//        .exec({session=>println(session("product_id").as[String])
//          session})

            }
   
    
    def updatecustomer = { 
      
      feed(y)
      exec(http("Request Name = Update Customer PUT")
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
      exec(http("Request Name = Create Cart POST")
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

    def customerlogout = {
      feed(y)
      exec(http("Request Name = Customer Logoff PUT")
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
 
  // Load Test
  val LoadTestScenario = scenario("Your Scenario Name is => LoadTest")
              .forever()
	      {	
              feed(y)
              .exec(CreateCustomerLogin.createcustomer)
              .pause(10)
              .exec(CreateCustomerLogin.customerlogin)
              .pause(10)
              .exec(CreateProductUpdate.createproduct)
              .pause(10)
              .exec(CreateProductUpdate.updateproduct)
              .pause(10)

//              .exec(CreateCustomerLogin.updatecustomer)
              .exec(CreateCustomerLogin.createcart)
              .pause(10)
              .exec(CreateCustomerLogin.customerlogout)
              .pause(10)
              }
  // Uncomment the next line to run a Load Test for 30 minutes
//    setUp(LoadTestScenario.inject(atOnceUsers(1))).maxDuration(1 minute)
  setUp(LoadTestScenario.inject(  rampConcurrentUsers(0) to(100) during(20 seconds )))
.maxDuration(4 minute)
//  constantConcurrentUsers(10) during(10 seconds)))
}

