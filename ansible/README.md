# Ansible - Tu dong cai dat va deploy

## Chuan bi (chay tren may ban hoac tren WSL/Linux)

```bash
pip install ansible
ansible-galaxy collection install -r requirements.yml
```

Tao file secret:

```bash
cp group_vars/vault.yml.example group_vars/vault.yml
ansible-vault encrypt group_vars/vault.yml
```

`group_vars/all.yml` da tro san ve repo `dtien15/devop03-cuoikhoa-trandangtien`.

## Chay lan dau (cai dat toan bo)

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --ask-vault-pass
```

File `inventory/hosts.ini` do Terraform tu sinh sau khi `terraform apply`.

## Deploy lai sau khi co image moi

```bash
ansible-playbook -i inventory/hosts.ini deploy.yml --ask-vault-pass
```

## Chay rieng tung phan bang tag

```bash
ansible-playbook playbook.yml --tags docker      # chi cai Docker
ansible-playbook playbook.yml --tags app         # chi deploy ung dung
ansible-playbook playbook.yml --tags monitoring  # chi dung Prometheus/Grafana
ansible-playbook playbook.yml --tags jenkins     # chi dung Jenkins
ansible-playbook playbook.yml --tags ssl         # chi xin chung chi HTTPS
```

## Cac role

| Role | Lam gi |
|---|---|
| `common` | Mui gio, goi he thong, swap, ufw, fail2ban, tat SSH bang mat khau |
| `docker` | Cai Docker Engine + Compose, gioi han log, dang nhap GHCR, cron don rac |
| `app` | Clone repo, sinh `.env`, pull image tu GHCR, `docker compose up -d`, cho healthcheck |
| `monitoring` | Dung Prometheus + Grafana + node/cadvisor/mongodb/blackbox exporter |
| `jenkins` | Build image Jenkins co docker CLI, chay container, in mat khau admin lan dau |
| `ssl` | Kiem tra DNS, xin chung chi Let's Encrypt cho 3 domain, reload nginx |

## Luu y

- Role `ssl` chi thanh cong khi 3 ban ghi A da tro dung ve IP VPS.
- Neu repo GitHub de **private**, sua `git_repo` thanh dang co token:
  `https://dtien15:<token>@github.com/dtien15/devop03-cuoikhoa-trandangtien.git`
