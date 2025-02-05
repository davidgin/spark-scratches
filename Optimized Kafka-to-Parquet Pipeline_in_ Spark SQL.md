🚀 Optimized Kafka-to-Iceberg Pipeline (Time-Travel & Schema Evolution)

This guide extends the Kafka-to-Parquet pipeline with Apache Iceberg, enabling: ✅ Time-travel queries
✅ Schema evolution (auto-update columns without breaking queries)
✅ Optimized storage with metadata pruning
✅ Support for Kafka semantics (at-least-once, exactly-once)
1️⃣ Choosing Kafka Processing Semantics (Exactly-Once vs. At-Least-Once)
🔥 Kafka Consumer Guarantees

| **Guarantee** | **Behavior** | **Best Use Case** | **Trade-offs** |
|--------------|------------|----------------|-------------|
| **At-Least-Once** | Messages are processed **at least once** but may be duplicated | High-throughput pipelines where duplicates can be handled (e.g., **aggregations**) | May require **de-duplication** in Iceberg |
| **Exactly-Once** | Messages are processed **only once**, preventing duplicates | Critical workflows like **financial transactions** | Higher **latency & resource usage** |

🔥 Configuring Kafka Read Semantics in Spark SQL

-- Enable at-least-once processing
SET spark.sql.streaming.kafka.useDeprecatedOffsetFetching = false;
SET spark.sql.streaming.commitOnBatchCompletion = true;

-- Enable exactly-once processing
SET spark.sql.streaming.kafka.useDeprecatedOffsetFetching = false;
SET spark.sql.streaming.commitOnBatchCompletion = false;

💡 Result: Selects the best trade-off between throughput and duplication prevention ✅
2️⃣ Ingest Kafka Data into Iceberg
🔥 Best Practices for Iceberg Table Creation

| **Optimization** | **Solution** |
|-----------------|-------------|
| **Enable Iceberg `MERGE INTO` for deduplication** | Ensures idempotent writes in at-least-once processing. |
| **Use `copy-on-write` mode** | Best for frequent updates and low-latency queries. |
| **Optimize partitioning (`PARTITION BY` event date)** | Ensures fast filtering of recent events. |

🔥 Example: Create Iceberg Table for Kafka Data

CREATE TABLE iceberg_transactions (
  user_id STRING,
  transaction_amount DOUBLE,
  event_time TIMESTAMP,
  event_date DATE
)
USING iceberg
PARTITIONED BY (event_date);

💡 Result: Table is optimized for fast reads and updates ✅
3️⃣ Process & Upsert Data in Iceberg
🔥 Use MERGE INTO to Handle At-Least-Once Processing

```MERGE INTO iceberg_transactions target
USING (
  SELECT user_id, transaction_amount, event_time, CAST(event_time AS DATE) AS event_date
  FROM kafka_stream
) source
ON target.user_id = source.user_id AND target.event_time = source.event_time
WHEN MATCHED THEN
  UPDATE SET transaction_amount = source.transaction_amount
WHEN NOT MATCHED THEN
  INSERT (user_id, transaction_amount, event_time, event_date)
  VALUES (source.user_id, source.transaction_amount, source.event_time, source.event_date);
```
💡 Result: Avoids duplicates in at-least-once Kafka processing ✅
4️⃣ Time-Travel Queries with Iceberg
🔥 Best Practices for Time Travel

| **Optimization**             | **Solution** |
|-----------------|-----------------

| **Use `AS OF TIMESTAMP` for historical queries** | Queries data **as it was at a specific time**. |
| **Use `VERSION AS OF` for rollback** | Restores a previous table state. |
| **Enable `SNAPSHOT_ID` pruning** | Reads only **relevant metadata**, improving query speed. |

🔥 Example: Query Iceberg Data from 1 Hour Ago

SELECT * FROM iceberg_transactions TIMESTAMP AS OF now() - interval 1 hour;

