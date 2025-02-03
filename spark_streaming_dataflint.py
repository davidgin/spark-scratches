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
