วัตถุประสงค์: ให้เอเจนต์สร้างโปรเจกต์ตัวอย่างที่ “deploy → ตรวจสุขภาพ → ทดสอบหลัง deploy → rollback อัตโนมัติเมื่อ fail” ครอบคลุม 2 โหมด

1. manual ด้วย `kubectl`
2. ใช้ Argo CD + Argo Rollouts

## โครงสร้างรีโปที่ต้องสร้าง

```
.
├─ app/
│  ├─ Dockerfile
│  ├─ main.py                  # HTTP server พื้นฐาน /live /ready /healthz และ /feature/new
│  ├─ requirements.txt
│  └─ README.md
├─ k8s-manifests/
│  ├─ base/
│  │  ├─ namespace.yaml
│  │  ├─ deployment.yaml       # Deployment + probes + resources
│  │  ├─ service.yaml
│  │  ├─ configmap-v1.yaml     # feature flags = off
│  │  ├─ secret-v1.yaml        # placeholder
│  │  └─ smoke-test-job.yaml   # Post-deploy smoke test
│  ├─ db/
│  │  ├─ migrator-job-up.yaml      # upgrade
│  │  ├─ migrator-job-down.yaml    # rollback เฉพาะที่ reversible
│  │  └─ pvc-or-notes.md
│  └─ rollouts/
│     ├─ rollout.yaml              # Argo Rollouts (canary steps)
│     ├─ analysis-template.yaml    # ใช้ Prometheus metric ชื่อจำลอง
│     └─ service-and-ingress.yaml
├─ argo/
│  ├─ app.yaml                 # Argo CD Application
│  ├─ hooks/
│  │  ├─ presync-backup.yaml  # ตัวอย่าง PreSync (echo/placeholder)
│  │  └─ postsync-smoke.yaml  # ใช้ smoke-test-job ผ่าน Hook
│  └─ README.md
├─ scripts/
│  ├─ build.sh
│  ├─ push.sh
│  ├─ set-image.sh            # เปลี่ยน tag ใน manifests
│  ├─ run-smoke.sh            # apply + wait job
│  ├─ gen-failure.sh          # เปิด feature ใหม่ให้ fail เพื่อทดสอบ rollback
│  └─ restore-config.sh
├─ Makefile
└─ README.md
```

## สมมติฐานสภาพแวดล้อม

* มีคลัสเตอร์ k8s พร้อม `kubectl` และสิทธิ์ namespace `test-rollback`
* ถ้าทดสอบโลคัล ให้ใช้ `kind` หรือ `k3d` ก็ได้
* มี registry สำหรับ push image เช่น `https://hub.docker.com/repositories/beamblackdragon/test-rollback`
* ถ้าใช้ Argo CD ให้ติดตั้งไว้และมี Project/Repo Allow แล้ว

---

## งานที่เอเจนต์ต้องทำ

### 1) สร้างแอปตัวอย่าง

* `app/main.py` ให้รัน HTTP บนพอร์ต 8080

  * `GET /live` ตอบ 200 ทันที
  * `GET /ready` อ่าน ENV `BOOT_DELAY` ถ้ายังไม่ครบให้ 503 เพื่อทดสอบ readiness
  * `GET /healthz` ตอบ 200 ถ้าอ่าน ENV `DB_DSN` ได้
  * `GET /feature/new` ถ้า `FEATURE_NEW=true` ให้สุ่ม error 500 บางครั้ง เพื่อจำลองบั๊กหลังปล่อยจริง
* ใส่ dependencies เบาๆ เช่น `fastapi`, `uvicorn`

### 2) สร้างคอนเทนเนอร์

* `Dockerfile` แบบ slim python
* `scripts/build.sh` สร้าง image tag ตามวันที่ เช่น `YYYYMMDD.N`
* `scripts/push.sh` push ไป registry

### 3) สร้าง manifests สำหรับ `kubectl` เพียว

* `k8s-manifests/base/deployment.yaml`

  * `image: registry.local/myapp:<TAG>`
  * `readinessProbe` `/ready`, `livenessProbe` `/live`
  * `envFrom` จาก `configmap-v1` และ `secret-v1`
  * `resources` กำหนด requests/limits
  * `lifecycle.preStop: sleep 10`
* `configmap-v1.yaml`

  * `FEATURE_NEW=false`
  * `BOOT_DELAY=5`
