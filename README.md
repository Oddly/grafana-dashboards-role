# grafana_dashboards

Ansible role for deploying Grafana dashboards that monitor an Elastic Stack. Dashboards are read from sibling `dashboards-<service>/` repositories and pushed to the Grafana HTTP API.

## Requirements

- Grafana 10+ with API access
- Elasticsearch 8+ (for the datasource)
- Optional: `yesoreyeram-infinity-datasource` plugin for direct API panels

## Repository Layout

The role repo lives alongside per-service dashboard repos:

```
grafana-dashboards/
├── grafana-dashboards-role/   # this repo
│   ├── defaults/main.yml
│   ├── vars/dashboards.yml
│   ├── tasks/
│   ├── meta/main.yml
│   └── site.yml.example
├── dashboards-elasticsearch/
│   └── dashboards/*.json
├── dashboards-logstash/
│   └── dashboards/*.json
├── dashboards-linux/
│   └── dashboards/*.json
├── dashboards-grafana/
│   └── dashboards/*.json
├── dashboards-network/
│   └── dashboards/*.json
└── dashboards-security/
    └── dashboards/*.json
```

## Role Variables

### Connection

| Variable | Default | Description |
|---|---|---|
| `grafana_url` | `http://localhost:3000` | Grafana base URL |
| `grafana_auth` | `admin:admin` | Basic auth credentials (`user:pass`) |
| `grafana_api_key` | `""` | API key (takes precedence over basic auth) |
| `elasticsearch_url` | `https://localhost:9200` | Elasticsearch URL |
| `elasticsearch_user` | `elastic` | ES username |
| `elasticsearch_password` | `""` | ES password (**required**) |
| `elasticsearch_version` | `8.0.0` | ES version string for the datasource |
| `elasticsearch_tls_skip_verify` | `false` | Skip TLS verification |
| `elasticsearch_index_pattern` | `metrics-*,logs-*` | Index pattern for datasource |
| `grafana_dashboards_path` | `{{ playbook_dir }}/..` | Parent directory containing `dashboards-<service>/` repos |

### Service Toggles

Each service controls a group of dashboards independently. Disable any group you don't need — only enabled services have their folders created and dashboards deployed.

| Variable | Default | Dashboards |
|---|---|---|
| `grafana_dashboards_elasticsearch` | `true` | ES-00 through ES-10 (11 dashboards) |
| `grafana_dashboards_logstash` | `true` | LS-00 through LS-04, LS-09 (6 dashboards) |
| `grafana_dashboards_grafana` | `true` | GF-00 through GF-02 (3 dashboards) |
| `grafana_dashboards_linux` | `true` | LX-00 through LX-08 (9 dashboards) |
| `grafana_dashboards_network` | `true` | NT-00 through NT-04 (5 dashboards) |
| `grafana_dashboards_netflow` | `false` | NT-05 (requires separate NetFlow/IPFIX data) |
| `grafana_dashboards_security` | `true` | AU-01, JD-01 (2 dashboards) |

### Colour Palette

Set `grafana_dashboards_palette` to recolour dashboards at deploy time. The source JSON files ship with `paul-tol-bright`. Leave the variable empty (default) to deploy unchanged.

| Palette | Description |
|---|---|
| `paul-tol-bright` | Colourblind-friendly, high contrast (source default) |
| `paul-tol-vibrant` | Bolder, more saturated variant |
| `paul-tol-muted` | Softer, pastel variant |
| `okabe-ito` | Widely used colourblind-safe palette |
| `grafana-classic` | Grafana's default named-colour equivalents |

```yaml
grafana_dashboards_palette: "okabe-ito"
```

### Infinity Plugin

Set `grafana_dashboards_infinity: true` to create Infinity datasources for direct API access panels. The plugin must already be installed. Additional variables control each Infinity datasource URL — see `defaults/main.yml` and `site.yml.example` for the full list.

## Folder Structure

The role creates this folder hierarchy in Grafana (only for enabled services):

```
Linux/                → LX-00..LX-08
Network/              → NT-00..NT-05
Security/             → AU-01, JD-01
Services/
  ├── Elasticsearch/  → ES-00..ES-10
  ├── Grafana/        → GF-00..GF-02
  └── Logstash/       → LS-00..LS-09
```

Shared parent folders (like `Services/`) are only created when at least one child service is enabled.

## Usage

```yaml
# site.yml
- hosts: localhost
  connection: local
  gather_facts: false
  roles:
    - role: "{{ playbook_dir }}"
      vars:
        grafana_url: "http://grafana.example.com:3000"
        grafana_auth: "admin:changeme"
        elasticsearch_url: "https://es.example.com:9200"
        elasticsearch_user: "elastic"
        elasticsearch_password: "changeme"
        elasticsearch_tls_skip_verify: true
```

```bash
ansible-playbook site.yml
```

To deploy only a subset of dashboards, disable the services you don't need:

```yaml
grafana_dashboards_logstash: false
grafana_dashboards_grafana: false
grafana_dashboards_network: false
grafana_dashboards_security: false
```

## What It Does

1. Validates that Grafana is reachable and credentials are set
2. Creates or updates an "Elasticsearch data" datasource pointing at your ES cluster
3. Optionally creates or updates Infinity datasources for direct API access
4. Creates the Grafana folder hierarchy (only folders needed by enabled services)
5. Deploys all dashboard JSON files from enabled services
6. Reports any deployment failures at the end without aborting on individual errors

## CI

The repository includes a GitHub Actions pipeline that runs on every push and PR:

- **lint** — yamllint + ansible-lint
- **integration** — deploys all 37 dashboards to a containerised Grafana instance and verifies via API
- **selective** — deploys only elasticsearch + linux dashboards and verifies that disabled services are absent
