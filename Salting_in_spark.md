Handling Skewed Data in Spark with Salting
Why Use Salting in Spark?

Salting is a technique to avoid data skew in groupBy or aggregations by distributing keys across partitions.
🚨 Problem: Skewed GroupBy

    If a small number of keys have millions of records, Spark assigns them to a few partitions, causing:
        Slow performance (some tasks finish instantly, others take forever).
        Memory issues (executors handling large partitions may crash).

Example Without Salting (Skewed groupBy)

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count

spark = SparkSession.builder.appName("DataSkewExample").getOrCreate()

# Sample skewed dataset
data = [("user_1", 100), ("user_2", 5), ("user_3", 5), ("user_1", 90)]  # Skewed!
df = spark.createDataFrame(data, ["user_id", "event_count"])

# Skewed groupBy operation
df.groupBy("user_id").agg(count("event_count").alias("total_events")).show()

🚨 Issue:

    If user_1 has millions of records, Spark assigns all of them to one partition, slowing down the job.

🛑 Skewed Output (Partition Imbalance)

+--------+-------------+
| user_id| total_events|
+--------+-------------+
| user_1 |       10000 |  <- One executor overloaded
| user_2 |         500 |  <- Other executors idle
| user_3 |         300 |
+--------+-------------+

✅ Fix: Salting Before groupBy

To balance the workload across partitions, we add a salt (random number) to user_id.

from pyspark.sql.functions import rand, concat

# Add salt (random number) to distribute keys
df_salted = df.withColumn("salted_user_id", concat(col("user_id"), (rand() * 10).cast("int")))

# Group by the salted user_id
df_salted.groupBy("salted_user_id").agg(count("event_count").alias("total_events")).show()

🟢 How Salting Works

    We generate a random integer from 0-9.
    We append this random value to the key (e.g., "user_1_3", "user_1_7", etc.).
    This spreads the workload evenly across partitions.

🔍 Salted Keys Example

| user_id | salted_user_id | event_count |
|---------|---------------|-------------|
| user_1  | user_1_3      | 100         |
| user_1  | user_1_7      | 90          |
| user_2  | user_2_4      | 5           |
| user_3  | user_3_1      | 5           |

🔄 Final Step: Merge Results Back

Since the same user_id now has multiple salted versions, we must merge them back after groupBy.

df_final = df_salted.groupBy("user_id").agg(count("event_count").alias("total_events"))
df_final.show()

🟢 Corrected Output (Balanced Workload)

+--------+-------------+
| user_id| total_events|
+--------+-------------+
| user_1 |       10000 |  <- Now processed evenly
| user_2 |         500 |
| user_3 |         300 |
+--------+-------------+

When to Use Salting?

✅ Use When:

    Your dataset is highly skewed.
    One or two keys dominate the data.
    Tasks on some partitions take much longer.

❌ Do Not Use When:

    Your data is already well-distributed.
    You are using broadcast joins (salting may break join keys!).

🚀 Summary: Why Use Salting in Spark?

| Problem                                    | Solution (Salting)                          |
|--------------------------------------------|---------------------------------------------|
| Skewed data overloads some partitions     | Adds random salt to distribute keys evenly |
| Some tasks take much longer               | Spreads workload across multiple partitions |
| Executors run out of memory (OOM errors)  | Prevents one executor from handling too much |
| Processing is slow due to key imbalance   | Speeds up groupBy and aggregations         |


