docker-compose -f docker-compose_rabbitmq.yml up -d
echo "Waiting 10 seconds for RabbitMQ to start." ; sleep 10
docker-compose -f docker-compose_kieker.yml up -d
echo "Waiting 2 minutes for TeaStore to start." ; sleep 120
echo "Now, you can start the load test."
