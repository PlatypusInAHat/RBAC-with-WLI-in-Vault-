# Quick reference commands for Minikube setup

## 1. Create minikube cluster
minikube start --nodes 2 --memory 3072 --cpus 2 --driver docker

## 2. Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

## 3. Load images
minikube image load prj-backend:latest
minikube image load prj-frontend:latest

## 4. Verify
kubectl get nodes
minikube image ls | findstr prj

## 5. Deploy application
.\scripts\deploy.ps1

## 6. Access services
# Option 1: Using minikube service (automatically opens browser)
minikube service frontend -n prj
minikube service backend -n prj

# Option 2: Using port-forward
kubectl port-forward -n prj svc/frontend 30080:3000
kubectl port-forward -n prj svc/backend 30000:3000

## 7. Check deployment
kubectl get pods -n prj
kubectl get pods -n vault
kubectl get svc -n prj

## 8. Logs
kubectl logs -n prj -l component=backend --tail=50
kubectl logs -n prj -l component=frontend --tail=50

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
