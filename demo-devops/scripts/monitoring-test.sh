#!/bin/bash
set -e

echo "Running monitoring tests for development environment..."

# Check monitoring components
echo "Checking monitoring namespace..."
kubectl get namespace monitoring

echo "Checking Prometheus deployment..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-server -n monitoring

echo "Checking Grafana deployment..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Test Prometheus metrics endpoint
echo "Testing Prometheus metrics endpoint..."
kubectl port-forward -n monitoring svc/prometheus-server 9090:9090 &
PROM_PID=$!
sleep 10

if curl -s http://localhost:9090/api/v1/query?query=up > /dev/null; then
    echo "Prometheus is responding to queries"
    # Check if Prometheus is scraping metrics
    SCRAPE_TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"up"' | wc -l)
    if [ $SCRAPE_TARGETS -gt 0 ]; then
        echo "Prometheus is successfully scraping $SCRAPE_TARGETS targets"
    else
        echo "Warning: Prometheus is not scraping any targets"
    fi
else
    echo "Error: Prometheus is not responding"
    exit 1
fi

kill $PROM_PID

# Test Grafana
echo "Testing Grafana..."
kubectl port-forward -n monitoring svc/grafana 3000:3000 &
GRAFANA_PID=$!
sleep 10

if curl -s http://localhost:3000/api/health | grep -q "OK"; then
    echo "Grafana is healthy"
else
    echo "Warning: Grafana health check failed"
fi

kill $GRAFANA_PID

# Check application metrics
echo "Checking if application metrics are being collected..."
sleep 30

kubectl port-forward -n monitoring svc/prometheus-server 9090:9090 &
sleep 10

APP_METRICS=$(curl -s http://localhost:9090/api/v1/query?query=up{namespace=\"app-dev\"} | grep -o '"value":\[[^]]*\]' | wc -l)
if [ $APP_METRICS -gt 0 ]; then
    echo "Application metrics are being collected successfully"
else
    echo "Warning: No application metrics found"
fi

kill %1

echo "Monitoring tests completed successfully!"