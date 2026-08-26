kubectl -n iris-demo get pod -l version=v1 -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.containerStatuses[*]}{.name}{" restartCount="}{.restartCount}{" lastState="}{.lastState}{"\n"}{end}{end}'
echo ""
kubectl -n iris-demo top pod 2>&1 || echo 'metrics-server not available'
echo ""
kubectl -n argocd get application istio-ingressgateway -o jsonpath='{.status.conditions}'
echo ""
kubectl -n argocd get application istio-ingressgateway -o jsonpath='{.status.sync.comparedTo}'
