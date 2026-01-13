# 🔴 Service Discovery Issues - Báo Cáo Triệu Chứng

## 📋 Mục đích
Tài liệu này mô tả các **triệu chứng cụ thể** khi gặp lỗi Service Discovery trong Kubernetes, giúp nhanh chóng xác định và khắc phục vấn đề.

---

## ❌ Lỗi 1: DNS không resolve Service Name

### Triệu chứng quan sát được:

**1. Error trong pod logs:**
```
Error: getaddrinfo ENOTFOUND postgres
Error: getaddrinfo EAI_AGAIN postgres
getaddrinfo ENOTFOUND postgres.bloodbank.svc.cluster.local
```

**2. Application crash với message:**
```
Cannot connect to database
Connection refused: Unknown host 'postgres'
dial tcp: lookup postgres: no such host
```

**3. Pod status:**
```powershell
kubectl get pods -n bloodbank
# Output:
NAME                        READY   STATUS             RESTARTS
backend-xxx                 1/2     CrashLoopBackOff   5
```

**4. Test nslookup từ pod FAIL:**
```powershell
kubectl exec -it backend-xxx -n bloodbank -- nslookup postgres
# Output:
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

nslookup: can't resolve 'postgres'
```

### Nguyên nhân:
- Service chưa được tạo hoặc tên sai
- CoreDNS pod không chạy
- NetworkPolicy block DNS traffic (port 53)

### Cách fix:
```powershell
# 1. Kiểm tra service có tồn tại
kubectl get svc -n bloodbank

# 2. Kiểm tra CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 3. Tạo service nếu thiếu
kubectl apply -f k8s/base/services.yaml
```

---

## ❌ Lỗi 2: DNS resolve OK nhưng không connect được

### Triệu chứng quan sát được:

**1. Error trong pod logs:**
```
Error: connect ECONNREFUSED 10.96.1.5:5432
Error: Connection refused
dial tcp 10.96.1.5:5432: connect: connection refused
```

**2. nslookup THÀNH CÔNG:**
```powershell
kubectl exec -it backend-xxx -n bloodbank -- nslookup postgres
# Output:
Name:      postgres
Address 1: 10.96.1.5 postgres.bloodbank.svc.cluster.local
# ✅ DNS OK
```

**3. Nhưng nc test FAIL:**
```powershell
kubectl exec -it backend-xxx -n bloodbank -- nc -zv postgres 5432
# Output:
postgres (10.96.1.5:5432): Connection refused
# ❌ Port không mở
```

**4. Service có endpoints EMPTY:**
```powershell
kubectl get endpoints postgres -n bloodbank
# Output:
NAME       ENDPOINTS
postgres   <none>
# ❌ Không có pod nào behind service
```

### Nguyên nhân:
- Service selector không match pod labels
- Pod chưa ready (failing health checks)
- Pod đang ở trạng thái CrashLoopBackOff

### Cách fix:
```powershell
# 1. Check selector vs labels
kubectl describe svc postgres -n bloodbank | findstr Selector
kubectl get pods -n bloodbank --show-labels

# 2. Check pod status
kubectl get pods -n bloodbank -l component=database

# 3. Fix labels trong deployment
# Đảm bảo labels match với service selector
```

---

## ❌ Lỗi 3: Connection timeout (không phải refused)

### Triệu chứng quan sát được:

**1. Error trong logs:**
```
Error: connect ETIMEDOUT
Error: dial tcp 10.96.1.5:5432: i/o timeout
context deadline exceeded
```

**2. Không có "Connection refused", chỉ timeout sau 30s-60s**

**3. nc test hang và timeout:**
```powershell
kubectl exec -it backend-xxx -n bloodbank -- nc -zv postgres 5432
# Output:
(hangs for 30 seconds)
nc: postgres (10.96.1.5:5432): Operation timed out
```

**4. Pod logs show retry attempts:**
```
Attempting to connect to postgres...
Retry 1/5...
Retry 2/5...
Retry 3/5...
Failed after 5 retries
```

### Nguyên nhân:
- **NetworkPolicy blocking traffic**
- Firewall rules
- Service port mapping sai

### Cách fix:
```powershell
# 1. Tạm disable NetworkPolicy để test
kubectl delete networkpolicy postgres-netpol -n bloodbank

# 2. Test lại connection
kubectl exec -it backend-xxx -n bloodbank -- nc -zv postgres 5432

# 3. Nếu OK → vấn đề là NetworkPolicy
# Check và fix policy rules
kubectl describe networkpolicy postgres-netpol -n bloodbank

# 4. Re-apply correct policy
kubectl apply -f k8s/base/network-policies.yaml
```

---

## ❌ Lỗi 4: Cross-namespace connection fail

### Triệu chứng quan sát được:

**1. Backend không connect được Vault:**
```
Error: getaddrinfo ENOTFOUND vault
Error: Unable to connect to Vault at http://vault:8200
```

**2. Vault ở namespace khác (vault) với backend (bloodbank)**

**3. Short name "vault" không work:**
```powershell
kubectl exec -it backend-xxx -n bloodbank -- nslookup vault
# Output:
nslookup: can't resolve 'vault'
# ❌ FAIL - tìm trong bloodbank namespace, không có
```

**4. Full name WORK:**
```powershell
kubectl exec -it backend-xxx -n bloodbank -- nslookup vault.vault.svc.cluster.local
# Output:
Name:      vault.vault.svc.cluster.local
Address 1: 10.96.2.10
# ✅ OK với full DNS name
```

