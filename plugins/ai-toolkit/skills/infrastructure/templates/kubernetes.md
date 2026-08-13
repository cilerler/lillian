# Kubernetes Templates

Kustomize-based Kubernetes manifests for .NET deployable processes.

The [canonical Kubernetes directory structure](../../solution-structure/SKILL.md#canonical-kubernetes-directory-structure)
owns every directory and filename. This template owns manifest content for that structure; it does not create
another repository layout. Resolve every identity, environment, and image token through
[Deployable identity and image tokens](../SKILL.md#deployable-identity-and-image-tokens) before applying the
manifest bodies below.

## Base manifests

### `/tools/Kubernetes/base/{DeploymentName}/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```

Add `service.yaml` only when the deployment exposes a stable network Service. Add `configmap.yaml` only when
it has actual non-secret configuration:

```yaml
resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
```

### `/tools/Kubernetes/base/{DeploymentName}/deployment.yaml`

This is the complete restricted baseline. An overlay may change replicas, measured resource values, or role
configuration. Remove a probe only when its endpoint is not mapped. Optional mounts and registry settings are
shown separately below and must not be copied unless used.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "{DeploymentKebabName}"
  labels:
    app.kubernetes.io/name: "{DeploymentKebabName}"
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: "{DeploymentKebabName}"
  template:
    metadata:
      labels:
        app.kubernetes.io/name: "{DeploymentKebabName}"
    spec:
      enableServiceLinks: false
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: "{DeploymentKebabName}"
          image: app-image:latest
          imagePullPolicy: IfNotPresent
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            readOnlyRootFilesystem: true
            runAsNonRoot: true
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /healthz/live
              port: http
            initialDelaySeconds: 0
            timeoutSeconds: 1
            periodSeconds: 60
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /healthz/ready
              port: http
            initialDelaySeconds: 5
            timeoutSeconds: 1
            periodSeconds: 180
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /healthz/startup
              port: http
            initialDelaySeconds: 0
            timeoutSeconds: 1
            periodSeconds: 10
            failureThreshold: 30
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
              ephemeral-storage: 1Gi
            limits:
              cpu: 500m
              memory: 512Mi
              ephemeral-storage: 2Gi
      terminationGracePeriodSeconds: 60
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0%
      maxUnavailable: 100%
```

### Optional `/tools/Kubernetes/base/{DeploymentName}/service.yaml`

Create this only when the deployment exposes a stable network Service. Expose only ports the process actually
listens on. Add an HTTPS port only when TLS terminates in the pod.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: "{DeploymentKebabName}"
  labels:
    app.kubernetes.io/name: "{DeploymentKebabName}"
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: "{DeploymentKebabName}"
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: http
```

### Optional `/tools/Kubernetes/base/{DeploymentName}/configmap.yaml`

Create this file only when there is real non-secret configuration. The example value is a scaffold token, not
permission to commit an empty object or secret.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{DeploymentKebabName}"
  labels:
    app.kubernetes.io/name: "{DeploymentKebabName}"
data:
  appsettings.json: |
    {NonSecretJsonConfiguration}
```

When this ConfigMap exists, add the matching mount to the base Deployment:

```yaml
spec:
  template:
    spec:
      containers:
        - name: "{DeploymentKebabName}"
          volumeMounts:
            - name: configmap-volume
              mountPath: /app/configuration/configmap
              readOnly: true
      volumes:
        - name: configmap-volume
          configMap:
            name: "{DeploymentKebabName}"
```

The base already uses the complete deployment resource identity; overlays never add a role suffix.

## Deployment leaves

Use the literal environment directory names `integration`, `testing`, `staging`, and `production`, but create
only those supported by the product. Beneath an environment, create one overlay per actual `{DeploymentName}`
that also exists under `base/`. Even a single deployment uses this full form.

### `overlays/{KubernetesEnvironmentKebabName}/{DeploymentName}/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../base/{DeploymentName}
patches:
  - path: deployment.yaml
labels:
  - includeSelectors: true
    pairs:
      app.kubernetes.io/environment: "{KubernetesEnvironmentKebabName}"
      app.kubernetes.io/instance: "{DeploymentKebabName}"
```

Add `service.yaml` or `configmap.yaml` to `patches` only when the overlay changes a corresponding resource
that exists in `base/{DeploymentName}`. Do not use `nameSuffix`; the base resource is already named from the
complete deployment identity.

### `overlays/{KubernetesEnvironmentKebabName}/{DeploymentName}/deployment.yaml`

Every deployment overlay sets its literal ASP.NET Core environment and its deployment-specific replicas and
resources. It may also carry the command, arguments, or feature-selection variables that distinguish roles of
the same binary.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "{DeploymentKebabName}"
spec:
  replicas: {ReplicaCount}
  template:
    spec:
      containers:
        - name: "{DeploymentKebabName}"
          env:
            - name: ASPNETCORE_ENVIRONMENT
              value: "{KubernetesEnvironmentName}"
          resources:
            requests:
              cpu: {CpuRequest}
              memory: {MemoryRequest}
              ephemeral-storage: 1Gi
            limits:
              cpu: {CpuLimit}
              memory: {MemoryLimit}
              ephemeral-storage: 2Gi
```

Resolve environment tokens using this closed table; do not leave them in committed manifests:

| `{KubernetesEnvironmentKebabName}` | `{KubernetesEnvironmentName}` | CPU request/limit | Memory request/limit |
|---|---|---|---|
| `integration` | `Integration` | `250m` / `500m` | `256Mi` / `512Mi` |
| `testing` | `Testing` | `500m` / `1000m` | `512Mi` / `1024Mi` |
| `staging` | `Staging` | `500m` / `1000m` | `512Mi` / `1024Mi` |
| `production` | `Production` | `500m` / `2000m` | `512Mi` / `2048Mi` |

These are starting budgets, not reasons to overwrite measured values.

### Optional overlay `service.yaml`

Create this patch only when an environment changes Service type, ports, or annotations. The patch targets the
complete base resource name; no role suffix is applied afterward.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: "{DeploymentKebabName}"
spec:
  type: LoadBalancer
```

### Optional overlay `configmap.yaml`

Create this patch only when `base/{DeploymentName}/configmap.yaml` exists and the selected deployment changes
non-secret values. It targets the base ConfigMap name; never put credentials, keys, tokens, or certificates
here.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{DeploymentKebabName}"
data:
  appsettings.json: |
    {EnvironmentAndDeploymentSpecificNonSecretJsonConfiguration}
```

## Optional Deployment additions

Add these blocks to a deployment base or overlay only when the workload requires them.

### External Secret mount

```yaml
spec:
  template:
    spec:
      containers:
        - name: "{DeploymentKebabName}"
          volumeMounts:
            - name: secret-volume
              mountPath: /app/configuration/secret
              readOnly: true
      volumes:
        - name: secret-volume
          secret:
            secretName: "{SecretName}"
```

### Private image registry

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: "{ImagePullSecretName}"
```

### In-pod HTTPS

Add the container port and matching Service port only when the process is configured to terminate TLS:

```yaml
# Deployment container ports
- name: https
  containerPort: 8081
  protocol: TCP

# Service ports
- name: https
  port: 443
  protocol: TCP
  targetPort: https
```

## Deployment strategy

The base uses a resource-conserving rolling update. Use this leaf patch only when the service requires
zero-downtime deployment and the cluster has capacity for the surge:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "{DeploymentKebabName}"
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0%
```

## CI image pinning and apply

CI changes only deploy-time state. It validates the selected literal environment and complete deployment
identity, pins the image and namespace in that leaf, and applies the same leaf.

```yaml
- name: Deploy
  shell: pwsh
  run: |
    $kubernetesEnvironmentKebabName = "${{ inputs.environment }}"
    $deploymentName = "${{ inputs.deployment }}"
    $allowedKubernetesEnvironmentKebabNames = @("integration", "testing", "staging", "production")

    if ($kubernetesEnvironmentKebabName -notin $allowedKubernetesEnvironmentKebabNames) {
      throw "Unsupported Kubernetes environment: $kubernetesEnvironmentKebabName"
    }
    if ($deploymentName -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$') {
      throw "Invalid complete deployment identity: $deploymentName"
    }

    $selectedDeploymentDirectory = Join-Path "./tools/Kubernetes/overlays/$kubernetesEnvironmentKebabName" $deploymentName
    $selectedKustomization = Join-Path $selectedDeploymentDirectory "kustomization.yaml"
    if (-not (Test-Path -LiteralPath $selectedKustomization -PathType Leaf)) {
      throw "Selected Kubernetes deployment does not exist: $selectedKustomization"
    }

    Push-Location $selectedDeploymentDirectory
    try {
      kustomize edit set image "app-image:latest=${{ env.IMAGE }}:${{ github.sha }}"
      kustomize edit set namespace "${{ env.NAMESPACE_PREFIX }}-$kubernetesEnvironmentKebabName"
      kubectl kustomize . | kubectl apply -f -
    }
    finally {
      Pop-Location
    }
```

The workflow may list fewer allowed environments when the product supports fewer. It must not accept a
shortened deployment alias or synthesize a missing overlay.
