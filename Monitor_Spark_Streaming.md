Below is a PySpark Structured Streaming example that runs indefinitely and pushes per-partition metrics to Prometheus via the Pushgateway. It demonstrates how to track the number of records processed per Kafka partition over time. As the streaming job runs continuously, we reuse the same partition labels without introducing label churn.
1. High-Level Approach

    Read Stream from Kafka (or any streaming source that has partition metadata).
    Use foreachBatch to:
        Group records by partition.
        Either push micro-batch counts or maintain cumulative counts to Prometheus.
    Pushgateway
        We’ll use prometheus_client to push metrics after each micro-batch.
        Prometheus scrapes the Pushgateway, so your time series remain updated indefinitely as the job runs.
`code`
   #!/usr/bin/env python3

from pyspark.sql import SparkSession
from pyspark.sql.functions import col
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

## A global dictionary to store cumulative counts per partition
## across multiple micro-batches. This is stored in the driver.
cumulative_partition_counts = {}

def process_microbatch(batch_df, batch_id):
    """
    Called by foreachBatch for each micro-batch. We:
      - Group by 'partition' to find how many records in each partition for this batch.
      - Update a global dictionary that tracks cumulative counts per partition.
      - Push these metrics to the Pushgateway.
    """
    global cumulative_partition_counts

    ### 1. Group by 'partition', compute the record count
    partition_count_df = batch_df.groupBy("partition").count()

    ### 2. Collect the results to the driver
    partition_counts = partition_count_df.collect()

    ### 3. Update cumulative counts in the driver
    for row in partition_counts:
        partition_id = str(row["partition"])  # Convert to string for consistent labeling
        batch_count = row["count"]
        # Add to the existing count in the dictionary
        if partition_id not in cumulative_partition_counts:
            cumulative_partition_counts[partition_id] = 0
        cumulative_partition_counts[partition_id] += batch_count

    ## 4. Create a fresh Prometheus registry
    registry = CollectorRegistry()

    ## 5. Define a gauge with a label for partition_id
    gauge = Gauge(
        "spark_streaming_cumulative_partition_count",
        "Cumulative count of records processed per Kafka partition",
        ["partition_id"],
        registry=registry
    )

    ## 6. Set the gauge value for each partition
    for partition_id, total_count in cumulative_partition_counts.items():
        gauge.labels(partition_id=partition_id).set(total_count)

    ## 7. Push to the Pushgateway
    push_to_gateway(
        "pushgateway.mycompany.com:9091",  # Replace with your Pushgateway host:port
        job="structured_streaming_partition_counts",  # 'job' label in Prometheus
        registry=registry
    )

def main():
    spark = SparkSession.builder \
        .appName("StructuredStreamingPushgatewayExample") \
        .getOrCreate()

    ## Example input: read from Kafka
    ## Replace with your real Kafka config
    df = spark \
        .readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "localhost:9092") \
        .option("subscribe", "my_topic") \
        .load()

    ## We'll select only partition, offset, and value for demonstration.
    kafka_df = df.select(
        col("partition"),
        col("offset"),
        col("value")
    )

    ## Write the stream using foreachBatch
    query = kafka_df.writeStream \
        .foreachBatch(process_microbatch) \
        .outputMode("append") \
        .start()

    ## Keep the streaming job running indefinitely
    query.awaitTermination()

    spark.stop()

if __name__ == "__main__":
    main()
```    
