# Magento 2 — 3-Tier DevOps Project

A complete, production-style Magento 2 stack running on Docker Compose, with a
full DevOps toolchain: CI/CD, Infrastructure as Code, monitoring, and backups.
The same stack runs identically on a **local VM** (VMware / Ubuntu) and a
**cloud VM** (AWS / GCP / Azure) — a hybrid, portable setup.

## The 3 tiers

```
                          ┌─────────────────────────────────────────┐
   Internet ── :80 ─────► │  TIER 1 · WEB                            │
                          │    Varnish  (full-page cache)            │
                          │       │                                  │
                          │    Nginx    (web server / reverse proxy) │
                          └───────┼──────────────────────────────────┘
                                  │ FastCGI :9000
                          ┌───────▼──────────────────────────────────┐
                          │  TIER 2 · APPLICATION                     │
                          │    PHP-FPM 8.3 + Magento 2 (Mage-OS)      │
                          └───────┼──────────────────────────────────┘
                                  │
        ┌─────────────┬───────────┼───────────────┬───────────────────┐
        ▼             ▼           ▼                ▼                   
   ┌─────────┐  ┌──────────┐ ┌──────────┐  ┌──────────────┐
   │ MySQL 8 │  │  Redis 7 │ │OpenSearch│  │  RabbitMQ    │   TIER 3 · DATA
   │   (DB)  │  │(cache +  │ │ (catalog │  │ (async       │
   │         │  │ sessions)│ │  search) │  │  message q)  │
   └─────────┘  └──────────┘ └──────────┘  └──────────────┘
```

## Prerequisites

- A host with **Docker Engine + Docker Compose plugin** (Ubuntu recommended).
- At least **6–8 GB RAM** free (OpenSearch + MySQL + PHP are memory-hungry).

## Quick start

```bash
# 1. clone
git clone https://github.com/sufyanwithcode/magento-devops.git
cd magento-devops

# 2. create your env file and set real passwords
cp .env.example .env
nano .env

# 3. build images and start the 3-tier stack
make build
make up          # or: docker compose up -d

# 4. install Magento (code + DB + Redis + OpenSearch + RabbitMQ wiring)
make install     # or: bash scripts/install-magento.sh
```

The installer uses **Mage-OS** (an open, drop-in Magento Open Source
distribution) so you do **not** need Adobe Marketplace auth keys. To use
official Magento instead, edit `scripts/install-magento.sh` and swap the
`composer create-project` line for `magento/project-community-edition`, then add
your keys when prompted.

Finally, point the domain at your machine (add to `hosts` file):

```
127.0.0.1   mysite.local
```

- Storefront: `http://mysite.local/`
- Admin: `http://mysite.local/admin`  (user `admin` / pass `Admin123!`)

## Handy commands (Makefile)

| Command          | What it does                                   |
| ---------------- | ---------------------------------------------- |
| `make build`     | Build all images                               |
| `make up`        | Start the 3-tier stack                         |
| `make down`      | Stop the stack                                 |
| `make install`   | Install Magento inside the php container       |
| `make shell`     | Bash shell in the php container                |
| `make logs`      | Tail logs from all services                    |
| `make monitoring`| Start Prometheus + Grafana + Loki              |
| `make backup`    | Dump the database + media                      |
| `make clean`     | Stop and delete volumes (**wipes data**)       |

## Repository layout

```
magento-devops/
├── docker-compose.yml               # the 3-tier stack
├── docker-compose.override.yml.example
├── Makefile
├── .env.example
├── docker/
│   ├── nginx/      Dockerfile + Magento vhost        (Tier 1)
│   ├── varnish/    Dockerfile + Magento VCL          (Tier 1)
│   ├── php/        Dockerfile + php.ini + www.conf    (Tier 2)
│   └── mysql/      my.cnf                             (Tier 3)
├── scripts/
│   └── install-magento.sh
├── ci/
│   └── gitlab-ci.yml                # GitLab CI alternative
├── .github/workflows/
│   └── ci.yml                       # GitHub Actions: validate → build → scan → deploy
├── infra/
│   ├── terraform/   main.tf, variables.tf, outputs.tf   (provision cloud VM)
│   └── ansible/     inventory.ini, playbook.yml         (deploy to local + cloud)
├── monitoring/
│   ├── docker-compose.monitoring.yml
│   ├── prometheus/  prometheus.yml
│   ├── grafana/     datasource.yml
│   ├── alertmanager/alertmanager.yml
│   └── loki/        loki-config.yml
├── backups/
│   ├── backup.sh
│   └── restore.sh
└── src/                             # Magento code lands here (gitignored)
```

## CI/CD

`.github/workflows/ci.yml` runs on every push/PR: validates the compose file,
builds the images, and runs a Trivy security scan. On `main` it can deploy to a
server over SSH — add repo secrets `DEPLOY_HOST`, `DEPLOY_USER`, and
`DEPLOY_SSH_KEY` to enable the deploy job (it is skipped if they are absent).
Prefer GitLab? Copy `ci/gitlab-ci.yml` to the repo root as `.gitlab-ci.yml`.

## Infrastructure as Code (the hybrid glue)

- **Terraform** (`infra/terraform/`) provisions a cloud VM + security group.
  ```bash
  cd infra/terraform
  terraform init
  terraform apply -var="ami_id=ami-xxxx" -var="key_name=my-key"
  ```
- **Ansible** (`infra/ansible/`) installs Docker and brings the stack up — the
  **same playbook** targets both your local VM and the cloud VM (put the cloud
  IP in `inventory.ini`).
  ```bash
  cd infra/ansible
  ansible-playbook -i inventory.ini playbook.yml
  ```

## Monitoring

```bash
make monitoring
```

- Grafana: `http://<host>:3000`  (admin / admin) — Prometheus + Loki datasources are pre-provisioned.
- Prometheus: `http://<host>:9090`
- Includes node-exporter (host metrics), cAdvisor (container metrics),
  blackbox-exporter (uptime probes), and Alertmanager.

## Backups

```bash
make backup                              # writes to backups/dumps/
bash backups/restore.sh backups/dumps/db_YYYY-MM-DD_HH-MM-SS.sql.gz
```

## Enabling Varnish full-page cache (Tier 1)

After install, wire Magento to use Varnish and purge through it:

```bash
docker compose exec php bin/magento setup:config:set --http-cache-hosts=varnish:80
docker compose exec php bin/magento config:set system/full_page_cache/caching_application 2
docker compose exec php bin/magento cache:flush
```

## Note on the DHCP / 502 problem

In VM setups, DHCP can reassign IPs on reboot and break upstream configs (the
classic Nginx 502). This project sidesteps that entirely: services talk to each
other by **container name** on a Docker network (`php`, `mysql`, `redis`,
`opensearch`), never by IP — so a reboot never breaks the upstreams.
