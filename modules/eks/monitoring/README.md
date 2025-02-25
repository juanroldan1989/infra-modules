# Monitoring Module for EKS

## Overview

This module provisions `Grafana` in an Amazon EKS cluster using `Terraform`, `Terragrunt` and `Helm`.

It deploys `Grafana` with an Ingress via AWS ALB for external access and supports internal monitoring via ClusterIP.

## Components Provisioned

This module provisions the following resources to enable real-time monitoring of an EKS cluster:

### Core Infrastructure

- Kubernetes `Namespace` → Creates the monitoring namespace (if not existing).
- Helm Release `(Grafana)` → Deploys Grafana via Helm with configurable authentication.
- Kubernetes `Service` → Creates a ClusterIP service (grafana) for internal traffic.
- Kubernetes `Ingress (ALB)` → Deploys an internet-facing AWS ALB (optional) for external Grafana access.
- Kubernetes `Secret` → Stores Grafana Admin Credentials securely.

### Networking & Access

- Supports `external access` via an ALB Ingress (`Internet-facing` ALB).
- Allows `internal-only access` via ClusterIP (optional configuration).
- Automatic `AWS ALB` provisioning with required annotations.

### Customization & Scaling

- Pod Tolerations for managed node groups with taints.
- Configurable Grafana admin authentication (via Terraform variables).
- This module can be customized by modifying the `values.yaml` file or using Terraform set values to override configurations.

## Key Features of This Module

- Real-Time Monitoring with Grafana Dashboards

<img width="1201" alt="Screenshot 2025-02-21 at 20 33 29" src="https://github.com/user-attachments/assets/65d256d5-7145-4461-8b8a-15971906da15" />

- This module automatically provisions Grafana dashboards, displaying real-time metrics:

1. `CPU & Memory Usage` → Per pod, per namespace and cluster-wide.
2. `Network Traffic` → Bytes in/out per pod & total.
3. `HPA Scaling Behavior` → Tracks replica count changes over time.
4. `API Performance Monitoring` → Measures request latency & response times for sample `Greeter` Flask app.
5. `Node-Level` Monitoring → Provides cluster-wide CPU, Memory, and Disk usage insights.

<img width="1503" alt="Screenshot 2025-02-21 at 20 49 46" src="https://github.com/user-attachments/assets/50345c65-22af-4880-8c79-ad3ab9b23af5" />
<img width="1677" alt="Screenshot 2025-02-21 at 20 49 22" src="https://github.com/user-attachments/assets/c74dfc9b-0a52-4947-bacd-4ba997768e54" />

## Accessing the Grafana Dashboard

There are multiple ways to access Grafana:

### External Access via AWS ALB (Recommended)

1. Once deployed, Grafana is accessible via an ALB Ingress.

2. Find the Grafana ALB DNS Name:

```bash
kubectl get ingress grafana -n monitoring
```

3. The output should include an address similar to:

```bash
NAME      CLASS    HOSTS   ADDRESS                                           PORTS   AGE
grafana   alb      *       k8s-monitoring-1234567890.us-east-1.elb.amazonaws.com   80      5m
```

4. Open a browser and visit:

```bash
http://k8s-monitoring-1234567890.us-east-1.elb.amazonaws.com
```

If you have a custom domain, ensure your DNS is pointing to this ALB.

### Local Access via Port-Forwarding

If you don’t want to expose Grafana externally, you can port-forward to access it locally.

```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

Then open Grafana in your browser:

```bash
http://localhost:3000
```

## Retrieving the Admin Password

Grafana credentials are stored in a Kubernetes Secret.

1. Get the Admin Password:

```bash
kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
```

2. Get the Admin Username:

```bash
kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-user}" | base64 --decode
```

By default, the username is `admin`.

## Configuration steps performed by the module

- Prometheus is installed (Metrics Collection):

1. Using `kube-state-metrics`, `node-exporter` and `cadvisor`.
2. Scrapes `EKS` metrics and stores them for `Grafana`.

- `API Key` is required for automated dashboards creation:

<img width="932" alt="Screenshot 2025-02-21 at 20 34 08" src="https://github.com/user-attachments/assets/f6098052-862a-4f53-845c-941fa5bbee28" />

1. A Grafana API key is needed with admin privileges.
2. Steps to generate an API key:

- Open Grafana (`https://your-grafana-url`)
- Go to `Administration` -> `Service Accounts`
- Click on `Add Service Account`
- Set `Role` to Admin and click `Create`.
- Click on `Add service account token`.
- Click on `Generate Token` in the popup.
- Copy the `API key (token)` generated.

- When provisioning this module:
- Fill in `grafana_api_key` variable with the API Key (token)
- Fill in `grafana_url` variable with your Grafana Dashboard URL.

## Loki - Monitoring Live Logs from `Greeter` Flask App

```bash
| Tool           | Purpose                              | Data Type                                    |
|----------------|--------------------------------------|----------------------------------------------|
| **Grafana**    | Visualization & Dashboards           | Displays metrics, logs, and alerts           |
| **Prometheus** | Metrics collection & alerting        | CPU, Memory, Network, API latency            |
| **cAdvisor**   | Container resource monitoring        | Per-container CPU, Memory, Disk I/O          |
| **Loki**       | Log aggregation & querying           | Pod logs, Application logs (stdout/stderr)   |
| **Promtail**   | Log collector for Loki               | Reads logs from Kubernetes pods & nodes      |
```

### Local access via Port-Forwarding

```bash
kubectl port-forward -n monitoring svc/loki 3100:3100
```

### Why is Loki important?

- While metrics tell you **what’s wrong**, logs tell you **why it’s wrong.**
- When you load test your `Greeter` Flask app, you’ll want to see logs when response times increase.
- `Loki` integrates seamlessly with `Grafana`, allowing log-based alerts & dashboards.

### Loki is deployed as a log aggregation system

- `Promtail` collects logs from all `Kubernetes` pods.
- `Grafana` integrates with `Loki` to visualize `Greeter` Flask logs from those pods.
- A new `Flask Logs` dashboard allows live log monitoring.
- Now, in Grafana, navigate to:

```bash
Explore → Select "Loki" → Run query:

{app="greeter"}
```

- Now we're capturing real-time logs for the `Greeter` App.
