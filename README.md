# Perry Chick E-Shop

![Perry Chick Logo](https://via.placeholder.com/150?text=Perry+Chick)

## Overview

Perry Chick is a simple e-commerce web application for selling products. It features a product catalog, shopping cart, user authentication, content management, notifications, and monitoring. The project is designed for easy local development with Minikube and is fully containerized for Kubernetes deployment.

- **Target Users:** Customers buying snacks; shop owner (your friend) for managing content and orders.
- **Key Features:**
  - Browse and purchase products.
  - Secure authentication via Keycloak.
  - Content editing with Strapi CMS.
  - Asynchronous notifications (email/webhook) backed by Redis queue.
  - Observability with OpenTelemetry, Jaeger, Prometheus, and Grafana.
  - Database migrations via EF Core in C# backend.

This project is public and uses open-source tools and public Docker images for easy collaboration.

## Tech Stack

- **Frontend:** SvelteKit with TailwindCSS.
- **Backend:** C# Minimal API (.NET 8+ with EF Core for DB migrations).
- **Database:** PostgreSQL (code-first schema via EF Core).
- **Authentication:** Keycloak.
- **CMS:** Strapi.
- **Notifications:** Dedicated C# service with Redis queue (supports email via SendGrid, webhooks).
- **Monitoring:** OpenTelemetry (with Collector), Jaeger (tracing), Prometheus (metrics), Grafana (dashboards).
- **Orchestration:** Kubernetes (Minikube for local dev); all in one `deploy.yaml`.
- **Containerization:** Docker (public images on Docker Hub).

## Prerequisites

- Docker
- Minikube
- kubectl
- .NET SDK 8+ (for backend/notifications)
- Node.js (for frontend)
- Git

## Documentation

- **[Environment Configuration Management](docs/environment-config.md)** - Complete guide for managing environment variables and configuration synchronization between `.env.local` and Kubernetes

## Quick Start

1. **Start Minikube and deploy everything:**

   ```bash
   # Run the comprehensive deployment
   ./scripts/Run-All-in-Minikube.ps1
   ```

2. **Access the services:**

   ```bash
   # Start port forwarding for all services
   ./scripts/Forward-All-Services.ps1
   ```

3. **View monitoring dashboards:**
   - Grafana: http://localhost:3001
   - Pre-configured dashboards in "Perry Chick" folder
   - Prometheus: http://localhost:9090
   - Jaeger: http://localhost:16686

## Monitoring & Observability

The project includes comprehensive monitoring with pre-configured Grafana dashboards:

- **Overview Dashboard**: System health, HTTP metrics, service status
- **Database Dashboard**: PostgreSQL performance and health
- **Business Metrics**: E-commerce KPIs, orders, revenue, conversions
- **Notifications Dashboard**: Redis queue and notification service monitoring

All dashboards are automatically provisioned and available in the "Perry Chick" folder in Grafana.

## License

MIT License – feel free to use and modify!

For more details on the stack and AI prompting, see `project-stack-ai.md`.
