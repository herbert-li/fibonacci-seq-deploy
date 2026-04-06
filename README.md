# Fibonacci API - OpenShift Deployment with ArgoCD

GitOps repository for deploying the Fibonacci API to OpenShift 4.19 using ArgoCD.

## Repository Structure

```
fibonacci-seq-deploy/
├── argocd/
│   ├── bootstrap/          # App of Apps bootstrap
│   │   └── app-of-apps.yaml
│   ├── applications/       # ArgoCD Application manifests
│   │   ├── fibonacci-dev.yaml
│   │   ├── fibonacci-test.yaml
│   │   └── fibonacci-prod.yaml
│   └── projects/
│       └── fibonacci-project.yaml
├── base/                   # Base Kubernetes manifests
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── route.yaml         # OpenShift Route
│   ├── hpa.yaml           # Horizontal Pod Autoscaler
│   └── pdb.yaml           # Pod Disruption Budget
├── overlays/               # Environment-specific configurations
│   ├── dev/
│   ├── test/
│   └── prod/
└── scripts/
    ├── deploy-bootstrap.sh # Deploy bootstrap app
    ├── preview-manifests.sh
    ├── sync-argocd.sh
    ├── update-image.sh
    └── verify-manifests.sh
```

## Environments

| Environment | Namespace | URL | Replicas | Resources |
|-------------|-----------|-----|----------|-----------|
| Development | fibonacci-dev | fibonacci-dev.apps.cluster.example.com | 1-3 | 128Mi-256Mi / 100m-200m |
| Test | fibonacci-test | fibonacci-test.apps.cluster.example.com | 2-5 | 256Mi-512Mi / 200m-500m |
| Production | fibonacci-prod | fibonacci.apps.cluster.example.com | 3-10 | 512Mi-1Gi / 500m-1000m |

## Prerequisites

1. **OpenShift 4.19 Cluster** with cluster-admin access
2. **ArgoCD** installed in the cluster
3. **Container Image** pushed to a registry accessible from OpenShift
4. **Git Repository** access configured in ArgoCD

## Initial Setup

### 1. Create Namespaces

```bash
oc new-project fibonacci-dev
oc new-project fibonacci-test
oc new-project fibonacci-prod
```

### 2. Configure Image Pull Secret (if using private registry)

```bash
# For each namespace
for ns in fibonacci-dev fibonacci-test fibonacci-prod; do
  oc create secret docker-registry regcred \
    --docker-server=<registry-url> \
    --docker-username=<username> \
    --docker-password=<password> \
    --docker-email=<email> \
    -n $ns
done
```

### 3. Update Git Repository URLs

Update the repository URL in these files:
```bash
# Update all application manifests
vim argocd/bootstrap/app-of-apps.yaml
vim argocd/applications/fibonacci-*.yaml
```

### 4. Deploy Using Bootstrap Application (Recommended)

**App of Apps Pattern** - Automatically deploys AppProject and all Applications:

```bash
./scripts/deploy-bootstrap.sh
```

This creates a `fibonacci-bootstrap` application that manages:
- AppProject: `fibonacci`
- Applications: `fibonacci-dev`, `fibonacci-test`, `fibonacci-prod`

**Manual Alternative**:
```bash
# Deploy AppProject first
oc apply -f argocd/projects/fibonacci-project.yaml

# Then deploy Applications
oc apply -f argocd/applications/fibonacci-dev.yaml
oc apply -f argocd/applications/fibonacci-test.yaml
oc apply -f argocd/applications/fibonacci-prod.yaml
```

## ArgoCD Configuration

### Access ArgoCD UI

```bash
# Get ArgoCD server URL
oc get route argocd-server -n argocd

# Get admin password
oc get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

### Sync Applications

```bash
# Via CLI
argocd app sync fibonacci-dev
argocd app sync fibonacci-test
argocd app sync fibonacci-prod

