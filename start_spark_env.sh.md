
#  change name of this file to
start_spark_env.sh

# Check if services are running
docker ps

echo "Environment started! Access the following:"

echo "Spark UI: http://localhost:8080"

echo "DataFlint UI: http://localhost:4040"

echo "Prometheus: http://localhost:9090"

echo "Grafana: http://localhost:3000 (Login: admin/admin)"

/// # Make it executable:

///# chmod +x start_spark_env.sh

///# Run the script:

/// # ./start_spark_env.sh

