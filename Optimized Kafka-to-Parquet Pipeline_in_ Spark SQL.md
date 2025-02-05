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


