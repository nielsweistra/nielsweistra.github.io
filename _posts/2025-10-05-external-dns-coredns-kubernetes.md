---
layout: post
title: "External DNS with CoreDNS: Static and Dynamic Zones in Kubernetes"
date: 2025-10-05 19:00:00 +0200
categories: kubernetes dns coredns networking
tags: [kubernetes, dns, coredns, networking, devops, infrastructure]
---

In this post, I'll walk you through setting up external DNS access using CoreDNS in Kubernetes with both static and dynamic DNS zones. This setup allows you to expose your internal services via custom domain names that can be resolved from outside your cluster.

## 🎯 Overview

We'll create:
- **Static DNS zone**: `int.itlusions.com` for infrastructure services
- **Dynamic DNS zone**: `dyn.int.itlusions.com` for dynamically managed records
- **External access**: Via MetalLB LoadBalancer
- **Volume mounts**: Proper ConfigMap mounting for zone files

## 🏗️ Architecture

```
External Clients
       ↓
   10.99.99.21 (LoadBalancer)
       ↓
   CoreDNS Pods
       ↓
   Zone Files (ConfigMaps)
   ├── Static: int.itlusions.com
   └── Dynamic: dyn.int.itlusions.com
```

## 📋 Prerequisites

- Kubernetes cluster with CoreDNS
- MetalLB or similar LoadBalancer implementation
- kubectl access with cluster-admin permissions

## 🔧 Step 1: MetalLB IP Pool Configuration

First, create a dedicated IP pool for DNS services:

```yaml
# dns-pool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dns-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.99.99.10-10.99.99.15
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: dns-pool-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - dns-pool
  nodeSelectors:
  - matchLabels:
      kubernetes.io/os: linux
```

## 🗂️ Step 2: Static Zone Configuration

Create the static zone for your infrastructure services:

```yaml
# coredns-custom-zones.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom-zones
  namespace: kube-system
  labels:
    app: coredns
    component: zones
data:
  # Static zone file for int.itlusions.com
  db.int.itlusions.com: |
    $ORIGIN int.itlusions.com.
    $TTL 300
    @       IN      SOA     ns1.int.itlusions.com. admin.itlusions.com. (
                            2024100501  ; serial (YYYYMMDDNN)
                            3600        ; refresh (1 hour)
                            1800        ; retry (30 minutes)
                            604800      ; expire (1 week)
                            300         ; minimum TTL (5 minutes)
                            )

    ; Name servers
    @       IN      NS      ns1.int.itlusions.com.
    @       IN      NS      coredns.kube-system.svc.cluster.local.

    ; Infrastructure
    ns1             IN      A       10.99.99.10
    gateway         IN      A       10.99.99.1
    router          IN      A       10.99.99.1

    ; Kubernetes services
    k8s-api         IN      A       10.96.0.1
    k8s-dashboard   IN      A       10.96.1.100
    traefik         IN      A       10.96.1.101

    ; Monitoring stack
    grafana         IN      A       10.96.2.100
    prometheus      IN      A       10.96.2.101
    alertmanager    IN      A       10.96.2.102

    ; Storage and databases
    minio           IN      A       10.96.3.100
    postgresql      IN      A       10.96.3.101
    redis           IN      A       10.96.3.102

    ; CNAME aliases for convenience
    monitoring      IN      CNAME   grafana.int.itlusions.com.
    metrics         IN      CNAME   prometheus.int.itlusions.com.
    storage         IN      CNAME   minio.int.itlusions.com.

    ; Wildcard for dynamic services
    *.apps          IN      A       10.96.5.100
    *.dev           IN      A       10.96.6.100
    *.test          IN      A       10.96.7.100
```

## ⚡ Step 3: Dynamic Zone Configuration

Create the dynamic zone with proper SOA record:

```yaml
# coredns-dynamic-zones.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-dynamic-zones
  namespace: kube-system
  labels:
    app: coredns
    component: dynamic-zones
data:
  db.dyn.int.itlusions.com: |
    $ORIGIN dyn.int.itlusions.com.
    $TTL 60
    @       IN      SOA     ns1.int.itlusions.com. admin.itlusions.com. (
                            2025100501  ; serial (YYYYMMDDNN)
                            300         ; refresh (5 minutes - short for dynamic)
                            180         ; retry (3 minutes)
                            86400       ; expire (1 day)
                            60          ; minimum TTL (1 minute - short for dynamic)
                            )

    ; Name servers
    @       IN      NS      ns1.int.itlusions.com.
    @       IN      NS      coredns.kube-system.svc.cluster.local.

    ; Dynamic records will be added here automatically
```

## 🌐 Step 4: External Access LoadBalancer

Create a LoadBalancer service to expose CoreDNS externally:

```yaml
# coredns-external-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: coredns-external
  namespace: kube-system
  labels:
    app: coredns
    component: external-access
  annotations:
    metallb.universe.tf/address-pool: dns-pool
    metallb.universe.tf/ip-allocated-from-pool: dns-pool
spec:
  type: LoadBalancer
  loadBalancerIP: 10.99.99.21
  loadBalancerSourceRanges:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
  selector:
    k8s-app: kube-dns
  ports:
  - name: dns-udp
    port: 53
    protocol: UDP
    targetPort: 53
  - name: dns-tcp
    port: 53
    protocol: TCP
    targetPort: 53
```

## 🔧 Step 5: CoreDNS Configuration

Update the CoreDNS configuration to include your custom zones:

