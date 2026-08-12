# Kubernetes Templates

Kustomize-based Kubernetes manifests for .NET services.

The [canonical Kubernetes directory structure](../../solution-structure/SKILL.md#canonical-kubernetes-directory-structure)
owns every directory and filename. This template supplies manifest content for that exact layout; it does not
introduce another layer or path alias.

---

## Directory Structure

Use the complete tree in
[Canonical Kubernetes directory structure](../../solution-structure/SKILL.md#canonical-kubernetes-directory-structure).
It explicitly enumerates the shared `/tools/Kubernetes/base/` and literal
`overlays/{integration,testing,staging,production}/{base,default,alternative}/` locations. There is no separate
image-transform layer and no environment-level kustomization between an environment directory and its three
components. The manifest bodies below map to those exact files.

## Resolve deployable identity once

Resolve the full `{DeployableProcessName}` from `solution-structure`, then derive
`{DeployableProcessKebabName}` exactly once using the rule in
[the infrastructure skill](../SKILL.md#deployable-identity-and-image-tokens). Every DNS-label field below uses
the derived token; do not shorten the source identity to a service or application nickname.

---

## Base Templates

### /tools/Kubernetes/base/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
```

### /tools/Kubernetes/base/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {DeployableProcessKebabName}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: {DeployableProcessKebabName}
  template:
    metadata:
      labels:
        app: {DeployableProcessKebabName}
    spec:
      nodeSelector:
        cloud.google.com/gke-nodepool: standard
      enableServiceLinks: false
      imagePullSecrets:
      - name: github-dockerconfigjson
      containers:
      - name: {DeployableProcessKebabName}
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
          secretName: {DeployableProcessKebabName}
      - name: configmap-volume
        configMap:
          name: {DeployableProcessKebabName}
      terminationGracePeriodSeconds: 60
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0%
      maxUnavailable: 100%
```

### /tools/Kubernetes/base/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {DeployableProcessKebabName}
spec:
  type: ClusterIP
  selector:
    app: {DeployableProcessKebabName}
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

### /tools/Kubernetes/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ./base
```

---

## Environment Overlays

### Environment base kustomization files

These four exact files share the same composition:

- `/tools/Kubernetes/overlays/integration/base/kustomization.yaml`
- `/tools/Kubernetes/overlays/testing/base/kustomization.yaml`
- `/tools/Kubernetes/overlays/staging/base/kustomization.yaml`
- `/tools/Kubernetes/overlays/production/base/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../../base
patches:
- path: deployment.yaml
- path: service.yaml
```

### Environment base patches

Generate each literal environment's `base/deployment.yaml` and `base/service.yaml` from the complete patch
shapes below. Resolve the content-only tokens with this closed table; they do not change any directory name:

| Directory | `{KubernetesEnvironmentName}` | `{KubernetesEnvironmentLabel}` |
|---|---|---|
| `integration` | `Integration` | `integration` |
| `testing` | `Testing` | `testing` |
| `staging` | `Staging` | `staging` |
| `production` | `Production` | `production` |

#### Environment `base/deployment.yaml`

The deployment patch targets the full deployable process, sets its matching ASP.NET Core environment, and
includes the matching resource block from [Environment-Specific Resource Limits](#environment-specific-resource-limits)
under the container. Do not leave either environment token unresolved in a committed file.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {DeployableProcessKebabName}
  labels:
    deployment-environment: {KubernetesEnvironmentLabel}
spec:
  template:
    metadata:
      labels:
        deployment-environment: {KubernetesEnvironmentLabel}
    spec:
      containers:
      - name: {DeployableProcessKebabName}
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: {KubernetesEnvironmentName}
        # Insert this environment's complete resources block from the section below.
```

#### Environment `base/service.yaml`

The service patch targets the same full deployable process and records the literal environment without
renaming the Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {DeployableProcessKebabName}
  labels:
    deployment-environment: {KubernetesEnvironmentLabel}
```

### Selectable component kustomization files

The selected component is one of these exact directories, each layered on its sibling `base`:

- `/tools/Kubernetes/overlays/integration/default/`
- `/tools/Kubernetes/overlays/integration/alternative/`
- `/tools/Kubernetes/overlays/testing/default/`
- `/tools/Kubernetes/overlays/testing/alternative/`
- `/tools/Kubernetes/overlays/staging/default/`
- `/tools/Kubernetes/overlays/staging/alternative/`
- `/tools/Kubernetes/overlays/production/default/`
- `/tools/Kubernetes/overlays/production/alternative/`

Each component's `kustomization.yaml` uses this shape. Its local `deployment.yaml` and `service.yaml` use the
complete patch shapes below. Resolve `{KubernetesVariantName}` to the literal directory name, `default` or
`alternative`; do not leave it unresolved in a committed file.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../base
patches:
- path: deployment.yaml
- path: service.yaml
```

#### Selectable component `deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {DeployableProcessKebabName}
  labels:
    deployment-variant: {KubernetesVariantName}
spec:
  template:
    metadata:
      labels:
        deployment-variant: {KubernetesVariantName}
```

#### Selectable component `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {DeployableProcessKebabName}
  labels:
    deployment-variant: {KubernetesVariantName}
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

## Scaffold-time identity and deploy-time image pinning

Resolve `{DeployableProcessName}` and `{DeployableProcessKebabName}` while scaffolding; committed manifests
contain their literal resolved values. At deployment time, CI changes only deploy-time state: it pins
`app-image:latest` and sets the namespace in the actual selected component kustomization.

### GitHub Actions Example

Deployment is pure Kustomize—no identity-template substitution occurs at deploy time. The workflow validates
the exact environment and component names, edits that selected component's `kustomization.yaml`, and applies
that same component:

```yaml
- name: Deploy
  shell: pwsh
  run: |
    $environmentName = "${{ inputs.environment }}"
    $componentName = "${{ inputs.component }}"
    $allowedEnvironmentNames = @("integration", "testing", "staging", "production")
    $allowedComponentNames = @("default", "alternative")

    if ($environmentName -notin $allowedEnvironmentNames) {
      throw "Unsupported Kubernetes environment: $environmentName"
    }
    if ($componentName -notin $allowedComponentNames) {
      throw "Unsupported Kubernetes component: $componentName"
    }

    $kubernetesRoot = "./tools/Kubernetes"
    $selectedComponentDirectory = Join-Path $kubernetesRoot "overlays/$environmentName/$componentName"
    $selectedKustomization = Join-Path $selectedComponentDirectory "kustomization.yaml"
    if (-not (Test-Path -LiteralPath $selectedKustomization -PathType Leaf)) {
      throw "Selected Kubernetes kustomization does not exist: $selectedKustomization"
    }

    Push-Location $selectedComponentDirectory
    try {
      kustomize edit set image "app-image:latest=${{ env.IMAGE }}:${{ github.sha }}"
      kustomize edit set namespace "${{ env.NAMESPACE_PREFIX }}-$environmentName"
      kubectl kustomize . | kubectl apply -f -
    }
    finally {
      Pop-Location
    }
```

---

## Maintaining supported overlays

- Keep `integration`, `testing`, `staging`, and `production` aligned with the exact structure in
  `solution-structure`.
- Keep both `default` and `alternative` selectable beneath every environment's `base`.
- If the canonical environment set ever changes, update `solution-structure` first; this content template
  follows that authority.
