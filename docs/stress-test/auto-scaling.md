# Autoscaling Configuration
## 1. Setting Resource Limits

The CPU and memory values below are intentionally low so that even moderate load justifies scaling:

```bash
oc set resources deployment/my-app \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=200m,memory=256Mi
```

| Parameter | Value | Explanation |
|---|---|---|
| CPU request | 100m | 0.1 CPU core — the amount the pod "reserves" |
| CPU limit | 200m | 0.2 CPU core — the maximum a single pod can use |
| Memory request | 128Mi | Minimum guaranteed memory |
| Memory limit | 256Mi | Maximum usable memory |

> CPU: 100m = 100 milli-CPU = 10% usage of a single CPU core

---

## 2. Creating the HorizontalPodAutoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
  namespace: endre-cloud-based-distributed-systems-laboratory
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Pods
          value: 2
          periodSeconds: 30
    scaleDown:
      stabilizationWindowSeconds: 120
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
```

| Parameter | Value | Explanation |
|---|---|---|
| `minReplicas` | 1 | At least 1 pod always running |
| `maxReplicas` | 5 | At most 5 parallel pods |
| `averageUtilization` | 50% | Scale up when average CPU exceeds 100m (50% of 200m limit) |
| `scaleUp.stabilizationWindowSeconds` | 30 s | Scale up after 30 s of sustained high load |
| `scaleUp.value` | 2 pods / 30 s | At most 2 new pods started at once |
| `scaleDown.stabilizationWindowSeconds` | 120 s | Scale down after 2 min of low load |
| `scaleDown.value` | 1 pod / 60 s | Remove 1 pod per minute when scaling down |

---

## 3. Verify settings

**Current HPA status**
```bash
oc get hpa my-app-hpa -o yaml
```

**Status and events**
```bash
oc describe hpa my-app-hpa
```

**Pod count in real time**
```bash
watch -n5 'oc get pods -l deployment=my-app'
```

Expected output under load:

```bash
NAME          REFERENCE           TARGETS   MINPODS   MAXPODS   REPLICAS
my-app-hpa    Deployment/my-app   87%/50%   1         5         3
```

---

## 4. Expected load-balancing "workflow":

1. Load increases
2. CPU avg > 50% (100m)
    - 30 s stabilization window
3. HPA: start +2 pods
4. Load decreases
5. CPU avg < 50%
    - 120 s stabilization window
6. HPA: stop -1 pod (per minute)