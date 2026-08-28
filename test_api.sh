#!/bin/bash

echo "=== TESTE COMPLETO DO PROJETO KIALE ==="
echo ""

echo "1. Status do Cluster Kubernetes:"
kubectl get nodes
echo ""

echo "2. Aplicações do Argo CD:"
kubectl -n argocd get applications
echo ""

echo "3. Pods Rodando por Namespace:"
kubectl get pods -A --field-selector=status.phase=Running | head -20
echo ""

echo "4. Teste Argo CD (https://localhost:8081):"
curl -sk https://localhost:8081 > /dev/null && echo "✓ Argo CD: FUNCIONANDO" || echo "✗ Argo CD: FALHA"
echo ""

echo "5. Teste Kiali (http://localhost:20001):"
curl -s http://localhost:20001 > /dev/null && echo "✓ Kiali: FUNCIONANDO" || echo "✗ Kiali: FALHA"
echo ""

echo "6. Teste Grafana (http://localhost:3000):"
curl -s http://localhost:3000 > /dev/null && echo "✓ Grafana: FUNCIONANDO" || echo "✗ Grafana: FALHA"
echo ""

echo "7. Teste Prometheus (http://localhost:9090):"
curl -s http://localhost:9090 > /dev/null && echo "✓ Prometheus: FUNCIONANDO" || echo "✗ Prometheus: FALHA"
echo ""

echo "8. Teste Iris API - Health Check:"
HEALTH=$(curl -s -H "Host: iris.kiale.local" http://localhost:8080/healthz)
echo "Resposta: $HEALTH"
echo ""

echo "9. Teste Iris API - Predição:"
PREDICT=$(curl -s -H "Host: iris.kiale.local" -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}')
echo "Resposta: $PREDICT"
echo ""

echo "10. Credenciais:"
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo ""
echo ""
echo "Grafana admin password: prom-operator"
echo "Neo4j username: neo4j, password: kiale12345"
echo ""

echo "=== TUDO PRONTO! ==="
echo ""
echo "Acesse os serviços:"
echo "  Argo CD: https://localhost:8081"
echo "  Kiali: http://localhost:20001"
echo "  Grafana: http://localhost:3000"
echo "  Prometheus: http://localhost:9090"
echo "  Iris API: curl -H 'Host: iris.kiale.local' http://localhost:8080/healthz"
echo "  Neo4j: http://localhost:7474"
