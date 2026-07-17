# Magento 2 — DevOps Project

Production-style deployment of Magento 2 using Docker Compose, wired up with a
full DevOps toolchain: CI/CD, Infrastructure as Code, monitoring, security, and
backups. The same stack is designed to run identically on a **local VM**
(VMware / Ubuntu) and a **cloud VM** (AWS / GCP / Azure) — a hybrid, portable
setup.

## Architecture

**Request path (runtime):**

```
Users  ->  CDN + WAF  ->  Load balancer (Nginx)  ->  Application tier
                                                       ( Varnish -> Magento: Nginx + PHP-FPM )
                                                              |
                             +--------------------------------+--------------------------------+
                             |               |                |                                |
                           Redis        Elasticsearch      RabbitMQ                          MySQL
                       (cache/session)  (catalog search)  (async queues)                (primary/replica)
```

**DevOps toolchain (around the runtime):** CI/CD pipeline, Terraform + Ansible
(IaC), Prometheus / Grafana / Loki / Alertmanager (observability), Vault / Trivy
/ UFW / Fail2ban (security), and automated backups.

## Tech stack

| Layer                    | Technology                     |
| ------------------------ | ------------------------------ |
| Web / reverse proxy      | Nginx                          |
| Application runtime      | PHP-FPM (Magento 2)            |
| Full-page cache          | Varnish                        |
| Database                 | MySQL 8                        |
| Object cache / sessions  | Redis                          |
| Catalog search           | Elasticsearch / OpenSearch     |
| Message queue            | RabbitMQ                       |
| Containers               | Docker + Docker Compose        |
| CI/CD                    | GitLab CI / GitHub Actions     |
| Infrastructure as Code   | Terraform + Ansible            |
| Monitoring               | Prometheus, Grafana, Loki, Alertmanager |
| Security                 | Vault, Trivy, UFW, Fail2ban    |

## Repository structure

```
magento-devops/
├── docker/
│   ├── nginx/          # Nginx image + site config
│   ├── php/            # PHP-FPM image (Magento)
│   ├── varnish/        # Varnish VCL
│   └── mysql/          # MySQL config
├── ci/                 # CI/CD pipeline definitions
├── infra/
│   ├── terraform/      # Cloud VM provisioning
│   └── ansible/        # Deploy to local + cloud VMs
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   ├── alertmanager/
│   └── loki/
├── backups/            # Backup + restore scripts
├── src/                # Magento application code (gitignored)
├── .env.example        # copy to .env and fill in real values
└── docker-compose.yml  # added in Phase 1
```

## Roadmap

- [x] **Phase 0** — Foundations: Docker + Compose, repo structure, git
- [ ] **Phase 1** — Core stack: Magento + Nginx + PHP-FPM + MySQL + Redis + Elasticsearch + RabbitMQ
- [ ] **Phase 2** — Edge & TLS: Varnish, HTTPS, HTTP→HTTPS redirect, security headers
- [ ] **Phase 3** — CI/CD: build, test, image push, auto-deploy
- [ ] **Phase 4** — Infrastructure as Code: Terraform + Ansible (hybrid)
- [ ] **Phase 5** — Monitoring: Prometheus, Grafana, Loki, Alertmanager, exporters
- [ ] **Phase 6** — Security: Vault, Trivy, UFW, Fail2ban, hardening
- [ ] **Phase 7** — Backup & DR: MySQL backups, media snapshots, offsite, restore drill
- [ ] **Phase 8** — Scaling & performance: node scaling, MySQL replica, load testing

## Getting started

Requirements: Ubuntu with Docker Engine + the Docker Compose plugin.

```bash
git clone git@github.com:sufyanwithcode/magento-devops.git
cd magento-devops
cp .env.example .env
# edit .env and set real passwords before bringing anything up
```

From Phase 1 onwards the full stack comes up with:

```bash
docker compose up -d
```

## Hybrid deployment

The same Compose stack runs on both a local VM and a cloud VM. Environment
differences (domain, TLS certificates, resource limits) are handled with a
per-environment `docker-compose.override.yml` file, so the base
`docker-compose.yml` never has to change.
