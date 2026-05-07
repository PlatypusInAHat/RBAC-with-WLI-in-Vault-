# K8s Demo - RBAC & Workload Identity with Vault

Ứng dụng demo đơn giản để kiểm thử các tính năng Kubernetes:
- **RBAC** (Role-Based Access Control)
- **Workload Identity** với HashiCorp Vault
- **Secret Sharing** giữa các services

## 📋 Kiến trúc

```
┌─────────────────┐
│    Frontend     │ (Static HTML)
│  (Port 30080)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│     Backend     │────▶│  PostgreSQL  │
│   (Port 30000)  │     │  (Port 5432) │
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐
│  Vault Server   │
│  (Port 8200)    │
└─────────────────┘
```

### Components

- **Backend**: Node.js/Express API với endpoints demo
- **Frontend**: Static HTML dashboard
- **PostgreSQL**: Database
- **Vault**: Secret management

## 🚀 Quick Start

### 1. Build Docker Images

Windows (PowerShell):
```powershell
.\scripts\build-images.ps1
```

Linux/Mac:
```bash
chmod +x ./scripts/build-images.sh
./scripts/build-images.sh
```

### 2. Load Images vào Kind/Minikube (nếu dùng)

**Kind:**
```bash
kind load docker-image prj-backend:latest --name <your-cluster-name>
kind load docker-image prj-frontend:latest --name <your-cluster-name>
```

**Minikube:**
```bash
minikube image load prj-backend:latest
minikube image load prj-frontend:latest
```

### 3. Deploy lên K8s

```powershell
.\scripts\deploy.ps1
```

### 4. Kiểm tra deployment

```bash
kubectl get pods -n prj
kubectl get pods -n vault
```

### 5. Truy cập ứng dụng

Port forward các services:
```bash
# Frontend
kubectl port-forward -n prj svc/frontend 30080:3000

# Backend (terminal mới)
kubectl port-forward -n prj svc/backend 30000:3000

# Vault (terminal mới)
kubectl port-forward -n vault svc/vault 8200:8200
```

Mở browser:
- **Frontend**: http://localhost:30080
- **Backend API**: http://localhost:30000
- **Vault UI**: http://localhost:8200

## 🔐 RBAC Configuration

### Service Accounts

- `prj-backend-sa` - Backend service account
- `prj-frontend-sa` - Frontend service account
- `prj-postgres-sa` - PostgreSQL service account

### Roles & Permissions

**Backend có quyền:**
- ✅ Read Secrets (`secret-reader` role)
- ✅ Read ConfigMaps (`configmap-reader` role)
- ✅ Read Pods (`pod-reader` role)
- ✅ Token Reviews (`auth-delegator` cluster role)

**Frontend có quyền:**
- ✅ Read ConfigMaps (`configmap-reader` role)

## 🔒 Vault Integration

### Workload Identity Flow

1. Pod được tạo với ServiceAccount annotation
2. Vault Agent Injector inject sidecar container
3. Sidecar authenticate với Vault sử dụng K8s auth
4. Secrets được mount vào `/vault/secrets/`

### Secret Sharing

Cả Backend và Frontend đều có thể access **shared secrets**:
- `encryption_key`
- `session_secret`

Backend có thêm access:
- Database credentials
- JWT secret
- API keys

## 📊 API Endpoints

Backend cung cấp các endpoints sau:

- `GET /health` - Health check
- `GET /api/info` - Service account & pod info
- `GET /api/rbac` - RBAC permissions status
- `GET /api/secrets` - Secrets access demo
- `GET /api/vault` - Vault integration status
- `GET /api/database` - Database connection test

## 🧪 Testing RBAC

Test từ bên trong pod:

```bash
# Vào backend pod
kubectl exec -it -n prj deploy/backend -- sh

# Kiểm tra service account token
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Kiểm tra namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace

# Test API
curl http://localhost:3000/api/rbac
curl http://localhost:3000/api/vault
```

## 🔍 Verify Vault Injection

```bash
# Check pod có vault sidecar
kubectl describe pod -n prj <backend-pod-name> | grep vault

# Check secrets được inject
kubectl exec -n prj <backend-pod-name> -- ls -la /vault/secrets/
```

## 🌐 Network Policies

Network policies đã được configure:

- PostgreSQL: Chỉ nhận traffic từ Backend
- Backend: Nhận từ Frontend và external
- Frontend: Nhận traffic external
- Tất cả services: Có thể connect tới Vault

## 🛠️ Troubleshooting

### Pods không start

```bash
kubectl get pods -n prj
kubectl describe pod -n prj <pod-name>
kubectl logs -n prj <pod-name>
```

### Vault Agent không inject

Check annotations trong deployment:
```bash
kubectl get deployment -n prj backend -o yaml | grep vault
```

### Database connection lỗi

```bash
# Check postgres pod
kubectl get pods -n prj | grep postgres

# Check logs
kubectl logs -n prj <postgres-pod>
```

## 📝 Files Structure

```
.
├── backend/
│   ├── server.js          # Express API server
│   ├── package.json       # Dependencies
│   ├── Dockerfile         # Container image
│   └── .dockerignore
├── frontend/
│   ├── index.html         # Dashboard UI
│   ├── Dockerfile         # Nginx container
│   └── .dockerignore
├── k8s/
│   ├── base/
│   │   ├── namespace.yaml
│   │   ├── rbac.yaml
│   │   ├── secrets.yaml
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── postgres-deployment.yaml
│   │   ├── services.yaml
│   │   ├── ingress.yaml
│   │   └── network-policies.yaml
│   └── vault/
│       ├── vault-rbac.yaml
│       ├── vault-deployment.yaml
│       └── vault-service.yaml
└── scripts/
    ├── build-images.ps1   # Build Docker images
    └── deploy.ps1         # Deploy to K8s
```

## 🎯 What This Demo Shows

1. ✅ **RBAC**: Service accounts với different permissions
2. ✅ **Workload Identity**: Vault authentication via K8s SA
3. ✅ **Secret Sharing**: Shared secrets between services
4. ✅ **Network Policies**: Restricted communication
5. ✅ **Security**: Non-root containers, resource limits
6. ✅ **Health Checks**: Liveness & readiness probes

## 📚 Further Reading

- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Vault Kubernetes Auth](https://www.vaultproject.io/docs/auth/kubernetes)
- [Vault Agent Injector](https://www.vaultproject.io/docs/platform/k8s/injector)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
