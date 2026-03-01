#!/bin/bash
# SWAG Status Check

echo "=== SWAG Pod Status ==="
kubectl get pods -n heezy -l app=swag

echo -e "\n=== SWAG Service ==="
kubectl get svc -n heezy swag

echo -e "\n=== SWAG PVC ==="
kubectl get pvc -n heezy swag-config

echo -e "\n=== Recent Logs (last 20 lines) ==="
kubectl logs -n heezy -l app=swag --tail=20

echo -e "\n=== Pod Events ==="
kubectl get events -n heezy --field-selector involvedObject.name=$(kubectl get pods -n heezy -l app=swag -o jsonpath='{.items[0].metadata.name}') --sort-by='.lastTimestamp' | tail -10
