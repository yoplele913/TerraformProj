variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "ap-northeast-2"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  default     = "ssh2"
}

variable "vpc_id" {
  description = "The VPC ID"
  default     = "vpc-05e81feee5ed30a92"
}

variable "subnet_ids" {
  description = "A list of subnet IDs"
  type        = list(string)
  default     = ["subnet-064efc35e0a88941d", "subnet-05fcfe1de5328dfe3"]
}
