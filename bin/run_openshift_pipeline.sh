#!/bin/bash
set -e

echo "=========================================================="
echo " Starting OpenShift Pipeline & Application Verification"
echo "=========================================================="

echo "=== 1. Inspecting User & Active Namespace ==="
oc whoami
CURRENT_NS=$(oc project -q)
echo "Active Project: $CURRENT_NS"

echo "=== 2. Creating / Verifying PersistentVolumeClaim ==="
oc apply -f .tekton/pvc.yml
oc get pvc oc-lab-pvc

echo "=== 3. Installing Custom Tekton Tasks (cleanup & nose) ==="
kubectl apply -f .tekton/tasks.yml
oc get tasks

echo "=== 4. Applying Tekton CD Pipeline (cd-pipeline) ==="
oc apply -f .tekton/pipeline.yml
oc get pipeline cd-pipeline

echo "=== 5. Running the Pipeline ==="
echo "Starting PipelineRun with shared workspace bound to oc-lab-pvc..."
tkn pipeline start cd-pipeline \
  -w name=output,claimName=oc-lab-pvc \
  -p repo-url="https://github.com/salonitiwari24/ci-cd-final-project.git" \
  -p branch="main" \
  --showlog

echo "=== 6. Checking Application Rollout ==="
oc rollout status deployment/hit-counter --timeout=180s
oc get pods -l app=hit-counter

echo "=== 7. Capturing Application Logs to Evidence File ==="
mkdir -p submission_evidence
oc logs deployment/hit-counter | tee submission_evidence/oc-pipeline-app-logs
cp submission_evidence/oc-pipeline-app-logs ./oc-pipeline-app-logs

echo "=========================================================="
echo " Pipeline execution and verification completed successfully!"
echo " Evidence file written to: submission_evidence/oc-pipeline-app-logs"
echo "=========================================================="