💡 Result: Returns transactions as they were 1 hour ago ✅
🔥 Example: Restore Iceberg Table to a Previous Version

ROLLBACK TO VERSION 123456789;

💡 Result: Fully restores previous state ✅
5️⃣ Optimize Iceberg Storage & Compaction
🔥 Best Practices for Iceberg Performance

| **Optimization** | **Solution** |
|-----------------|-------------|
| **Enable metadata pruning** | Reads only **necessary partitions** for faster queries. |
| **Compact small files (`REWRITE DATAFILES`)** | Prevents the **small file problem**. |
| **Use `ZORDER` for better scan efficiency** | Clusters similar data together for better read performance. |

🔥 Example: Compact Small Files in Iceberg

CALL iceberg_transactions.REWRITE_DATAFILES();

💡 Result: Improves query speed & reduces storage overhead ✅
🚀 Final Summary: Kafka-to-Iceberg Pipeline Optimizations

| Step |                       Optimization |
|------|    -------------|
| **1️⃣ Kafka Read Semantics** | Choose **at-least-once (high throughput) or exactly-once (no duplicates)**. |
| **2️⃣ Iceberg Ingestion** | Use **`MERGE INTO`** to prevent duplicates in at-least-once processing. |
| **3️⃣ Time-Travel Queries** | Use **`TIMESTAMP AS OF`** to retrieve historical data. |
| **4️⃣ Storage Optimization** | Use **`REWRITE DATAFILES`** to compact small files. |



🚀 Iceberg-Based Real-Time Aggregation in Spark SQL

This guide covers real-time streaming aggregations using Kafka + Iceberg in Spark SQL, including: ✅ Kafka ingestion with Iceberg
✅ Windowed aggregations (e.g., hourly, daily stats per user)
✅ Incremental updates (MERGE INTO instead of full scans)
✅ Optimized compaction & time-travel queries
1️⃣ Ingest Kafka Data into Iceberg
🔥 Best Practices for Streaming Data Ingestion

| **Optimization** | **Solution** |
|-----------------|-------------|
| **Use `maxOffsetsPerTrigger` to control batch size** | Ensures Spark processes a fixed number of Kafka messages per batch. |
| **Enable checkpointing** | Prevents data loss & enables exactly-once processing. |
| **Use schema-on-read** | Supports evolving schemas without breaking queries. |

🔥 Example: Read Kafka Events into Iceberg

CREATE TABLE kafka_stream 
USING kafka 
OPTIONS (
  bootstrap.servers = "kafka-broker:9092",
  subscribe = "transactions",
  startingOffsets = "latest",
  maxOffsetsPerTrigger = 10000
);

💡 Result: Only new messages are processed ✅
2️⃣ Aggregate Streaming Data in Real-Time
🔥 Best Practices for Streaming Aggregations

| **Optimization** | **Solution** |
|-----------------|-------------|
| **Use `WINDOW` functions for time-based aggregations** | Reduces the need for full table scans. |
| **Use `MERGE INTO` for incremental updates** | Prevents redundant writes. |
| **Use `WATERMARK` for late-arriving events** | Ensures Spark discards old records gracefully. |

🔥 Example: Compute Hourly Total Spending per User

CREATE TABLE user_hourly_spending 
USING iceberg 
PARTITIONED BY (event_date, hour) 
AS 
SELECT 
  user_id, 
  SUM(transaction_amount) AS total_spent, 
  DATE(event_time) AS event_date,
  HOUR(event_time) AS hour
FROM kafka_stream 
WHERE event_time >= WATERMARK(event_time, "10 minutes") 
GROUP BY user_id, event_date, hour;

💡 Result: Aggregates are computed in real-time and partitioned efficiently ✅
3️⃣ Merge Aggregated Data for Incremental Updates
🔥 Best Practices for Merging Data Efficiently

