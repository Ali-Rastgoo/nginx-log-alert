# NGINX Log-Based Alerting System

This project implements a lightweight alerting system that monitors NGINX access logs and identifies spikes in HTTP 5xx errors. If the error rate exceeds a defined threshold for a sustained period, it automatically generates a critical report for inspection.

## Project Structure

```
.
├── Dockerfile           # Custom NGINX image with access log support
├── nginx.conf           # NGINX configuration with normal and failure routes
├── log_watcher.sh       # Bash script that performs log monitoring and alerting
├── logs/                # Host-mounted directory where NGINX writes access logs
├── alert.log            # Log file where alert messages are written (auto-generated)
├── CRITICAL-*.txt       # Critical reports created when 5xx errors persist
```

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Ali-Rastgoo/nginx-log-alert.git
cd nginx-log-alert
```

### 2. Build the Docker Image

```bash
docker build -t nginx-alert .
```

### 3. Run the NGINX Container

```bash
docker run -d   --name nginx-log   -v $(pwd)/logs:/var/log/nginx   -p 8080:80   nginx-alert
```

## NGINX Behavior

The server has two routes:

- `/` – Returns `200 OK` (normal response)
- `/fail` – Proxies to a non-existent backend, returning `502 Bad Gateway`

This setup helps simulate both successful and failing requests.

## Monitoring Script

### Start the Log Watcher

```bash
chmod +x log_watcher.sh
./log_watcher.sh
```

The script:

- Checks the last 100 access log lines every 30 seconds
- Calculates the percentage of HTTP 5xx responses
- If error rate > 10%, logs an alert to `alert.log`
- If high error rate occurs 3 times in a row:
  - Generates a `CRITICAL-<timestamp>.txt` file
  - Includes `docker ps` output and the last 20 5xx log entries

## Simulating Traffic

### Normal Request (returns 200):

```bash
curl http://localhost:8080/
```

### Failing Request (returns 502):

```bash
curl http://localhost:8080/fail
```

### Generate Load:

```bash
for i in {1..50}; do curl -s http://localhost:8080/fail > /dev/null; done
```

## Output Files

- `alert.log`: Contains all alert and monitoring logs
- `CRITICAL-<timestamp>.txt`: Includes system diagnostics on repeated failures

## Requirements

- Docker
- Bash (Linux/macOS/WSL)
- No external dependencies required

## Notes

This project is a simple and practical log-based alerting tool designed for containerized environments. It can be extended with webhooks, Slack alerts, or integrated with full-featured monitoring stacks like Prometheus.
