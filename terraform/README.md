# Terraform - Ha tang VPS tren DigitalOcean

## Chuan bi

1. Tao Personal Access Token: DigitalOcean > API > Generate New Token (quyen Read + Write)
2. Tao SSH key neu chua co:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```
3. Copy file bien:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

## Chay

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Sau khi `apply` xong:
- Terraform in ra IP cua droplet
- Tu sinh file `../ansible/inventory/hosts.ini`
- Vao cPanel > Zone Editor them 3 ban ghi A theo output `dns_records_can_tao`

## Huy ha tang

```bash
terraform destroy
```

## Tai nguyen duoc tao

| Tai nguyen | Muc dich |
|---|---|
| `digitalocean_ssh_key` | Day public key len de SSH khong can mat khau |
| `digitalocean_vpc` | Mang rieng 10.10.10.0/24 |
| `digitalocean_droplet` | VPS Ubuntu 24.04, cloud-init cai san Docker + swap + ufw |
| `digitalocean_reserved_ip` | IP tinh, doi may khong phai sua DNS |
| `digitalocean_firewall` | Chi mo 22 / 80 / 443 |
| `digitalocean_project` | Gom tai nguyen cho de quan ly |
| `digitalocean_monitor_alert` | Canh bao email khi CPU > 85% |