| **Optimization** | **Solution** |
|-----------------|-------------|
| **Use `MERGE INTO` instead of full table overwrites** | Updates only changed records, reducing compute overhead. |
| **Use `coalesce()` before writing to avoid small files** | Prevents fragmentation in storage. |
| **Enable `ZORDER` for better scan efficiency** | Groups frequently accessed data together for fast reads. |

🔥 Example: Merge Aggregated Data Without Duplication

MERGE INTO user_hourly_spending target
USING (
  SELECT user_id, SUM(transaction_amount) AS total_spent, DATE(event_time) AS event_date, HOUR(event_time) AS hour
  FROM kafka_stream
  GROUP BY user_id, event_date, hour
) source
ON target.user_id = source.user_id 
AND target.event_date = source.event_date 
AND target.hour = source.hour
WHEN MATCHED THEN 
  UPDATE SET total_spent = source.total_spent
WHEN NOT MATCHED THEN 
  INSERT (user_id, total_spent, event_date, hour)
  VALUES (source.user_id, source.total_spent, source.event_date, source.hour);

💡 Result: Updates only modified records, reducing write amplification ✅
4️⃣ Query Aggregated Data with Time Travel
🔥 Best Practices for Time-Travel Queries

| **Optimization** | **Solution** |
|-----------------|-------------|
| **Use `VERSION AS OF` to rollback tables** | Allows you to restore previous states easily. |
| **Use `SNAPSHOT_ID` to track incremental changes** | Enables fine-grained control over table revisions. |
| **Use `ZORDER` indexing** | Improves query speed by clustering similar data together. |

🔥 Example: Query Aggregates from 1 Day Ago

``` SELECT * FROM user_hourly_spending TIMESTAMP AS OF now() - interval 1 day; ```

💡 Result: Returns hourly spending statistics as they were yesterday ✅
🔥 Example: Restore Table to a Previous Snapshot

ROLLBACK TO VERSION 123456789;

💡 Result: Fully restores previous state ✅
5️⃣ Optimize Iceberg Storage & Compaction
🔥 Best Practices for Reducing Storage Overhead

| **Optimization** | **Solution** |
|-----------------|-------------|
| **Enable metadata pruning** | Reads only **necessary partitions** for faster queries. |
| **Compact small files (`REWRITE DATAFILES`)** | Reduces the number of storage files. |
| **Use `ZORDER` for better scan efficiency** | Groups similar data together for better read performance. |

🔥 Example: Compact Small Files in Iceberg

CALL user_hourly_spending.REWRITE_DATAFILES();

💡 Result: Improves query speed & reduces storage overhead ✅
🚀 Final Summary: Iceberg-Based Streaming Aggregation

| Step | Optimization |
|------|-------------|
| **1️⃣ Kafka Ingestion** | Use `maxOffsetsPerTrigger` and checkpointing for **efficient streaming reads**. |
| **2️⃣ Real-Time Aggregations** | Use `WINDOW` functions and `WATERMARK` for **time-based stats**. |
| **3️⃣ Merging Aggregates** | Use `MERGE INTO` to **avoid full table overwrites**. |
| **4️⃣ Time-Travel Queries** | Use `TIMESTAMP AS OF` to **query historical data**. |
| **5️⃣ Storage Optimization** | Use **`REWRITE DATAFILES`** to **compact small files**. |


1️⃣ How This Solution Handles At-Least-Once Processing
🔥 Key Strategies Used

| **Issue** | **Solution** |
|----------|-------------|
| **Duplicate records due to Kafka's at-least-once semantics** | Use `MERGE INTO` to **update or insert only new records**. |
| **Re-processing on failure** | Use **checkpointing** to store processed offsets. |
| **Data integrity issues** | Use **event-time watermarking** to prevent old duplicate events from being processed. |

2️⃣ Ensuring Exactly-Once Updates in Iceberg
🔥 Why Use MERGE INTO Instead of INSERT INTO?

    INSERT INTO blindly appends duplicate records.
    MERGE INTO updates existing records if they already exist, preventing duplicate writes.

