# Kubernetes Templates

Kustomize-based Kubernetes manifests for .NET services.

---

## Directory Structure

```
tools/kubernetes/
├── kustomization.yaml      # References all overlays
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── integration/
    │   ├── kustomization.yaml
    │   └── base/
    │       ├── kustomization.yaml
    │       └── deployment.yaml
    ├── testing/
    ├── staging/
    └── production/
```

---

## Base Templates

### base/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
```

### base/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $(APPLICATION_NAME)
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $(APPLICATION_NAME)
  template:
    metadata:
      labels:
        app: $(APPLICATION_NAME)
    spec:
      nodeSelector:
        cloud.google.com/gke-nodepool: standard
      enableServiceLinks: false
      imagePullSecrets:
      - name: github-dockerconfigjson
      containers:
      - name: $(APPLICATION_NAME)
        image: $(IMAGE)
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          protocol: TCP
          name: http
        - containerPort: 8081
          protocol: TCP
          name: https
        livenessProbe:
          httpGet:
            path: /healthz/live
            port: 8080
            httpHeaders:
            - name: probe
              value: liveness
          initialDelaySeconds: 0
          timeoutSeconds: 1
          periodSeconds: 60
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /healthz/ready
            port: 8080
            httpHeaders:
            - name: probe
              value: readiness
          initialDelaySeconds: 5
          timeoutSeconds: 1
          periodSeconds: 180
          failureThreshold: 3
        resources:
          requests:
            memory: 512Mi
            cpu: 500m
            ephemeral-storage: "1Gi"
          limits:
            memory: 1024Mi
            cpu: 1000m
            ephemeral-storage: "2Gi"
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: Development
        volumeMounts:
        - name: secret-volume
          mountPath: /app/configuration/secret
        - name: configmap-volume
          mountPath: /app/configuration/configmap
      volumes:
      - name: secret-volume
        secret:
          secretName: $(APPLICATION_NAME)
      - name: configmap-volume
        configMap:
          name: $(APPLICATION_NAME)
      terminationGracePeriodSeconds: 60
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0%
      maxUnavailable: 100%
```

### base/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: $(APPLICATION_NAME)
spec:
  type: ClusterIP
  selector:
    app: $(APPLICATION_NAME)
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
```

---

## Root Kustomization

### kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ./overlays/integration
- ./overlays/testing
- ./overlays/staging
- ./overlays/production
```

---

## Environment Overlays

### overlays/{environment}/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ./base
- ./default
```

### overlays/{environment}/base/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../../base
patches:
- path: deployment.yaml
```

### overlays/{environment}/base/deployment.yaml

Environment-specific patches:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $(APPLICATION_NAME)
spec:
  template:
    spec:
      containers:
      - name: $(APPLICATION_NAME)
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: Integration  # or Testing, Staging, Production
```

---

## Environment-Specific Resource Limits

### Integration/Testing

```yaml
resources:
  requests:
    memory: 512Mi
    cpu: 500m
  limits:
    memory: 1024Mi
    cpu: 1000m
```

### Staging

```yaml
resources:
  requests:
    memory: 512Mi
    cpu: 500m
  limits:
    memory: 1024Mi
    cpu: 1000m
```

### Production

```yaml
resources:
  requests:
    memory: 512Mi
    cpu: 500m
  limits:
    memory: 2048Mi
    cpu: 2000m
```

---

## Variable Substitution

Variables are substituted during deployment (typically in CI/CD):

| Variable | Purpose | Example |
|----------|---------|---------|
| `$(APPLICATION_NAME)` | Service identifier | `my-service` |
| `$(IMAGE)` | Container image with tag | `ghcr.io/org/my-service:1.0.0` |

### GitHub Actions Example

```yaml
- name: Deploy
  run: |
    export APPLICATION_NAME=my-service
    export IMAGE=ghcr.io/org/my-service:${{ github.sha }}
    envsubst < deployment.yaml | kubectl apply -f -
```

---

## Adding New Environments

1. Create `overlays/{new-env}/` directory
2. Copy structure from existing environment
3. Update `ASPNETCORE_ENVIRONMENT` value
4. Adjust resource limits as needed
5. Add to root `kustomization.yaml`
