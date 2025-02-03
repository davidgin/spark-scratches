# spark-scratches 

basic spark optimization steps:

Best Ways to Identify Spark Streaming Performance Issues

To troubleshoot slow performance in Spark Streaming, you need real-time monitoring, profiling, and log analysis. Below are the best tools and techniques for identifying bottlenecks.
1. Use Spark Web UI for Performance Metrics

🛠 Tool: Spark Web UI (http://<driver>:4040)
📊 What to Check:

    Streaming Tab → Shows batch processing times, input rates, scheduling delays.
    Jobs Tab → Identifies slow tasks.
    Executors Tab → Monitors memory & CPU usage.

✅ How to Use It:
1️⃣ Run your Spark Streaming job.
2️⃣ Open your browser and go to: http://localhost:4040


Navigate to:

    Streaming Tab: Check batch processing time.
    Stages Tab: Look for shuffle-heavy operations (like groupBy and join).
    Executors Tab: Check memory usage and Garbage Collection (GC) time.

2. Use DataFlint for Advanced Spark Monitoring

🛠 Tool: DataFlint
📊 What to Check:

    Query Performance Breakdown
    Slow Stages & Tasks
    Cluster Resource Usage
    Data Skew & Backpressure Analysis

✅ How to Enable DataFlint: 1️⃣ Add DataFlint to spark-submit:

spark-submit --packages io.dataflint:spark_2.12:0.2.9 --conf spark.plugins=io.dataflint.spark.SparkDataflintPlugin your_script.py (or code in scala or java)
Open Spark UI → Click on "DataFlint" tab. 3️⃣ Analyze slow jobs, memory bottlenecks, and shuffle issues.


Best Ways to Identify Spark Streaming Performance Issues

To troubleshoot slow performance in Spark Streaming, you need real-time monitoring, profiling, and log analysis. Below are the best tools and techniques for identifying bottlenecks.
1. Use Spark Web UI for Performance Metrics

🛠 Tool: Spark Web UI (http://<driver>:4040)
📊 What to Check:

    Streaming Tab → Shows batch processing times, input rates, scheduling delays.
    Jobs Tab → Identifies slow tasks.
    Executors Tab → Monitors memory & CPU usage.

✅ How to Use It:
1️⃣ Run your Spark Streaming job.
2️⃣ Open your browser and go to:

http://localhost:4040

3️⃣ Navigate to:

    Streaming Tab: Check batch processing time.
    Stages Tab: Look for shuffle-heavy operations (like groupBy and join).
    Executors Tab: Check memory usage and Garbage Collection (GC) time.

2. Use DataFlint for Advanced Spark Monitoring

🛠 Tool: DataFlint
📊 What to Check:

    Query Performance Breakdown
    Slow Stages & Tasks
    Cluster Resource Usage
    Data Skew & Backpressure Analysis

✅ How to Enable DataFlint: 1️⃣ Add DataFlint to spark-submit:

spark-submit --packages io.dataflint:spark_2.12:0.2.9 --conf spark.plugins=io.dataflint.spark.SparkDataflintPlugin your_script.py

2️⃣ Open Spark UI → Click on "DataFlint" tab. 3️⃣ Analyze slow jobs, memory bottlenecks, and shuffle issues.
3. Enable Streaming Metrics (Backpressure & Batch Delay)

🛠 Tool: Spark Metrics System
📊 What to Check:

    Batch Scheduling Delay (spark.streaming.schedulerDelay)
    Processing Time (spark.streaming.batchProcessingTime)
    Backpressure (spark.streaming.backpressure.enabled)

✅ How to Enable Metrics in Spark Config: 
--conf spark.streaming.backpressure.enabled=true \
--conf spark.streaming.kafka.maxRatePerPartition=1000

✅ Analyze Metrics with a Dashboard (Prometheus + Grafana) if exists:

    Prometheus scrapes Spark metrics.
    Grafana visualizes performance over time.

4. Check Spark Logs for Errors & Performance Warnings

🛠 Tool: Log Files (stdout, stderr)
📊 What to Check:

    Long-running batch warnings (WARN Scheduling delay too high)
    Executor lost messages (ERROR ExecutorLostFailure)
    GC Overhead warnings (WARN Task took too long to complete)

✅ How to View Logs:
docker logs -f spark-master or 
cat logs/spark-job.log | grep WARN

5. Identify Skewed Data (Uneven Load Distribution)

🛠 Tool: Spark UI → Stages Tab
📊 What to Check:

    Some tasks take much longer than others.
    Certain partitions have more data than others.

✅ How to Fix Data Skew:

    Use repartition() to balance partitions:
     df = df.repartition(10, "user_id")
  Use salting for groupBy to distribute keys.


6. Analyze Slow Checkpointing & State Storage

🛠 Tool: HDFS/S3 Logs
📊 What to Check:

    Checkpoint write failures.
    Slow recovery after failure.

✅ How to Check:

    Look at HDFS/S3 checkpointing logs.
    Enable debug mode:

--conf spark.executor.extraJavaOptions="-Dlog4j.logger.org.apache.spark.streaming=DEBUG"

7. Enable GC Logging to Detect High Memory Usage

🛠 Tool: GC Logs
📊 What to Check:

    Frequent Full GC Events
    High Memory Pressure

✅ How to Enable GC Logging in Spark:

--conf spark.executor.extraJavaOptions=-XX:+PrintGCDetails

Then analyze the logs:

grep "GC" logs/spark-job.log

3. Start the Spark Cluster with DataFlint
    docker-compose up -d
    Copy the streaming job into the container:
    docker cp spark_streaming_dataflint.py spark-master:/spark_streaming_dataflint.py
    docker exec -it spark-master spark-submit --master spark://spark-master:7077 /spark_streaming_dataflint.py

Spark Streaming with DataFlint for Monitoring in Docker-Compose

This example extends your Spark Streaming setup by integrating DataFlint for enhanced monitoring.
1. Update docker-compose.yml

Modify your Spark cluster to include DataFlint for monitoring.



✅ Key Additions:

    Enabled DataFlint monitoring in Spark Master and Worker via SPARK_PLUGINS=io.dataflint.spark.SparkDataflintPlugin.

2. Create the Streaming Job (spark_streaming_dataflint.py)

This Spark job:

    Reads real-time data from Netcat (nc -lk -p 9999).
    Counts words in real-time.
    Prints results to the console.
    Includes DataFlint Monitoring.

from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split

# Initialize Spark with DataFlint Plugin
spark = SparkSession.builder \
    .appName("SparkStreamingDataFlint") \
    .master("spark://spark-master:7077") \
    .config("spark.jars.packages", "io.dataflint:spark_2.12:0.2.9") \
    .config("spark.plugins", "io.dataflint.spark.SparkDataflintPlugin") \
    .getOrCreate()

# Read Streaming Data from Netcat
lines = spark.readStream \
    .format("socket") \
    .option("host", "netcat-server") \
    .option("port", 9999) \
    .load()

# Split lines into words
words = lines.select(explode(split(lines.value, " ")).alias("word"))

# Count occurrences of each word
word_counts = words.groupBy("word").count()

# Output results to console
query = word_counts.writeStream \
    .outputMode("complete") \
    .format("console") \
    .start()

query.awaitTermination()

3. Start the Spark Cluster with DataFlint

Run:

docker-compose up -d

Copy the streaming job into the container:

docker cp spark_streaming_dataflint.py spark-master:/spark_streaming_dataflint.py

Run the Spark Streaming Job with DataFlint:

docker exec -it spark-master spark-submit --master spark://spark-master:7077 /spark_streaming_dataflint.py

4. Test the Streaming Application

Send test messages via Netcat:

nc localhost 9999

💬 Type messages in the terminal, such as:

hello world spark streaming is awesome
hello spark monitoring

📌 The Spark Streaming application will process the words and print real-time word counts.
5. Monitor with DataFlint

Open Spark UI (with DataFlint added) at:

http://localhost:8080

✅ Navigate to the "DataFlint" tab for:

    Query Breakdown with performance metrics.
    Live Cluster Monitoring.
    Execution Timeline & Performance Insights.
6. Stopping the Cluster

To stop all containers:

docker-compose down


Spark image does not include the DataFlint jar by default. You need to manually provide the DataFlint JAR package either by:

    Passing it in spark-submit (--packages io.dataflint:spark_2.12:0.2.9).
    Mounting the JAR inside the container and referencing it in the configuration

Option 1: Pass DataFlint as a Dependency in spark-submit

This is the simplest way to use DataFlint without modifying the image.

Run the job with:

docker exec -it spark-master spark-submit \
    --master spark://spark-master:7077 \
    --packages io.dataflint:spark_2.12:0.2.9 \
    --conf spark.plugins=io.dataflint.spark.SparkDataflintPlugin \
    /spark_streaming_dataflint.py

✅ This will automatically download the DataFlint JAR and enable the plugin.
Option 2: Mount the DataFlint JAR into the Spark Container

If you want a persistent setup, manually download the DataFlint JAR and mount it into the container.

1️⃣ Download the JAR (Replace version as needed):

wget https://repo1.maven.org/maven2/io/dataflint/spark_2.12/0.2.9/spark_2.12-0.2.9.jar -O dataflint.jar



3️⃣ Restart the Cluster:

docker-compose down && docker-compose up -d

4️⃣ Run the Spark Streaming Job:

docker exec -it spark-master spark-submit \
    --master spark://spark-master:7077 \
    --conf spark.plugins=io.dataflint.spark.SparkDataflintPlugin \
    /spark_streaming_dataflint.py

Summary of Approaches
Approach	Pros	Cons
Use --packages in spark-submit	✅ No need to modify images	❌ Downloads the JAR each time
Mount JAR via docker-compose.yml	✅ Persistent & avoids re-downloading	❌ Requires manually downloading the JAR

If you plan to use DataFlint regularly, Option 2 (Mount JAR) is preferred for efficiency.















