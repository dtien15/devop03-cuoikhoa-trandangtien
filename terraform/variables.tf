variable "do_token" {
  description = "DigitalOcean Personal Access Token (export TF_VAR_do_token=...)"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Tien to dat ten cho moi tai nguyen"
  type        = string
  default     = "mern-todo"
}

variable "region" {
  description = "Vung dat may chu. sgp1 = Singapore (gan VN nhat)"
  type        = string
  default     = "sgp1"
}

variable "droplet_size" {
  description = <<-EOT
    Cau hinh droplet.
    s-1vcpu-2gb  (~12$/thang) : chi du chay app, KHONG du cho Jenkins + monitoring
    s-2vcpu-4gb  (~24$/thang) : khuyen nghi - du cho app + Prometheus/Grafana + Jenkins
  EOT
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "droplet_image" {
  description = "Image he dieu hanh"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "ssh_public_key_path" {
  description = "Duong dan file public key se dung de SSH vao VPS"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Private key tuong ung, ghi vao inventory cua Ansible"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "allowed_ssh_cidrs" {
  description = "Dai IP duoc phep SSH. Nen thu hep lai IP nha ban: [\"1.2.3.4/32\"]"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "domain" {
  description = "Domain chinh (DNS quan ly ben cPanel Zone Editor, Terraform khong tao record)"
  type        = string
  default     = "todo.muatheme247.com"
}

variable "enable_backups" {
  description = "Bat backup tu dong cua DigitalOcean (tinh them ~20% gia droplet)"
  type        = bool
  default     = false
}

variable "enable_reserved_ip" {
  description = "Cap Reserved IP de doi droplet ma khong phai sua DNS"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = <<-EOT
    Email nhan canh bao CPU tu DigitalOcean.
    De trong ("") thi khong tao alert - he thong da co 10 canh bao trong
    Prometheus/Alertmanager roi nen khong bat buoc.
  EOT
  type        = string
  default     = ""
}

variable "grafana_domain" {
  description = "Domain cho Grafana (phai khop ansible/group_vars/all.yml)"
  type        = string
  default     = "grafana.muatheme247.com"
}

variable "jenkins_domain" {
  description = "Domain cho Jenkins (phai khop ansible/group_vars/all.yml)"
  type        = string
  default     = "jenkins.muatheme247.com"
}
