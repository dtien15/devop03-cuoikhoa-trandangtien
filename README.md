# Đồ án cuối khóa DevOps

**Trần Đăng Tiến** — Lớp DEVOP03

Ứng dụng Todo List (ReactJS + ExpressJS + MongoDB) triển khai lên VPS thật.

## Link demo

| Dịch vụ | Địa chỉ |
|---|---|
| Ứng dụng | https://todo.muatheme247.com |
| Grafana | https://grafana.muatheme247.com |
| Jenkins | https://jenkins.muatheme247.com |

VPS: DigitalOcean (Ubuntu 24.04, Singapore). Domain quản lý qua cPanel Zone Editor. HTTPS bằng Let's Encrypt.

## Các yêu cầu và vị trí file

| Yêu cầu | File |
|---|---|
| Đóng gói bằng Dockerfile | `backend/Dockerfile`, `frontend/Dockerfile` |
| docker-compose | `docker-compose.yml` (dev), `docker-compose.prod.yml` (VPS) |
| Workflow GitHub Actions | `.github/workflows/ci-cd.yml` |
| Pipeline Jenkins | `Jenkinsfile` |
| Giám sát Grafana + Prometheus | `monitoring/`, `docker-compose.monitoring.yml` |
| Terraform tạo hạ tầng VPS | `terraform/` |
| Ansible cài đặt và deploy | `ansible/` |

## Chạy thử bằng Docker

```bash
docker compose up -d --build
```

Frontend `http://localhost:3000`, backend `http://localhost:8000`.

Bật thêm giám sát:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

Grafana `http://localhost:3001` (admin/admin), Prometheus `http://localhost:9090`.

## Giám sát

- **Phần cứng VPS**: node-exporter + cAdvisor — CPU, RAM, swap, ổ đĩa, mạng, load
- **Trạng thái database**: mongodb-exporter — up/down, kết nối, opcounters, dung lượng
- 3 dashboard tự động nạp vào Grafana, 10 cảnh báo trong Alertmanager

Tài khoản Grafana trên VPS nằm trong `ansible/group_vars/vault.yml` (không commit lên GitHub).
