---
title: Level Up Your Serverless Game
author: Lena Fuhrimann
date: 2019-07-25T20:24:44+02:00
---

Serverless has become a buzzword of its own. It has grown tremendously in popularity since AWS released their [FaaS](https://en.wikipedia.org/wiki/Function_as_a_service) product called [Lambda](https://aws.amazon.com/lambda) which allows you to easily run code in many different programming languages on demand. However, it is crucial to say that the term _serverless_ not only includes FaaS products. AWS and many other providers have had serverless services like S3 or DynamoDB in their repertoire for a long time. Basically, serverless means three things:

Firstly, you don't need to provision or manage any underlying infrastructure. The server(s), the operating system and most of the installed software are completely managed for you by the platform.

Secondly, you pay as you go. Many cloud offerings promise dynamic pricing but using serverless services is truly dynamic. With FaaS platforms, you usually pay per unit of time your code runs. You never pay for idle resources and you get billed at an incredibly high granularity and flexibility. Furthermore, many services have really generous free tiers which allow you to try them before you really buy in.

Thirdly, the underlying platform and resources will scale virtually indefinitely. In the case of AWS Lambda or any of its larger competitors, you will never run out of resources and you can have your application scale in and out automatically.

This sounds great, doesn't it? However, like anything in software (and in general), it also comes with its downsides and caveats. The goal of this blog post is to encourage you to try a FaaS platform with a playground application and then gradually level up your game by making your code and configuration more mature and production ready. The described platform is AWS Lambda but the concepts are true for pretty much any FaaS provider and can be used ubiquitously.

Preconditions: Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and the [Go](https://golang.org) programming language. We'll be doing most things manually via the AWS CLI to understand them better. Nevertheless, it is usually recommended to use a higher abstraction framework like [Apex Up](https://github.com/apex/up) or [Serverless](https://serverless.com).

## Level 0 - This is Easy!

Let's get our first piece of code running, shall we? We'll deploy a simple Go function that runs on demand and greets the invoker. If you're not into Go, you can also adapt the code to the programming language of your choice. By now, pretty much anything should run on Lambda.

Let's create our Lambda function. We'll start by creating a Go module:

```shell
$ go mod init
```

Next, we'll create a `main.go` file which contains the AWS Lambda libraries and our simple function:

```go
package main

import (
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(handler)
}

type Event struct {
	Name string `json:"name"`
}

type Response struct {
	Message string `json:"message"`
}

func handler(evt Event) (Response, error) {
	return Response{Message: fmt.Sprintf("Greetings, %s", evt.Name)}, nil
}
```

This simple function takes an input (the name of the invoker as a string) and greets them. Run the following command to build your app for the Lambda platform:

```shell
$ GOOS=linux go build -o main
```

Next, we'll have to package our executable into a ZIP archive to be able to upload it to Lambda:

```shell
$ zip bin.zip main
```

Great. Now we can create our function in AWS:

```shell
$ aws iam create-role --role-name greeter-exec --assume-role-policy-document '{ "Version": "2012-10-17", "Statement": [ { "Action": "sts:AssumeRole", "Effect": "Allow", "Principal": { "Service": "lambda.amazonaws.com"  }  }  ]  }'
$ aws iam attach-role-policy --role-name greeter-exec --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
$ aws lambda create-function --function-name greeter --runtime go1.x --zip-file fileb://bin.zip --handler main --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/greeter-exec"
```

The first command creates a new role in IAM and allows the Lambda service to assume it. By default, all requests are blocked in AWS so we have to enable that. The second command attaches an existing policy to that role we have created. This allows the role to write logs in CloudWatch, the logging aggregation service from AWS. The third command creates the actual Lambda function.

We can now invoke our function to test it:

```shell
$ aws lambda invoke --function-name greeter --payload '{"name":"Garfield"}' output.txt
```

If we then look at the `output.txt` file, we'll see that Garfield has been greeted correctly.

## Level 1 - No Cold Starts!
