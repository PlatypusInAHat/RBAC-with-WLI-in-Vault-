# Quick reference commands for Minikube setup

## 1. Create minikube cluster
minikube start --nodes 2 --memory 3072 --cpus 2 --driver docker

## 2. Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

## 3. Load images
minikube image load bloodbank-backend:latest
minikube image load bloodbank-frontend:latest

## 4. Verify
kubectl get nodes
minikube image ls | findstr bloodbank

## 5. Deploy application
.\scripts\deploy.ps1

## 6. Access services
# Option 1: Using minikube service (automatically opens browser)
minikube service frontend -n bloodbank
minikube service backend -n bloodbank

# Option 2: Using port-forward
kubectl port-forward -n bloodbank svc/frontend 30080:3000
kubectl port-forward -n bloodbank svc/backend 30000:3000

## 7. Check deployment
kubectl get pods -n bloodbank
kubectl get pods -n vault
kubectl get svc -n bloodbank

## 8. Logs
kubectl logs -n bloodbank -l component=backend --tail=50
kubectl logs -n bloodbank -l component=frontend --tail=50

## 9. Clean up
minikube stop
minikube delete

## ⚠️ Troubleshooting

**Lỗi: minikube start treo hoặc failing to connect registry**
Nếu tạo cluster quá lâu hoặc lỗi mạng, dùng lệnh sau để dùng mirror server:
```powershell
minikube delete
minikube start --nodes 2 --memory 3072 --cpus 2 --driver docker --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```
Sau đó chạy lại script setup.
