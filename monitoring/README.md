# Perry Chick - Grafana Monitoring Setup

## Overview

The Perry Chick project includes comprehensive monitoring via Grafana dashboards and Prometheus metrics. This directory contains pre-configured Grafana dashboards for monitoring the Perry Chick e-commerce application.

## Architecture

```
monitoring/
├── grafana/
│   ├── provisioning/
│   │   ├── dashboards/
│   │   │   └── dashboards.yaml      # Dashboard provider config
│   │   └── datasources/
│   │       └── datasources.yaml     # Prometheus datasource config
│   └── dashboards/
│       ├── perry-chick-overview.json     # Main application overview
│       ├── perry-chick-database.json     # Database performance metrics
│       ├── perry-chick-business.json     # Business & user metrics
│       └── perry-chick-notifications.json # Notification service metrics
```

## Deployment

### Method 1: Separate ConfigMap (Recommended)

```powershell
# Create dashboard ConfigMap from separate files
./scripts/create-dashboard-configmap.ps1

# Deploy the application
kubectl apply -f k8s/deploy.yaml
```

### Method 2: VS Code Task

Use the VS Code task: **"Create Dashboard ConfigMap"**

## Access URLs

After deployment with port forwarding:

- **Grafana**: http://localhost:3001 (admin/adminpassword)
- **Prometheus**: http://localhost:9090

## Dashboard Overview

### 1. Perry Chick - Overview (`perry-chick-overview`)

- **Purpose**: High-level system health and performance monitoring
- **Panels**:
  - HTTP Request Rate
  - HTTP Response Time (95th and 50th percentiles)
  - Service Status (Backend, Frontend, Notifications, Database)
  - CPU Usage by Service
  - Memory Usage by Service
  - HTTP Error Count (4xx/5xx)

### 2. Perry Chick - Database Monitoring (`perry-chick-database`)

- **Purpose**: PostgreSQL database performance and health
- **Panels**:
  - Database Status
  - Active Connections
  - Database Size
  - Total DB Transactions
  - Database Operations Rate (Inserts/Updates/Deletes)
  - Database Connections vs Max Connections
  - Cache Hit Ratio
  - Database Size Over Time

### 3. Perry Chick - Business Metrics (`perry-chick-business`)

- **Purpose**: E-commerce specific business KPIs
- **Panels**:
  - Orders Last Hour
  - Revenue Last Hour
  - Active Users
  - Cart Conversion Rate
  - Order Rate
  - Revenue Rate
  - Top 5 Viewed Products
  - Top 5 Purchased Products
  - Cart Abandonment Rate

### 4. Perry Chick - Notifications & Redis (`perry-chick-notifications`)

- **Purpose**: Monitoring notification service and Redis queue
- **Panels**:
  - Redis Status
  - Notifications Service Status
  - Redis Connected Clients
  - Notification Queue Size
  - Notification Send Rate (Email/Webhook)
  - Redis Command Rate
  - Redis Memory Usage
  - Notification Failures & Retries

## Directory Structure

```
monitoring/
├── grafana/
│   ├── dashboards/               # Individual dashboard JSON files
│   │   ├── perry-chick-overview.json
│   │   ├── perry-chick-database.json
│   │   ├── perry-chick-business.json
│   │   └── perry-chick-notifications.json
│   └── provisioning/            # Grafana provisioning configs
│       ├── dashboards/
│       │   └── dashboards.yaml
│       └── datasources/
│           └── datasources.yaml
```

## How It Works

### Kubernetes Integration

The dashboards are automatically loaded into Grafana through Kubernetes ConfigMaps:

1. **grafana-provisioning ConfigMap**: Contains datasource and dashboard provider configuration
2. **grafana-dashboards ConfigMap**: Contains the actual dashboard JSON definitions
3. **Volume Mounts**: Both ConfigMaps are mounted into the Grafana container

### Automatic Dashboard Loading

- Dashboards are automatically imported on Grafana startup
- Changes to dashboard files are picked up within 10 seconds (configurable)
- Dashboards are organized in a "Perry Chick" folder

## Required Metrics

The dashboards expect the following Prometheus metrics to be available:

### HTTP Metrics

- `http_requests_total` - Total HTTP requests by service, method, route, status code
- `http_request_duration_seconds_bucket` - HTTP request duration histograms

### Service Health

- `up` - Service availability (1 = up, 0 = down)

### Database Metrics (PostgreSQL Exporter)

- `pg_up` - PostgreSQL server status
- `pg_stat_database_*` - Database statistics
- `pg_database_size_bytes` - Database size
- `pg_settings_max_connections` - Max connections setting

### Business Metrics (Custom Application Metrics)

- `perrychick_orders_total` - Total orders counter
- `perrychick_revenue_total` - Total revenue counter
- `perrychick_active_users` - Current active users gauge
- `perrychick_cart_conversion_rate` - Cart to order conversion rate
- `perrychick_product_views_total` - Product view counter by product
- `perrychick_product_purchases_total` - Product purchase counter by product
- `perrychick_cart_abandonment_rate` - Cart abandonment rate

### Redis Metrics (Redis Exporter)

- `redis_up` - Redis server status
- `redis_connected_clients` - Number of connected clients
- `redis_commands_total` - Total commands processed
- `redis_memory_used_bytes` - Memory usage
- `redis_memory_max_bytes` - Max memory limit

### Notification Metrics (Custom Application Metrics)

- `perrychick_notifications_queue_size` - Current queue size
- `perrychick_notifications_sent_total` - Total notifications sent by type
- `perrychick_notifications_failed_total` - Total failed notifications
- `perrychick_notifications_retry_total` - Total notification retries

### Container Metrics

- `container_cpu_usage_seconds_total` - Container CPU usage
- `container_memory_usage_bytes` - Container memory usage

## Accessing Dashboards

1. **Start the application**: `kubectl apply -f k8s/deploy.yaml`
2. **Port forward Grafana**: `kubectl port-forward service/grafana 3001:3000`
3. **Login to Grafana**:
   - URL: http://localhost:3001
   - Username: admin
   - Password: adminpassword (or check secrets)
4. **Navigate to dashboards**: Go to "Dashboards" > "Perry Chick" folder

## Customization

### Adding New Dashboards

1. Create a new dashboard in Grafana UI
2. Export the dashboard JSON
3. Add the JSON to the `grafana-dashboards` ConfigMap in `k8s/deploy.yaml`
4. Apply the updated configuration: `kubectl apply -f k8s/deploy.yaml`

### Modifying Existing Dashboards

1. Edit the dashboard JSON in the ConfigMap
2. Apply the changes: `kubectl apply -f k8s/deploy.yaml`
3. Grafana will automatically reload the dashboard within 10 seconds

### Adding Custom Metrics

1. Implement the metrics in your application code
2. Ensure Prometheus can scrape the metrics
3. Update dashboard queries to use the new metrics

## Troubleshooting

### Dashboards Not Loading

- Check if the ConfigMaps are properly mounted: `kubectl describe pod <grafana-pod>`
- Verify Grafana logs: `kubectl logs <grafana-pod>`
- Ensure provisioning configuration is correct

### Missing Data

- Verify Prometheus is scraping your services
- Check if metric names match the dashboard queries
- Confirm datasource configuration in Grafana

### Performance Issues

- Adjust query intervals for high-cardinality metrics
- Consider using recording rules for complex queries
- Monitor Prometheus memory usage

## Security Considerations

- Dashboard UIDs are fixed to prevent conflicts
- Dashboards are marked as editable but changes won't persist unless saved to ConfigMaps
- Consider restricting dashboard editing permissions in production
