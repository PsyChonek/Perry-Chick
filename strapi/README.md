# Strapi CMS for Perry Chick E-commerce

This directory contains the Strapi CMS configuration for the Perry Chick e-commerce platform.

## Quick Start

### 1. Generate Strapi Secrets (First Time Only)

```powershell
./scripts/generate-strapi-secrets.ps1
```

### 2. Initialize Strapi

```powershell
./scripts/setup-strapi.ps1
```

### 3. Access Strapi Admin Panel

Open <http://localhost:1337/admin> and create your first admin user.

## Development Commands

### Local Development

```bash
npm run develop   # Start with auto-reload
npm run start     # Start without auto-reload
# or
yarn start
```

### `build`

Build your admin panel. [Learn more](https://docs.strapi.io/dev-docs/cli#strapi-build)

```bash
npm run build     # Build for production
```

### Kubernetes Development

```powershell
# Build and deploy
./scripts/setup-strapi.ps1

# Or restart existing deployment
./scripts/setup-strapi.ps1 -RestartOnly
```

## Content Types for Perry Chick

Create these content types in the Strapi admin panel for e-commerce functionality:

### Products

- **name** (Text) - Required
- **description** (Rich Text)
- **price** (Number, Decimal) - Required
- **sku** (Text) - Unique
- **images** (Media, Multiple)
- **category** (Relation to Category)
- **inStock** (Boolean) - Default: true
- **featured** (Boolean) - Default: false
- **slug** (UID from name)

### Categories

- **name** (Text) - Required
- **description** (Rich Text)
- **slug** (UID from name)
- **image** (Media, Single)
- **parentCategory** (Relation to Category, optional)

### Pages

- **title** (Text) - Required
- **content** (Rich Text)
- **slug** (UID from title)
- **metaDescription** (Text)
- **published** (Boolean) - Default: false

### Site Settings (Single Type)

- **siteName** (Text)
- **tagline** (Text)
- **logo** (Media, Single)
- **favicon** (Media, Single)
- **contactEmail** (Email)
- **socialLinks** (JSON)

## API Usage

### Public API Endpoints

- **Products:** `GET /api/products`
- **Categories:** `GET /api/categories`
- **Pages:** `GET /api/pages`
- **Settings:** `GET /api/site-setting`

### Integration with Frontend

```javascript
// Example API call
const response = await fetch("http://localhost:1337/api/products?populate=*");
const products = await response.json();
```

## VS Code Tasks

- **Debug Strapi** - Run Strapi locally in development mode
- **Setup Strapi** - Initialize Strapi in Kubernetes
- **Generate Strapi Secrets** - Generate secure secrets

For more information, see the [Strapi Documentation](https://docs.strapi.io/).
