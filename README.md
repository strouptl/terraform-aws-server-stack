# AWS Server Stack Module
A Terraform/OpenTofu module for creating a load balanced server stack with autoscaling support in AWS

## Example Usage
Insert the following into your main.tf file:

    terraform {
      required_providers {
        aws = { 
          source  = "hashicorp/aws"
          version = "~> 5.17"
        }   
      }
      required_version = ">= 1.2.0"
    }
    
    provider "aws" {
      region  = "us-east-1"
    }
    
    module "example-load-balancer" {
      source = "git@github.com:strouptl/terraform-aws-server-stack.git?ref=0.1.1"
      name = "example"
      desired_capacity = 2
      min_size = 1
      max_size = 4
      log_bucket_name = "example-load-balancer-logs"
      launch_template_id = "lt-0123456789"
      ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/123-abc-456-def-789-ghi"
      security_group_ids = ["sg-123abc456def"]
    }

## Steps
1. Create your Security Groups
   - Recommended: use the [aws-security-groups](https://github.com/strouptl/terraform-aws-security-groups) module
   - See "Example Usage: aws-security-groups" below for details
3. Configure your desired EC2 instance, and then create an Image and a Launch Template for that image.
4. Create an SSL certificate for your desired domain name
5. Plug your Security Groups, Launch Template, and SSL certificate into your server stack module as shown above


## Additional Options
1. vpc_id (defaults to the default VPC)
2. subnet_ids (defaults to all public subnets in the selected VPC)


## Example Usage: aws-security-groups

    terraform {
      required_providers {
        aws = { 
          source  = "hashicorp/aws"
          version = "~> 5.17"
        }   
      }
      required_version = ">= 1.2.0"
    }
    
    provider "aws" {
      region  = "us-east-1"
    }
  
    module "example_security_groups" {
      source = "git@github.com:strouptl/terraform-aws-security-groups.git?ref=0.1.0"
      name = "example"
    }
    
    # Server Stack
    module "example-load-balancer" {
      source = "git@github.com:strouptl/terraform-aws-server-stack.git?ref=0.1.1"
      name = "example"
      desired_capacity = 2
      min_size = 1
      max_size = 4
      log_bucket_name = "example-load-balancer-logs"
      launch_template_id = "lt-0123456789"
      ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/123-abc-456-def-789-ghi"
      security_group_ids = [module.example_security_groups.load_balancers.id]
    }
