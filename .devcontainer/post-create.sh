#!/bin/bash

# Post-create script for Perry Chick development container
echo "🐣 Setting up Perry Chick development environment..."

# Ensure .dotnet tools are in PATH
export PATH="$PATH:/home/vscode/.dotnet/tools"

# Install global npm packages
echo "📦 Installing global npm packages..."
npm install -g @vue/cli vue-tsc typescript

# Set git config if not already set
if [ -z "$(git config --global user.name)" ]; then
	echo "⚙️  Setting up Git configuration..."
	echo "Please run: git config --global user.name 'Your Name'"
	echo "Please run: git config --global user.email 'your.email@example.com'"
fi

# Create necessary directories
mkdir -p frontend backend notifications k8s

# Install dotnet dev certificates for HTTPS
echo "🔒 Setting up development certificates..."
dotnet dev-certs https --trust 2>/dev/null || echo "Note: HTTPS certificates setup skipped in container"

# Create a sample .env file if it doesn't exist
if [ ! -f .env ]; then
	echo "📝 Creating sample .env file..."
	cat > .env << 'EOF'
# Perry Chick Environment Variables
# Copy this to .env.local and customize as needed

# Database
POSTGRES_USER=perrychick
POSTGRES_PASSWORD=dev_password_change_me
POSTGRES_DB=perrychick_db
DATABASE_URL=Host=localhost;Database=perrychick_db;Username=perrychick;Password=dev_password_change_me

# Keycloak
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin_password_change_me
KEYCLOAK_URL=http://localhost:8080

# Redis
REDIS_URL=localhost:6379

# SendGrid (for notifications)
SENDGRID_API_KEY=your_sendgrid_api_key_here

# Application URLs
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:5000
NOTIFICATIONS_URL=http://localhost:5003

# Docker Registry
DOCKER_REGISTRY=yourusername
EOF
fi

echo "✅ Development environment setup complete!"
echo ""
echo "🚀 Quick start commands:"
echo "  - Run 'code .' to open in VS Code"
echo "  - Use Ctrl+Shift+P -> 'Tasks: Run Task' -> 'Setup Development Environment'"
echo "  - Use F5 to start debugging"
echo ""
echo "📚 Documentation:"
echo "  - Project stack: .github/project-stack-ai.md"
echo "  - README: README.md"
echo ""