🔥 Example: De-duplicating Streaming Data in Iceberg
```
MERGE INTO user_hourly_spending target
USING (
  SELECT user_id, SUM(transaction_amount) AS total_spent, DATE(event_time) AS event_date, HOUR(event_time) AS hour
  FROM kafka_stream
  GROUP BY user_id, event_date, hour
) source
ON target.user_id = source.user_id 
AND target.event_date = source.event_date 
AND target.hour = source.hour
WHEN MATCHED THEN 
  UPDATE SET total_spent = source.total_spent
WHEN NOT MATCHED THEN 
  INSERT (user_id, total_spent, event_date, hour)
  VALUES (source.user_id, source.total_spent, source.event_date, source.hour);
```

✅ Ensures that each user’s hourly aggregation is updated instead of duplicated.
3️⃣ Enabling Checkpointing to Avoid Reprocessing
🔥 Why Use Checkpointing?

    Without checkpointing, if Spark Streaming fails and restarts, it will reprocess Kafka messages.
    Checkpointing stores offsets so that Spark resumes from where it left off.

🔥 Example: Checkpointing Streaming Writes
```
CREATE TABLE iceberg_transactions 
USING iceberg 
OPTIONS (
  path = "s3://my-bucket/transactions/",
  checkpointLocation = "s3://my-bucket/spark-checkpoints/"
) 
AS 
SELECT * FROM kafka_stream;
```
✅ Guarantees Spark resumes exactly where it left off after failures.
4️⃣ Handling Late-Arriving Data with Watermarking
🔥 Why Use WATERMARK?

    Prevents reprocessing very old events that Kafka may redeliver.
    Ensures only new, relevant events are processed.

🔥 Example: Filtering Late Events

``` SELECT * FROM kafka_stream 
WHERE event_time >= WATERMARK(event_time, "10 minutes");
```
✅ Ensures old duplicates don’t pollute the dataset.

🚀 Final Answer: Does This Solve Kafka’s At-Least-Once Semantics?

✅ Yes, the combination of MERGE INTO, checkpointing, and watermarking ensures Spark processes Kafka’s at-least-once delivery without duplicates.
🚀 Next Steps

Would you like an Iceberg streaming ingestion DAG using Airflow for better orchestration? 🚀
You said:
does SELECT * FROM kafka_stream is from a table named kafka_stream or from the stream itself ?
ChatGPT said:
ChatGPT
Is SELECT * FROM kafka_stream Reading from a Table or a Stream?

✅ It depends on how kafka_stream is defined.
1️⃣ If kafka_stream is a Temporary Table (View) on a Kafka Stream

If kafka_stream was created using a direct Kafka source (e.g., USING kafka), then it represents a real-time stream, not a static table.

Example: Creating a Streaming Kafka Table

CREATE TABLE kafka_stream 
USING kafka 
OPTIONS (
  bootstrap.servers = "kafka-broker:9092",
  subscribe = "transactions",
  startingOffsets = "latest",
  maxOffsetsPerTrigger = 10000
);

💡 In this case, SELECT * FROM kafka_stream reads from the live Kafka stream.
2️⃣ If kafka_stream is a Materialized Iceberg Table

If kafka_stream was previously ingested into an Iceberg table, then it is a batch table, not a real-time stream.

Example: Persisting Kafka Data into Iceberg

CREATE TABLE iceberg_transactions 
USING iceberg 
AS SELECT * FROM kafka_stream;

💡 In this case, SELECT * FROM kafka_stream reads from a static Iceberg table, not a stream.
🔥 How to Check if kafka_stream is a Stream or a Table

Run:

DESCRIBE TABLE kafka_stream;

    If it lists Kafka options (e.g., bootstrap.servers, subscribe), it’s a stream.
    If it lists schema details without Kafka configs, it’s a table.

🚀 Summary: How SELECT * FROM kafka_stream Works