* `smoke-test-job.yaml`

  * ใช้ `curlimages/curl`
  * เช็ค `http://myapp.test-rollback.svc.cluster.local/healthz` 3 ครั้ง

### 4) งาน DB migration จำลอง

* `db/migrator-job-up.yaml` และ `db/migrator-job-down.yaml`

  * ใช้ image เดียวกับแอป หรือสคริปต์ python ที่พิมพ์ล็อกแทนจริง
  * ระบุ arg `upgrade 20251028` และ `downgrade 20251028` เพื่อแสดงรูปแบบ versioned
  * ติด label `job-type=migration` และตั้ง `backoffLimit: 0`
* ใส่หมายเหตุใน `pvc-or-notes.md` ว่าควร snapshot/backup ก่อนรันจริง

### 5) สร้าง Argo CD objects

* `argo/app.yaml` ชี้ path `k8s-manifests/rollouts` สำหรับโหมด Rollouts
* Hook:

  * `hooks/presync-backup.yaml` จำลอง backup ขั้นตอน PreSync (echo)
  * `hooks/postsync-smoke.yaml` เรียกใช้ `smoke-test-job.yaml` เป็น PostSync Hook พร้อม `hook-delete-policy`

### 6) Argo Rollouts

* `rollouts/rollout.yaml`

  * canary steps: 10% → analysis → 50% → analysis → 100%
  * ใช้ selector เดิมของ service
* `rollouts/analysis-template.yaml`

  * metric จำลอง `http_5xx_rate` ผ่าน Prometheus query ชื่อ placeholder
  * `successCondition: result < 0.01`
* `rollouts/service-and-ingress.yaml`

  * Service แบบ stable + canary ตามวิธีของ Rollouts
  * Ingress ตัวอย่างหรือ VirtualService ถ้าใช้ Istio (ปล่อยเป็นตัวเลือก)

### 7) สคริปต์ควบคุม

* `scripts/set-image.sh <tag>` แทนที่ tag ในไฟล์ที่เกี่ยวข้อง
* `scripts/run-smoke.sh` apply แล้ว `kubectl wait` จน job complete หรือ fail
* `scripts/gen-failure.sh`

  * แก้ ConfigMap ให้ `FEATURE_NEW=true`
  * รีสตาร์ต Deployment หรือสร้าง Rollout ใหม่
* `scripts/restore-config.sh`

  * กลับ `FEATURE_NEW=false` และ restart

### 8) Makefile targets

```makefile
REG ?= registry.local
IMG ?= $(REG)/myapp
TAG ?= $(shell date +%Y%m%d).1
NS  ?= test-rollback

.PHONY: build push set-image deploy wait smoke logs undo history clean

build:
\tbash scripts/build.sh $(IMG) $(TAG)

push:
\tbash scripts/push.sh $(IMG) $(TAG)

set-image:
\tbash scripts/set-image.sh $(TAG)

deploy:  ## kubectl mode
\tkubectl apply -n $(NS) -f k8s-manifests/base/

wait:
\tkubectl rollout status -n $(NS) deploy/myapp --timeout=5m

smoke:
\tbash scripts/run-smoke.sh $(NS)

logs:
\tkubectl logs -n $(NS) deploy/myapp --tail=200

history:
\tkubectl rollout history -n $(NS) deploy/myapp

undo:
\tkubectl rollout undo -n $(NS) deploy/myapp

fail-on:
\tbash scripts/gen-failure.sh $(NS)

fail-off:
\tbash scripts/restore-config.sh $(NS)

# Argo CD mode
argo-app:
\tkubectl apply -n argocd -f argo/app.yaml

argo-sync:
\targocd app sync myapp

argo-rollback:
\targocd app rollback myapp --to-revision 1
```

---

## ขั้นทดสอบและเกณฑ์ผ่าน

### โหมด 1: kubectl เพียว

1. `make build push set-image deploy wait`

   * เกณฑ์ผ่าน: `kubectl rollout status` เป็น `success`
2. `make smoke`

   * เกณฑ์ผ่าน: Job `Complete`
3. สร้างความล้มเหลวควบคุม

   * `make fail-on` แล้ว `make wait`
   * คาดหวัง: readiness flap หรือ error 500 ใน `/feature/new`
4. Rollback

   * `make undo` แล้ว `make wait` และ `make fail-off`
   * เกณฑ์ผ่าน: `/healthz` 200 และ `/feature/new` stable อีกครั้ง

