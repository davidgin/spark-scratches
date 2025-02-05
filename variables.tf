variable "aws_region" {
  default = "us-east-1"
}

variable "emr_cluster_name" {
  default = "elastic-emr-cluster"
}

variable "emr_instance_type" {
  default = "m5.xlarge"
}

variable "num_core_instances" {
  default = 4
}

variable "num_task_instances" {
  default = 10
}

variable "spot_bid_price" {
  default = "0.1" # Adjust based on current spot market price
}