```yaml
# coredns-config-patch.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        
        # Static custom zone for int.itlusions.com
        file /etc/coredns/zones/db.int.itlusions.com int.itlusions.com {
            reload 30s
        }
        
        # Dynamic zone for dyn.int.itlusions.com (auto-reload when changed)
        auto dyn.int.itlusions.com {
            directory /etc/coredns/dynamic
            reload 10s
        }
        
        # Kubernetes cluster DNS
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        
        # Prometheus metrics
        prometheus :9153
        
        # Forward external queries
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        
        cache 30
        loop
        reload
        loadbalance
    }
```

## 📁 Step 6: CoreDNS Deployment Volume Mounts

The crucial part is properly mounting the ConfigMaps as volumes in CoreDNS pods:

```yaml
# coredns-deployment-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
spec:
  template:
    spec:
      containers:
      - name: coredns
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        - name: custom-zones
          mountPath: /etc/coredns/zones
          readOnly: true
        - name: dynamic-zones
          mountPath: /etc/coredns/dynamic
          readOnly: false
      volumes:
      - name: config-volume
        configMap:
          name: coredns
          items:
          - key: Corefile
            path: Corefile
      - name: custom-zones
        configMap:
          name: coredns-custom-zones
          defaultMode: 0644
      - name: dynamic-zones
        configMap:
          name: coredns-dynamic-zones
          defaultMode: 0644
```

## 🚀 Step 7: Deployment Commands

Deploy everything in the correct order:

```bash
# 1. Create IP pool
kubectl apply -f dns-pool.yaml

# 2. Create zone ConfigMaps
kubectl apply -f coredns-custom-zones.yaml
kubectl apply -f coredns-dynamic-zones.yaml

# 3. Update CoreDNS configuration
kubectl apply -f coredns-config-patch.yaml

# 4. Patch CoreDNS deployment for volume mounts
kubectl patch deployment coredns -n kube-system --patch-file coredns-deployment-patch.yaml

# 5. Create external LoadBalancer service
kubectl apply -f coredns-external-service.yaml

# 6. Restart CoreDNS to pick up changes
kubectl rollout restart deployment/coredns -n kube-system
```

## 🧪 Step 8: Testing

Test your DNS setup:

```bash
# Test static zone
nslookup k8s-api.int.itlusions.com 10.99.99.21

# Test dynamic zone (after adding records)
nslookup myapp.dyn.int.itlusions.com 10.99.99.21

# Check CoreDNS logs
kubectl logs -l k8s-app=kube-dns -n kube-system
```

Expected output for static zone:
```
Server:         10.99.99.21
Address:        10.99.99.21#53

Name:   k8s-api.int.itlusions.com
Address: 10.96.0.1
```

## 🔍 Troubleshooting

### Volume Mount Issues
- Ensure ConfigMaps exist before patching deployment
- Check that volume names match between mounts and volumes
- Verify file permissions (0644 for zone files)

### Zone Loading Errors
```bash
# Check for SOA record errors
kubectl logs -l k8s-app=kube-dns -n kube-system | grep SOA

# Verify zone file syntax
kubectl get configmap coredns-custom-zones -n kube-system -o yaml
```

### External Access Issues
- Verify LoadBalancer IP allocation
- Check MetalLB logs
- Test internal resolution first

## 📊 Key Configuration Points

### Volume Mounts Explained

1. **config-volume**: Main CoreDNS configuration (Corefile)
2. **custom-zones**: Static zone files (`/etc/coredns/zones/`)
3. **dynamic-zones**: Dynamic zone files (`/etc/coredns/dynamic/`)

### Zone File Requirements

- **SOA Record**: Mandatory for proper zone loading
- **NS Records**: Define authoritative name servers
- **Serial Number**: Used for zone transfer coordination
- **TTL Values**: Balance between cache efficiency and update speed

### Plugin Configuration

- **file**: For static zones with reload capability
- **auto**: For dynamic zones with automatic reload
- **reload**: Monitors file changes for updates

## 🎯 Best Practices

1. **Use separate ConfigMaps** for static and dynamic zones
2. **Set appropriate TTL values** (low for dynamic, higher for static)
3. **Monitor CoreDNS logs** for configuration errors
4. **Use descriptive resource labels** for easier management
5. **Implement proper RBAC** for zone management scripts

## 🔄 Dynamic Zone Management

For dynamic zones, you can create management scripts that update the ConfigMap:

```bash
# Add a dynamic record
kubectl get configmap coredns-dynamic-zones -n kube-system -o jsonpath='{.data.db\.dyn\.int\.itlusions\.com}' > temp-zone.txt
echo "myapp    IN    A    10.96.10.100" >> temp-zone.txt
kubectl create configmap coredns-dynamic-zones --from-file=db.dyn.int.itlusions.com=temp-zone.txt --dry-run=client -o yaml | kubectl replace -f -
```

## 🎉 You reached the finishline!

This setup provides you with:
- ✅ External DNS access via LoadBalancer
- ✅ Static zone for infrastructure services
- ✅ Dynamic zone for application services
- ✅ Proper volume mounting and configuration
- ✅ Automatic zone reloading

Your DNS infrastructure is now ready to serve both static infrastructure records and dynamically managed application records, accessible from external networks!

> In a future post, I'll dive deeper into managing and automating the dynamic DNS zone, including practical scripts and workflows for updating records.

---

*Tags: kubernetes, dns, coredns, networking, devops, infrastructure, metallb, loadbalancer*