### โหมด 2: Argo CD + Rollouts

1. สลับ path ให้ Argo CD ใช้ `k8s-manifests/rollouts`
2. `make argo-app && make argo-sync`

   * เกณฑ์ผ่าน: canary เริ่มที่ 10%
3. Analysis ทำงาน

   * เกณฑ์ผ่าน: metric ต่ำกว่ากำหนด จึงขยับเป็น 50% และ 100%
4. สร้างความล้มเหลว

   * `make fail-on` แล้ว `make argo-sync` หรือรีคอนซิล
   * เกณฑ์ผ่าน: Rollouts **abort** และ auto-rollback
5. Rollback แบบคนสั่ง

   * `make argo-rollback`
   * เกณฑ์ผ่าน: กลับ revision ก่อนหน้า

---

## สัญญาณมอนิเตอร์ที่ต้องตรวจ

* Probes: `readiness`, `liveness`, `startup`
* Metrics: error rate 5xx, p95 latency
* K8s Signals: `CrashLoopBackOff`, OOMKill, Events
* Logs: คำหลัก error ในแอป
* Ingress/Service mesh: success rate

---

## Runbook สั้น

* Fail ระหว่าง rollout:

  1. ปิด feature flag → 2) rollback config → 3) rollback image → 4) พิจารณา `down` migration เฉพาะที่ reversible → 5) restore snapshot
* DB:

  * ใช้ expand–contract
  * snapshot/backup ก่อน `up`
  * `down` เฉพาะที่ไม่ทำให้ข้อมูลสูญหาย
* หลังเหตุการณ์: แนบลิงก์สรุป metric และเหตุผลที่ abort

---

## ตัวอย่างสั้นของไฟล์หลัก

`k8s-manifests/base/deployment.yaml` ย่อ:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: test-rollback
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxSurge: 1, maxUnavailable: 1 }
  selector:
    matchLabels: { app: myapp }
  template:
    metadata:
      labels: { app: myapp }
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: app
        image: registry.local/myapp:REPLACE_TAG
        ports: [{ containerPort: 8080 }]
        envFrom:
        - configMapRef: { name: myapp-config-v1 }
        - secretRef:    { name: myapp-secret-v1 }
        readinessProbe:
          httpGet: { path: /ready, port: 8080 }
          periodSeconds: 5
          failureThreshold: 2
        livenessProbe:
          httpGet: { path: /live, port: 8080 }
          periodSeconds: 10
        resources:
          requests: { cpu: "200m", memory: "256Mi" }
          limits:   { cpu: "1",    memory: "512Mi" }
```

`k8s-manifests/rollouts/rollout.yaml` ย่อ:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
  namespace: test-rollback
spec:
  replicas: 6
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: { duration: 120 }
      - analysis: { templates: [ { templateName: error-rate-check } ] }
      - setWeight: 50
      - pause: { duration: 300 }
      - analysis: { templates: [ { templateName: error-rate-check } ] }
      - setWeight: 100
  selector: { matchLabels: { app: myapp } }
  template:
    metadata: { labels: { app: myapp } }
    spec:
      containers:
      - name: app
        image: registry.local/myapp:REPLACE_TAG
        ports: [{ containerPort: 8080 }]
        readinessProbe: { httpGet: { path: /ready, port: 8080 } }
        livenessProbe:  { httpGet: { path: /live,  port: 8080 } }
```

`k8s-manifests/rollouts/analysis-template.yaml` ย่อ:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: error-rate-check
  namespace: test-rollback
spec:
  metrics:
  - name: http-5xx-rate
    interval: 30s
    count: 6
    successCondition: result < 0.01
    provider:
      prometheus:
        address: http://prometheus.prom:9090
        query: |
          sum(rate(http_requests_total{app="myapp",status=~"5.."}[1m]))
          /
          sum(rate(http_requests_total{app="myapp"}[1m]))
```

---

## เกณฑ์ส่งมอบ

* รัน `make build push set-image deploy wait smoke` ผ่านในคลัสเตอร์ทดสอบ
* สคริปต์ `fail-on` ทำให้เกิดการ abort ใน Rollouts และ rollback อัตโนมัติ
* เอกสาร README ระบุวิธีสลับโหมด kubectl ↔ Argo CD
* ไม่มีค่า hard-code เฉพาะเครื่อง ยกเว้นค่า `registry.local` และ `test-rollback` ที่เปลี่ยนได้ผ่าน env/make vars