| Scenario | `kafka_stream` Represents | Behavior of `SELECT * FROM kafka_stream` |
|----------|--------------------------|-------------------------------------------|
| **Created using `USING kafka`** | A real-time **stream** from Kafka | Fetches **new Kafka messages** continuously |
| **Created as a persisted table (`USING iceberg`)** | A **static** Iceberg table | Reads **historical stored data** |

Would you like an example of how to ingest streaming data into an Iceberg table while keeping a live stream running? 🚀
You said:
yes
ChatGPT said:
ChatGPT
🚀 Streaming Data Ingestion into Iceberg While Keeping a Live Stream Running

This guide demonstrates how to:
✅ Continuously ingest Kafka events into an Iceberg table
✅ Query live streaming data & stored Iceberg data simultaneously
✅ Ensure exactly-once processing with checkpointing
1️⃣ Set Up a Continuous Kafka Stream in Spark SQL
🔥 Create a Real-Time Kafka Stream Table

CREATE TABLE kafka_stream 
USING kafka 
OPTIONS (
  bootstrap.servers = "kafka-broker:9092",
  subscribe = "transactions",
  startingOffsets = "latest",
  maxOffsetsPerTrigger = 10000
);

✅ Now, kafka_stream represents a real-time data stream from Kafka.
2️⃣ Continuously Ingest Streaming Data into Iceberg
🔥 Persist Kafka Data into an Iceberg Table

CREATE TABLE iceberg_transactions 
USING iceberg 
PARTITIONED BY (event_date)
OPTIONS (
  path = "s3://my-bucket/transactions/",
  checkpointLocation = "s3://my-bucket/spark-checkpoints/"
) 
AS 
SELECT 
  user_id, 
  transaction_amount, 
  event_time, 
  DATE(event_time) AS event_date
FROM kafka_stream;

✅ Now, all new Kafka events are continuously stored in Iceberg.
3️⃣ Query Both Live Stream & Stored Data
🔥 Querying Live Kafka Events (Stream)

SELECT * FROM kafka_stream 
WHERE event_time >= WATERMARK(event_time, "10 minutes");

✅ Returns real-time events from Kafka.
🔥 Querying Stored Iceberg Data

SELECT * FROM iceberg_transactions 
WHERE event_date = CURRENT_DATE;

✅ Returns historical Iceberg data stored in S3.
4️⃣ Querying Both Live & Stored Data Together
🔥 Unifying Real-Time & Stored Data

SELECT user_id, transaction_amount, event_time 
FROM kafka_stream
UNION ALL
SELECT user_id, transaction_amount, event_time 
FROM iceberg_transactions 
WHERE event_date = CURRENT_DATE;

✅ Combines live Kafka events & stored Iceberg data for a unified view.
5️⃣ Handle Late Events & Deduplication
🔥 Preventing Late Duplicates

MERGE INTO iceberg_transactions target
USING (
  SELECT user_id, SUM(transaction_amount) AS total_spent, event_date
  FROM kafka_stream
  GROUP BY user_id, event_date
) source
ON target.user_id = source.user_id AND target.event_date = source.event_date
WHEN MATCHED THEN 
  UPDATE SET transaction_amount = source.total_spent
WHEN NOT MATCHED THEN 
  INSERT (user_id, transaction_amount, event_date)
  VALUES (source.user_id, source.total_spent, source.event_date);

✅ Prevents duplicate writes while ensuring all data is up to date.
🚀 Final Summary: Iceberg Streaming Ingestion

| Step | Optimization |
|------|-------------|
| **1️⃣ Create Kafka Stream** | Use `USING kafka` to define a **live streaming table**. |
| **2️⃣ Store Data in Iceberg** | Use `USING iceberg` to create a **persistent table**. |
| **3️⃣ Query Both Live & Stored Data** | Use `UNION ALL` to **combine streaming + historical data**. |
| **4️⃣ Prevent Duplicates** | Use `MERGE INTO` to **deduplicate Kafka reprocessing**. |








