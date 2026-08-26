# kiale — GitOps demo: Kubernetes + Argo CD + Istio + Prometheus + Grafana + Kiali + IA

Ambiente local, 100% automatizado, que sobe um cluster Kubernetes (kind) e usa **Argo CD**
(padrão *app of apps*) pra instalar e manter declarativamente:

- **Istio** (service mesh: base + istiod + ingress gateway)
- **kube-prometheus-stack** (Prometheus + Grafana)
- **Kiali** (visualização do mesh)
- **iris-classifier**: um serviço de IA simples (scikit-learn) com **duas versões** (v1
  `LogisticRegression` / v2 `RandomForestClassifier`) roteadas via Istio (90%/10%), pra
  demonstrar traffic-splitting/canary e aparecer bonito no grafo do Kiali.

Tudo neste repositório roda **via WSL** — é onde estão o Docker, o git e as ferramentas.

## Arquitetura

```mermaid
graph TD
    subgraph "kind cluster"
        ArgoCD[Argo CD] -->|sync| IstioBase[istio-base]
        ArgoCD -->|sync| Istiod[istiod]
        ArgoCD -->|sync| Gateway[istio-ingressgateway]
        ArgoCD -->|sync| Prom[kube-prometheus-stack]
        ArgoCD -->|sync| Kiali[kiali]
        ArgoCD -->|sync| Iris[iris-classifier v1 + v2]

        Gateway --> VS[VirtualService 90/10]
        VS --> V1[iris-classifier-v1]
        VS --> V2[iris-classifier-v2]

        Prom -. scrape /metrics .-> V1
        Prom -. scrape /metrics .-> V2
        Kiali -. lê métricas + config do mesh .-> Prom
        Kiali -. lê config .-> Istiod
    end

    Git[(repositório git)] -->|GitOps: fonte da verdade| ArgoCD
```

## Estrutura

```
cluster/              config do kind (nós do cluster local)
scripts/              automação: instalar ferramentas, subir cluster, argocd, bootstrap
gitops/argocd/        Applications do Argo CD (app-of-apps: istio, prometheus, kiali, iris)
apps/iris-classifier/ código-fonte (FastAPI + scikit-learn) + Helm chart do app
```

## Pré-requisitos

- WSL com Docker funcionando (`docker --version`)
- Nada mais — `kubectl`, `kind` e `helm` são instalados automaticamente pelos scripts

## Subir tudo

```bash
cd scripts
./up.sh
```

Isso: instala kubectl/kind/helm em `~/.local/bin`, cria o cluster kind, builda e carrega a
imagem do `iris-classifier`, instala o Argo CD e aplica o *root Application*. A partir daí o
Argo CD sincroniza sozinho: istio → prometheus/grafana → kiali → iris-classifier.

Acompanhar:
```bash
kubectl -n argocd get applications -w
```

Quando tudo estiver `Synced`/`Healthy`, abra os acessos locais:
```bash
./scripts/port-forward.sh
```

| Serviço    | URL                          | Credenciais |
|------------|-------------------------------|-------------|
| Argo CD    | https://localhost:8081         | `admin` / senha impressa por `02-install-argocd.sh` |
| Kiali      | http://localhost:20001         | anônimo (demo) |
| Grafana    | http://localhost:3000          | `admin` / `prom-operator` |
| Prometheus | http://localhost:9090          | — |
| Iris demo  | http://localhost:8080 (header `Host: iris.kiale.local`) | — |

Exemplo de chamada ao demo via Istio ingress gateway (precisa do header `Host`, já que o
Gateway/VirtualService usam um host concreto em vez de wildcard - exigência do webhook de
validação do Istio):
```bash
curl -H "Host: iris.kiale.local" http://localhost:8080/healthz
curl -H "Host: iris.kiale.local" -X POST http://localhost:8080/predict \
  -H 'Content-Type: application/json' \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
```

Parar os port-forwards: `./scripts/stop-port-forward.sh`
Derrubar tudo: `./scripts/down.sh`

## Sobre o repositório remoto

Os `Application` do Argo CD (em `gitops/argocd/`) apontam para
`https://github.com/jgpjuniorj/training.git` via HTTPS. Se o repo for privado, cadastre
credenciais no Argo CD (`kubectl -n argocd create secret ...` ou `argocd repo add`) ou torne
o repo público — sem isso o Argo CD não consegue clonar e as Applications ficam com erro de
sync.

## Sobre a demo de IA

`apps/iris-classifier` é um serviço FastAPI mínimo: treina (em build-time, dentro da imagem)
dois modelos scikit-learn no dataset clássico Iris e serve `/predict`. A mesma imagem é usada
nas duas versões — só muda a env var `MODEL_VERSION`. Isso deixa a demo simples de entender
e ainda assim funcional o bastante pra mostrar métricas reais (`/metrics`, Prometheus,
Grafana) e roteamento real de tráfego (Istio VirtualService + Kiali).

Reconstruir a imagem após alterar o código:
```bash
./scripts/build-load-image.sh
```

## Notas

- Versões de chart do Istio/kube-prometheus-stack/Kiali em `gitops/argocd/apps/*.yaml` estão
  fixadas; ajuste `targetRevision` se quiser versões mais novas.
- `iris-demo` namespace recebe o label `istio-injection: enabled` — os pods do app sobem com
  sidecar Envoy automaticamente.
