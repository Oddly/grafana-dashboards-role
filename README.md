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
│   └── site.yml               # example playbook
├── dashboards-elasticsearch/
│   └── dashboards/*.json
├── dashboards-logstash/
│   └── dashboards/*.json
├── dashboards-linux/
│   └── dashboards/*.json
└── ...
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
| `elasticsearch_password` | `""` | ES password |
| `elasticsearch_tls_skip_verify` | `false` | Skip TLS verification |
| `elasticsearch_index_pattern` | `metrics-*,logs-*` | Index pattern for datasource |
| `grafana_dashboards_path` | `{{ playbook_dir }}/..` | Parent directory containing `dashboards-<service>/` repos |

### Service Toggles

Each service can be enabled or disabled independently:

| Variable | Default |
|---|---|
| `grafana_dashboards_elasticsearch` | `true` |
| `grafana_dashboards_logstash` | `true` |
| `grafana_dashboards_grafana` | `true` |
| `grafana_dashboards_linux` | `true` |
| `grafana_dashboards_network` | `true` |
| `grafana_dashboards_netflow` | `false` |
| `grafana_dashboards_security` | `true` |

### Infinity Plugin

Set `grafana_dashboards_infinity: true` to create Infinity datasources for direct API access panels. The plugin must already be installed.

## Usage

```yaml
# site.yml (inside the role repo)
- hosts: localhost
  connection: local
  gather_facts: false
  roles:
    - role: "{{ playbook_dir }}"
      vars:
        grafana_url: "http://grafana.example.com:3000"
        grafana_auth: "admin:admin"
        elasticsearch_url: "https://es.example.com:9200"
        elasticsearch_user: "elastic"
        elasticsearch_password: "changeme"
        elasticsearch_tls_skip_verify: true
```

```bash
ansible-playbook site.yml
```

## What It Does

1. Creates an "Elasticsearch data" datasource pointing at your ES cluster
2. Optionally creates Infinity datasources for direct API access
3. Creates the Grafana folder hierarchy (Services/Elasticsearch, Services/Logstash, etc.)
4. Deploys all dashboard JSON files from enabled services
