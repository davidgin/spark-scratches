resource "aws_emr_cluster" "elastic_emr" {
  name          = var.emr_cluster_name
  release_label = "emr-6.9.0"
  applications  = ["Spark", "Hadoop"]

  ec2_attributes {
    key_name                          = "my-keypair"
    instance_profile                  = aws_iam_instance_profile.emr_profile.arn
    subnet_id                          = aws_subnet.default.id
    emr_managed_master_security_group = aws_security_group.emr_master.id
    emr_managed_slave_security_group  = aws_security_group.emr_slaves.id
  }

  master_instance_group {
    instance_type = var.emr_instance_type
    instance_count = 1
    market         = "ON_DEMAND"
  }

  core_instance_group {
    instance_type  = var.emr_instance_type
    instance_count = var.num_core_instances
    market         = "SPOT"
    bid_price      = var.spot_bid_price
  }

  task_instance_group {
    instance_type  = var.emr_instance_type
    instance_count = var.num_task_instances
    market         = "SPOT"
    bid_price      = var.spot_bid_price
  }

  configurations_json = <<EOF
[
  {
    "Classification": "spark",
    "Properties": {
      "maximizeResourceAllocation": "true"
    }
  },
  {
    "Classification": "spark-defaults",
    "Properties": {
      "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
      "spark.sql.shuffle.partitions": "500",
      "spark.streaming.kafka.maxRatePerPartition": "20000"
    }
  }
]
EOF

  log_uri = "s3://my-emr-logs/"
}
