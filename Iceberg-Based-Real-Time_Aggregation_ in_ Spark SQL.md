
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

SELECT * FROM user_hourly_spending TIMESTAMP AS OF now() - interval 1 day;

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

