# ============================================================
#  HA TANG VPS TREN DIGITALOCEAN
#  terraform init && terraform plan && terraform apply
# ============================================================

locals {
  name = var.project_name
  tags = [var.project_name, "devops-final", "terraform"]
}

# --- SSH key: day public key cua may ban len DigitalOcean ---
resource "digitalocean_ssh_key" "this" {
  name       = "${local.name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# --- Mang rieng cho droplet ---
resource "digitalocean_vpc" "this" {
  name     = "${local.name}-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# --- VPS chinh: cai san Docker qua cloud-init ---
resource "digitalocean_droplet" "app" {
  name     = "${local.name}-vps"
  image    = var.droplet_image
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.this.id
  backups  = var.enable_backups
  ipv6     = true
  tags     = local.tags

  ssh_keys  = [digitalocean_ssh_key.this.fingerprint]
  user_data = file("${path.module}/cloud-init.yaml")

  lifecycle {
    # Doi user_data khong lam huy may dang chay (Ansible se lo phan cau hinh)
    ignore_changes = [user_data]
  }
}

# --- IP tinh: doi/tao lai droplet ma khong phai sua DNS ---
resource "digitalocean_reserved_ip" "this" {
  count      = var.enable_reserved_ip ? 1 : 0
  region     = var.region
  droplet_id = digitalocean_droplet.app.id
}

# --- Tuong lua: chi mo 22 / 80 / 443 ---
resource "digitalocean_firewall" "this" {
  name        = "${local.name}-fw"
  droplet_ids = [digitalocean_droplet.app.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_cidrs
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# --- Gom tai nguyen vao 1 Project cho de nhin tren dashboard ---
resource "digitalocean_project" "this" {
  name        = local.name
  description = "Do an cuoi khoa DevOps - MERN Todo App"
  purpose     = "Web Application"
  environment = "Production"
  resources = compact([
    digitalocean_droplet.app.urn,
    var.enable_reserved_ip ? digitalocean_reserved_ip.this[0].urn : "",
  ])
}

# --- Canh bao qua email khi CPU cao (mien phi cua DigitalOcean) ---
resource "digitalocean_monitor_alert" "cpu" {
  alerts {
    email = []
  }
  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 85
  enabled     = true
  entities    = [digitalocean_droplet.app.id]
  description = "CPU droplet vuot 85% trong 5 phut"
}

# --- Tu sinh inventory cho Ansible ---
locals {
  public_ip = var.enable_reserved_ip ? digitalocean_reserved_ip.this[0].ip_address : digitalocean_droplet.app.ipv4_address
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.ini"
  file_permission = "0644"
  content         = <<-EOT
    ; File nay do Terraform tu sinh - dung sua tay
    [todo_servers]
    ${local.public_ip} ansible_user=root ansible_ssh_private_key_file=${var.ssh_private_key_path}

    [todo_servers:vars]
    ansible_python_interpreter=/usr/bin/python3
    ansible_host_key_checking=False
    app_domain=${var.domain}
  EOT
}