# Or enable auto-sync in the Application manifests
```

## Deployment Pipeline

### CI/CD Flow

1. **CI Pipeline** (GitHub Actions):
   - Runs tests
   - Builds Docker image
   - Pushes image with tags: `latest`, `$GITHUB_SHA`, `$ENV-latest`
   - Updates image tag in this repository (optional)

2. **CD Pipeline** (ArgoCD):
   - Monitors this Git repository
   - Detects changes to manifests
   - Syncs changes to OpenShift cluster
   - Performs health checks

### Updating Image Tags

**Option 1: Manual Update**
```bash
cd overlays/prod
kustomize edit set image fibonacci-api=<registry>/fibonacci-api:v1.2.3
git commit -am "Update prod to v1.2.3"
git push
```

**Option 2: Automated via CI**
The CI pipeline can update kustomization.yaml files automatically using tools like:
- `kustomize edit set image`
- ArgoCD Image Updater
- Flux Image Automation

## Horizontal Pod Autoscaling

HPA is configured to scale based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)

### Monitor HPA

```bash
# Watch HPA status
oc get hpa -n fibonacci-prod -w

# View metrics
oc describe hpa fibonacci-api -n fibonacci-prod
```

## Pod Disruption Budget

PDB ensures high availability during:
- Node maintenance
- Cluster upgrades
- Voluntary disruptions

Configuration:
- **Dev**: minAvailable: 1
- **Test**: minAvailable: 1
- **Prod**: minAvailable: 2

## Testing the Deployment

```bash
# Get route URL
ROUTE=$(oc get route fibonacci-api -n fibonacci-prod -o jsonpath='{.spec.host}')

# Test API
curl "http://$ROUTE/fibonacci?n=10"
# Expected: {"result": 55}

curl "http://$ROUTE/health"
# Expected: {"status": "healthy"}
```

## Load Testing

```bash
# Install hey (HTTP load testing tool)
# On macOS: brew install hey

# Run load test
hey -z 60s -c 50 -q 10 "http://$ROUTE/fibonacci?n=100"
```

Watch the HPA scale up pods during the load test:
```bash
watch oc get hpa,pods -n fibonacci-prod
```

## Monitoring and Observability

### View Logs

```bash
# All pods in namespace
oc logs -l app=fibonacci-api -n fibonacci-prod --tail=100 -f

# Specific pod
oc logs <pod-name> -n fibonacci-prod -f
```

### Application Metrics

```bash
# Pod metrics
oc adm top pods -n fibonacci-prod

# Node metrics
oc adm top nodes
```

### ArgoCD Health Status

```bash
# View application health
argocd app get fibonacci-prod

# View sync history
argocd app history fibonacci-prod
```

## Rollback Procedures

### Via ArgoCD

```bash
# List history
argocd app history fibonacci-prod

# Rollback to specific revision
argocd app rollback fibonacci-prod <revision-number>
```

### Via Git

```bash
# Revert to previous commit
git revert HEAD
git push

# ArgoCD will automatically sync the rollback
```

## Troubleshooting

### Application Not Syncing

```bash
# Check ArgoCD application status
argocd app get fibonacci-prod

# Force sync
argocd app sync fibonacci-prod --force

# Check for sync errors
oc describe application fibonacci-prod -n argocd
```

### Pods Not Scaling

```bash
# Check HPA events
oc describe hpa fibonacci-api -n fibonacci-prod

# Verify metrics server
oc get apiservice v1beta1.metrics.k8s.io

# Check pod resource requests are set
oc get pod <pod-name> -n fibonacci-prod -o yaml | grep -A 5 resources
```

### Image Pull Errors

```bash
# Check image pull secret
oc get secret regcred -n fibonacci-prod

# Check pod events
oc describe pod <pod-name> -n fibonacci-prod

# Verify image exists
oc debug deployment/fibonacci-api -n fibonacci-prod -- sh -c "curl -I <registry-url>"
```

## Security Considerations

1. **Image Security**: Use signed and scanned images
2. **RBAC**: Limit namespace access via OpenShift RBAC
3. **Network Policies**: Implement network segmentation
4. **Secrets Management**: Use OpenShift Secrets or external secret managers (e.g., Vault)
5. **Pod Security**: Run as non-root user (already configured in Dockerfile)

## Maintenance

### Updating Kubernetes Manifests

1. Make changes to base or overlay files
2. Test locally: `kustomize build overlays/prod`
3. Commit and push changes
4. ArgoCD will detect and sync changes

### OpenShift Cluster Upgrades

- PDB ensures pods remain available during upgrades
- Test upgrades in dev/test before prod
- Monitor application health during upgrades

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [OpenShift 4.19 Documentation](https://docs.openshift.com/)
- [Kustomize Documentation](https://kustomize.io/)
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
