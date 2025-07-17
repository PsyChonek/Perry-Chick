# Perry Chick Project Stack and AI Instructions

This document outlines the tech stack for the "Perry Chick" e-shop project and provides a template for prompting AI assistants (like T3 Chat powered by Grok 4). Use this to ensure AI responses align with project goals, technologies, and best practices.

## Project Overview

- **App Name:** Perry Chick
- **Description:** A Kubernetes-based e-commerce app for selling popcorn and ham. Includes frontend, backend, auth, CMS, notifications, and monitoring.
- **Goals:** Build a scalable, observable online store with easy local dev (Minikube). Project is public, using open-source tools and public images.
- **Constraints:** All services in one `deploy.yaml` for single-command apply. Use EF Core for DB migrations (code-first, no raw SQL schemas).

## Tech Stack Details

- **Frontend (FE):** SvelteKit with TailwindCSS. Use components for product listings, cart, etc. Integrate with backend API and Keycloak for auth.
- **Backend:** C# Minimal API (.NET 8+). Handle API endpoints for products/orders. Use EF Core for Postgres migrations (define models like Product, Order in DbContext).
- **Database:** PostgreSQL (latest). Code-first schema via EF Core – focus on entities like Products (ID, Name, Price, Stock), Orders (ID, UserID from Keycloak, TotalAmount), OrderItems, Notifications.
- **Authentication:** Keycloak (public image). Use OAuth2/OpenID for user accounts; integrate with backend/frontend.
- **CMS:** Strapi (public image). For editing product content and pages.
- **Notifications:** Dedicated C# Minimal API service. Uses Redis for queuing (StackExchange.Redis). Handles email (SendGrid) and webhooks asynchronously.
- **Monitoring/Observability:** OpenTelemetry (SDK in C# services). Includes OTel Collector, Jaeger (tracing), Prometheus (metrics), Grafana (dashboards) – all public images.
- **Queueing:** Redis (public image) for notification backing queue.
- **Containerization/Orchestration:** Docker (public images on Docker Hub). Kubernetes with Minikube for local dev; single `deploy.yaml` for all deployments/services.
- **Other:** Git for version control (public GitHub repo). Use tabs in code; format with Prettier (80-char width).

**Why This Stack?** Scalable (Kubernetes), modern (SvelteKit/C#), observable (OTel), and cost-free/public for easy sharing.

## AI Prompt Template

When prompting an AI for help (e.g., generating code, debugging, or ideas), copy-paste this template and fill in the [brackets]. This ensures responses are helpful, respectful, and aligned.

**1. App Overview**

- **App Name:** Perry Chick
- **High-Level Description:** [e.g., "E-shop for popcorn and ham with auth, CMS, notifications, and monitoring."]
- **Target Users:** [e.g., "Snack buyers and shop admin."]
- **Key Features:** [List 3-5, e.g., "Product catalog, orders, email notifications."]

**2. Goals and Objectives**

- **Primary Goal:** [e.g., "Create a functional MVP deployable on Minikube."]
- **Success Metrics:** [e.g., "Running locally with monitoring dashboards."]
- **Constraints/Limitations:** [e.g., "Single YAML file; public images only."]

**3. Preferred Technologies**

- **Frontend:** SvelteKit
- **Backend:** C# Minimal API with EF Core for migrations
- **Database:** Postgres (code-first via EF Core)
- **Authentication:** Keycloak
- **CMS:** Strapi
- **Notifications:** C# service with Redis queue
- **Monitoring:** OpenTelemetry, Jaeger, Prometheus, Grafana
- **Orchestration:** Kubernetes/Minikube, Docker public images
- **Why These?** [e.g., "For scalability and ease of use."]

**4. Specific Request to AI**

- **What I Need Help With:** [e.g., "Generate EF Core models for products and orders."]
- **Output Format:** [e.g., "C# code in Markdown block, formatted with tabs and 80-char width."]
- **Additional Guidelines:** [e.g., "Keep it efficient; integrate with existing stack."]

**5. Any Additional Context**

- [e.g., "Project is public on GitHub. Current date: 7/11/2025."]

## Instructions for AI Assistants

- **Be Helpful and Engaging:** Provide step-by-step explanations, code snippets, and suggestions. Always suggest grammar fixes if needed.
- **Stick to Stack:** Do not suggest alternatives unless asked (e.g., no MySQL instead of Postgres).
- **Use Tools if Needed:** For up-to-date info (post-Nov 2024), use web search tool with absolute dates (e.g., "2025").
- **Code Formatting:** Use Markdown blocks with language (e.g., ```csharp). Tabs for indentation; Prettier 80-char width.
- **DB Handling:** Assume EF Core code-first – generate models/migrations, not raw SQL.
- **Example Prompt Usage:** "Using the Perry Chick AI template, generate a SvelteKit component for the shopping cart."

This template ensures consistent, on-target AI help. If updating the project, revise this doc accordingly!
