# Perry Chick VS Code Agent Mode Setup

This document provides guidance for working with the Perry Chick project in VS Code Agent Mode.

## Quick Start

1. **Open the workspace**: Open `perry-chick.code-workspace` in VS Code
2. **Install recommended extensions**: VS Code will prompt you to install recommended extensions
3. **Set up development environment**: Run the task "Setup Development Environment" (Ctrl+Shift+P > Tasks: Run Task)
4. **Start local development**: Run the task "Full Local Development Setup"

## VS Code Configuration Overview

The project includes comprehensive VS Code configuration:

### `.vscode/settings.json`

- Project-specific settings aligned with Perry Chick coding standards
- Tab-based indentation (4 spaces) with 80-character line limit
- Auto-formatting with Prettier
- Language-specific configurations for C#, SvelteKit, TypeScript, YAML, etc.
- Docker and Kubernetes integration settings

### `.vscode/tasks.json`

Pre-configured tasks for common development workflows:

- **Build All Docker Images**: Builds frontend, backend, and notifications images
- **Start Minikube**: Initializes local Kubernetes cluster
- **Deploy to Kubernetes**: Applies the `deploy.yaml` manifest
- **Build/Run Backend**: .NET development tasks
- **Frontend Development**: npm install, dev server, production build
- **Setup Development Environment**: One-click setup for local development
- **Full Local Development Setup**: Complete end-to-end setup

### `.vscode/launch.json`

Debug configurations for:

- Backend API debugging
- Notifications service debugging
- Container debugging (attach to Kubernetes pods)
- Frontend debugging (Chrome/Edge)
- Full-stack debugging compound configuration

### `.vscode/extensions.json`

Recommended extensions for:

- C# development (C# DevKit, OmniSharp)
- SvelteKit development (Svelte extension, Tailwind CSS)
- Docker & Kubernetes tooling
- Git integration (GitLens)
- Database tools (PostgreSQL)
- Monitoring tools (REST Client)

### `.vscode/api-requests.http`

Ready-to-use HTTP requests for testing:

- Authentication with Keycloak
- Product CRUD operations
- Cart management
- Order processing
- Notification testing
- Health checks and metrics

## Development Container Support

The project includes `.devcontainer/` configuration for consistent development environments:

- Pre-installed .NET 8 SDK, Node.js LTS, Docker, kubectl, Minikube
- All necessary development tools and extensions
- Automatic port forwarding for all services
- Post-creation setup script

## Agent Mode Best Practices

### 1. Use Tasks Instead of Terminal Commands

Instead of manually running commands, use the pre-configured tasks:

```text
Ctrl+Shift+P > Tasks: Run Task > [Select Task]
```

### 2. Debug with F5

Use the debug configurations:

- F5 to start debugging
- Select "Debug Full Stack" for complete application debugging

### 3. API Testing

Use the `.vscode/api-requests.http` file with the REST Client extension:

- Click "Send Request" above each HTTP request
- Variables are automatically managed between requests

### 4. File Structure Navigation

The workspace is organized into logical folders:

- **Perry Chick (Root)**: Main project files
- **Frontend (SvelteKit)**: SvelteKit application
- **Backend (C# API)**: .NET Minimal API
- **Notifications Service**: Notification microservice
- **Kubernetes Manifests**: K8s deployment files
- **Documentation**: Project documentation

### 5. Environment Configuration

1. Copy `.env.example` to `.env.local`
2. Update with your actual configuration values
3. The development container will use these automatically

## Common Workflows

### Starting Development

1. Open workspace: `perry-chick.code-workspace`
2. Run task: "Setup Development Environment"
3. Run task: "Full Local Development Setup"
4. Start debugging: F5 > "Debug Full Stack"

### Testing APIs

1. Open `.vscode/api-requests.http`
2. Update variables if needed
3. Click "Send Request" for any endpoint

### Deploying Changes

1. Run task: "Build All Docker Images"
2. Run task: "Deploy to Kubernetes"
3. Monitor with task: "Get Kubernetes Dashboard URL"

### Monitoring

- Grafana: `http://localhost:3001`
- Prometheus: `http://localhost:9090`
- Jaeger: `http://localhost:16686`
- Use task: "Open Grafana Dashboard" for port forwarding

## Troubleshooting

### Port Conflicts

If ports are in use, check the `forwardPorts` configuration in `.devcontainer/devcontainer.json`

### Kubernetes Issues

- Ensure Minikube is running: `minikube status`
- Check pod status: `kubectl get pods`
- View logs: `kubectl logs [pod-name]`

### Database Issues

- Verify PostgreSQL is running in the cluster
- Run migrations: Task "Run Backend Migrations"
- Check connection string in `.env.local`

### Frontend Issues

- Clear npm cache: `npm cache clean --force`
- Reinstall dependencies: Task "Install Frontend Dependencies"
- Check the dev server is running on port 3000

## AI Agent Integration

This project is optimized for AI agent assistance:

1. **Stack-aligned prompts**: Use the template in `.github/project-stack-ai.md`
2. **Clear file organization**: Logical folder structure for easy navigation
3. **Comprehensive documentation**: README, API docs, and inline comments
4. **Standardized tooling**: Consistent development environment across machines
5. **Observable systems**: Built-in monitoring and logging for troubleshooting

The project follows the Perry Chick tech stack guidelines, ensuring AI agents can provide relevant, accurate assistance while maintaining consistency with project standards.
