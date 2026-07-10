# Kubernetes Templates

Kustomize-based Kubernetes manifests for .NET services.

---

## Directory Structure

```
tools/Kubernetes/
├── kustomization.yaml      # References all overlays
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── repo/
│   └── kustomization.yaml  # Image transform layer — CI rewrites the tag via `kustomize edit set image`
└── overlays/
    ├── integration/
    │   ├── kustomization.yaml
    │   ├── base/
    │   │   ├── kustomization.yaml
    │   │   └── deployment.yaml
    │   └── default/            # Default variant — kustomization.yaml + patches
    ├── testing/
    ├── staging/
    └── production/
```

Per `solution-structure`, each environment overlay contains `{base,default,alternative}` variants. `default/` holds the default variant's kustomization and patches.

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
  name: {APPLICATION_NAME}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: {APPLICATION_NAME}
  template:
    metadata:
      labels:
        app: {APPLICATION_NAME}
    spec:
      nodeSelector:
        cloud.google.com/gke-nodepool: standard
      enableServiceLinks: false
      imagePullSecrets:
      - name: github-dockerconfigjson
      containers:
      - name: {APPLICATION_NAME}
        image: app-image:latest
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
        startupProbe:
          httpGet:
            path: /healthz/startup
            port: 8080
            httpHeaders:
            - name: probe
              value: startup
          initialDelaySeconds: 0
          timeoutSeconds: 1
          periodSeconds: 10
          failureThreshold: 30
        resources:
          requests:
            memory: 256Mi
            cpu: 250m
            ephemeral-storage: "1Gi"
          limits:
            memory: 512Mi
            cpu: 500m
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
          secretName: {APPLICATION_NAME}
      - name: configmap-volume
        configMap:
          name: {APPLICATION_NAME}
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
  name: {APPLICATION_NAME}
spec:
  type: ClusterIP
  selector:
    app: {APPLICATION_NAME}
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
  name: {APPLICATION_NAME}
spec:
  template:
    spec:
      containers:
      - name: {APPLICATION_NAME}
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: Integration  # or Testing, Staging, Production
```

---

## Environment-Specific Resource Limits

### Integration

```yaml
resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m
```

### Testing

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
| `{APPLICATION_NAME}` | Service identifier — **scaffold-time token**, replaced with the real name when the manifest is generated; nothing substitutes it at deploy time | `my-service` |
| `app-image:latest` | Image placeholder — **deploy-time**, rewritten by `kustomize edit set image` in the `repo/` layer | `ghcr.io/org/my-service:abc123` |

### GitHub Actions Example

Deployment is pure Kustomize — no template substitution at deploy time. CI pins the image in the `repo/` layer, sets the namespace per component, and applies each component of the target environment:

```yaml
- name: Deploy
  shell: pwsh
  run: |
    $environment = "${{ inputs.environment }}";
    $k8sDir = "./tools/Kubernetes";

    # Set image tag in the repo layer
    Push-Location "$k8sDir/repo"
    kustomize edit set image "app-image:latest=${{ env.IMAGE }}:${{ github.sha }}"
    Pop-Location

    # Read components from kustomization.yaml and deploy each one
    $envDir = "$k8sDir/overlays/$environment"
    $components = (Get-Content "$envDir/kustomization.yaml" | Select-String '^\s*-\s+(?!.*://)(.+)' | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }) | Where-Object { $_ -ne 'base' }
    foreach ($componentName in $components) {
      $componentDir = Join-Path $envDir $componentName
      Push-Location $componentDir
      kustomize edit set namespace "${{ env.NAMESPACE_PREFIX }}-$environment"
      Pop-Location

      kubectl kustomize $componentDir | kubectl apply -f -
    }
```

---

## Adding New Environments

1. Create `overlays/{new-env}/` directory
2. Copy structure from existing environment
3. Update `ASPNETCORE_ENVIRONMENT` value
4. Adjust resource limits as needed
5. Add to root `kustomization.yaml`