### Nguyên nhân:
- Thiếu namespace trong service name
- DNS search path không bao gồm namespace khác

### Cách fix:
```yaml
# Trong backend-deployment.yaml
env:
  - name: VAULT_ADDR
    value: "http://vault.vault.svc.cluster.local:8200"
    # PHẢI có .vault (namespace)
```

---

## ❌ Lỗi 5: Environment variable không đúng

### Triệu chứng quan sát được:

**1. Application logs:**
```
Error: Invalid connection string
TypeError: Cannot read property 'host' of undefined
DATABASE_HOST is undefined
```

**2. Pod logs show missing env:**
```
Starting application...
Config: {
  host: undefined,
  port: undefined,
  database: undefined
}
Error: Missing required environment variables
```

**3. Check env vars trong pod:**
```powershell
kubectl exec -it backend-xxx -n bloodbank -- env | grep DATABASE
# Output:
(empty or không có DATABASE_HOST)
```

**4. ConfigMap/Secret có data nhưng không inject:**
```powershell
kubectl get configmap backend-config -n bloodbank -o yaml
# Data có đủ

kubectl describe pod backend-xxx -n bloodbank
# Nhưng không thấy trong Env
```

### Nguyên nhân:
- ConfigMap/Secret reference sai tên
- Key trong configMapKeyRef không tồn tại
- Vault annotations sai format

### Cách fix:
```powershell
# 1. Verify ConfigMap data
kubectl get configmap backend-config -n bloodbank -o yaml

# 2. Check deployment env config
kubectl get deployment backend -n bloodbank -o yaml | grep -A 20 env

# 3. Fix deployment
# Đảm bảo configMapKeyRef.key khớp với data trong ConfigMap

# 4. Restart pods
kubectl rollout restart deployment/backend -n bloodbank
```

---

## ❌ Lỗi 6: Port mapping sai

### Triệu chứng quan sát được:

**1. Error khi call API:**
```
Error: connect ECONNREFUSED 10.96.1.5:3000
fetch failed: http://backend:3000/api/donors
```

**2. Service có port 3000 nhưng container listen 8080:**

**3. curl từ pod fail:**
```powershell
kubectl exec -it frontend-xxx -n bloodbank -- curl http://backend:3000/health
# Output:
curl: (7) Failed to connect to backend port 3000: Connection refused
```

**4. Nhưng curl với port 8080 OK:**
```powershell
kubectl exec -it frontend-xxx -n bloodbank -- curl http://backend:8080/health
# Output:
{"status": "ok"}
# ✅ Container đang listen 8080, không phải 3000
```

### Nguyên nhân:
- Service `port` không khớp với container `containerPort`
- Service `targetPort` không đúng

### Cách fix:
```yaml
# Trong services.yaml
spec:
  ports:
    - port: 3000         # Port client dùng
      targetPort: 8080   # Port container listen
      protocol: TCP

# HOẶC fix container để listen đúng port
# Trong backend-deployment.yaml
containers:
  - name: backend
    ports:
      - containerPort: 3000  # Phải khớp với app
```

---

## ✅ Quick Diagnostic Commands

```powershell
# 1. Check tất cả services
kubectl get svc -A

# 2. Check endpoints
kubectl get endpoints -n bloodbank

# 3. Test DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n bloodbank -- nslookup postgres

# 4. Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n bloodbank -- nc -zv postgres 5432

# 5. Check NetworkPolicies
kubectl get networkpolicies -n bloodbank

# 6. CoreDNS status
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 7. Pod env vars
kubectl exec <pod> -n bloodbank -- env | grep DATABASE

# 8. Service details
kubectl describe svc postgres -n bloodbank
```

---

## 📊 Decision Tree

```
Connection không work?
├─ Error: "ENOTFOUND" / "no such host"
│  └─ → Lỗi DNS (Lỗi 1)
│     └─ Check: CoreDNS, Service name, NetworkPolicy (DNS port 53)
│
├─ Error: "ECONNREFUSED"
│  └─ DNS OK, port không mở
│     ├─ Endpoints empty? → Lỗi 2 (selector sai)
│     └─ Endpoints có → Lỗi 6 (port mapping sai)
│
├─ Error: "ETIMEDOUT" / "context deadline"
│  └─ → Lỗi 3 (NetworkPolicy block)
│     └─ Check: NetworkPolicies, Firewall
│
├─ Error cross-namespace
│  └─ → Lỗi 4 (thiếu namespace)
│     └─ Fix: Dùng full DNS name
│
└─ Error: "undefined" / "missing env"
   └─ → Lỗi 5 (env vars)
      └─ Check: ConfigMap, Secret, Vault
```

---

## 🎯 Tổng kết

| Lỗi | Triệu chứng chính | Fix nhanh |
|-----|------------------|-----------|
| **DNS** | ENOTFOUND | `kubectl get svc` |
| **Selector** | ECONNREFUSED + empty endpoints | Check labels |
| **NetworkPolicy** | ETIMEDOUT | Delete policy test |
| **Cross-NS** | Can't find service | Add `.namespace` |
| **Env vars** | undefined | Check ConfigMap |
| **Port** | ECONNREFUSED + có endpoints | Check targetPort |

---

**Lưu file này để reference khi troubleshoot!** 📖
