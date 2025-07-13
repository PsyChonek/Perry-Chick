#!/usr/bin/env node

const { execSync, spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

// Parse command line arguments
const args = process.argv.slice(2);
let skipMinikube = false;
let skipDocker = false;
let dockerRegistry = "yourusername";

for (let i = 0; i < args.length; i++) {
	switch (args[i]) {
		case "--skip-minikube":
			skipMinikube = true;
			break;
		case "--skip-docker":
			skipDocker = true;
			break;
		case "--docker-registry":
			dockerRegistry = args[++i];
			break;
		case "-h":
		case "--help":
			console.log(
				"Usage: node setup.js [--skip-minikube] [--skip-docker] [--docker-registry REGISTRY]"
			);
			process.exit(0);
		default:
			console.log(`Unknown option ${args[i]}`);
			process.exit(1);
	}
}

console.log("🐣 Perry Chick Development Setup");
console.log("=================================");

// Helper function to check if command exists
function commandExists(cmd) {
	try {
		execSync(`${process.platform === "win32" ? "where" : "which"} ${cmd}`, {
			stdio: "ignore",
		});
		return true;
	} catch {
		return false;
	}
}

// Helper function to run command and return success status
function runCommand(cmd, options = {}) {
	try {
		execSync(cmd, { stdio: "inherit", ...options });
		return true;
	} catch {
		return false;
	}
}

// Check prerequisites
console.log("\n📋 Checking prerequisites...");

const missingTools = [];

if (!commandExists("docker")) {
	missingTools.push("Docker");
}

if (!commandExists("kubectl")) {
	missingTools.push("kubectl");
}

if (!skipMinikube && !commandExists("minikube")) {
	missingTools.push("Minikube");
}

if (!commandExists("dotnet")) {
	missingTools.push(".NET SDK 8+");
}

if (!commandExists("node")) {
	missingTools.push("Node.js");
}

if (!commandExists("npm")) {
	missingTools.push("npm");
}

if (missingTools.length > 0) {
	console.log("❌ Missing required tools:");
	missingTools.forEach((tool) => console.log(`   - ${tool}`));
	console.log(
		"\nPlease install the missing tools and run this script again."
	);
	process.exit(1);
}

console.log("✅ All prerequisites found!");

// Create environment file
console.log("\n📝 Setting up environment configuration...");

if (!fs.existsSync(".env.local")) {
	if (fs.existsSync(".env.example")) {
		fs.copyFileSync(".env.example", ".env.local");
		console.log("✅ Created .env.local from .env.example");
		console.log(
			"   Please edit .env.local with your actual configuration values"
		);
	} else {
		console.log("⚠️  .env.example not found, creating basic .env.local");
		const envContent = `DATABASE_URL=Host=localhost;Database=perrychick_db;Username=perrychick;Password=dev_password_change_me
DOCKER_REGISTRY=${dockerRegistry}
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:5000
NOTIFICATIONS_URL=http://localhost:5003
`;
		fs.writeFileSync(".env.local", envContent);
	}
} else {
	console.log("✅ .env.local already exists");
}

// Start Minikube if requested
if (!skipMinikube) {
	console.log("\n🚀 Starting Minikube...");

	try {
		const minikubeStatus = execSync("minikube status", {
			encoding: "utf8",
			stdio: "pipe",
		});
		if (minikubeStatus.includes("Running")) {
			console.log("✅ Minikube is already running");
		} else {
			throw new Error("Not running");
		}
	} catch {
		console.log("Starting Minikube with Docker driver...");
		if (runCommand("minikube start --driver=docker")) {
			console.log("✅ Minikube started successfully");
		} else {
			console.log("❌ Failed to start Minikube");
		}
	}

	// Enable required addons
	console.log("Enabling Minikube addons...");
	runCommand("minikube addons enable ingress");
	runCommand("minikube addons enable dashboard");
	runCommand("minikube addons enable metrics-server");
}

// Install .NET tools
console.log("\n🔧 Installing .NET tools...");
if (runCommand("dotnet tool install --global dotnet-ef", { stdio: "pipe" })) {
	console.log("✅ Entity Framework tools installed");
} else {
	console.log("✅ Entity Framework tools already installed");
}

// Create project directories
console.log("\n📁 Creating project structure...");
const directories = ["frontend", "backend", "notifications", "k8s"];
directories.forEach((dir) => {
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir, { recursive: true });
		console.log(`✅ Created ${dir} directory`);
	} else {
		console.log(`✅ ${dir} directory already exists`);
	}
});

// Install global npm packages
console.log("\n📦 Installing global npm packages...");
if (runCommand("npm install -g @vue/cli vue-tsc typescript")) {
	console.log("✅ Vue CLI and TypeScript tools installed");
} else {
	console.log("⚠️  Some npm packages may already be installed");
}

// Display next steps
console.log("\n🎉 Setup Complete!");
console.log("==================");

console.log("\n📚 Next steps:");
console.log("1. Open the workspace in VS Code:");
console.log("   code perry-chick.code-workspace");

console.log("\n2. Install recommended VS Code extensions when prompted");

console.log("\n3. Edit .env.local with your configuration values");

console.log("\n4. Use VS Code tasks to build and run the application:");
console.log(
	"   - Ctrl+Shift+P > Tasks: Run Task > 'Setup Development Environment'"
);
console.log(
	"   - Ctrl+Shift+P > Tasks: Run Task > 'Full Local Development Setup'"
);

console.log(
	"\n5. Start debugging with F5 or use the 'Debug Full Stack' configuration"
);

if (!skipMinikube) {
	console.log("\n🔗 Useful URLs (after deployment):");
	console.log("   - Frontend: http://localhost:3000");
	console.log("   - Backend API: http://localhost:5000");
	console.log("   - Grafana: http://localhost:3001");
	console.log("   - Prometheus: http://localhost:9090");
	console.log("   - Jaeger: http://localhost:16686");
	console.log("   - Kubernetes Dashboard: minikube dashboard");
}

console.log("\n📖 Documentation:");
console.log("   - Project overview: README.md");
console.log("   - Tech stack details: .github/project-stack-ai.md");
console.log("   - VS Code setup: .vscode/README.md");

console.log("\nHappy coding! 🚀");
