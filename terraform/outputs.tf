output "droplet_ip" {
  description = "IP cong khai - dan vao A record ben cPanel Zone Editor"
  value       = local.public_ip
}

output "droplet_private_ip" {
  description = "IP noi bo trong VPC"
  value       = digitalocean_droplet.app.ipv4_address_private
}

output "ssh_command" {
  description = "Lenh SSH vao VPS"
  value       = "ssh root@${local.public_ip}"
}

output "dns_records_can_tao" {
  description = "Cac ban ghi can them trong cPanel > Zone Editor"
  value = {
    "A  ${var.domain}"             = local.public_ip
    "A  grafana.${var.domain}"     = local.public_ip
    "A  jenkins.${var.domain}"     = local.public_ip
  }
}

output "buoc_tiep_theo" {
  value = <<-EOT

    1) Vao cPanel > Zone Editor, them 3 ban ghi A tro ve ${local.public_ip}
    2) Doi DNS phan giai (kiem tra: nslookup ${var.domain})
    3) Chay Ansible:  cd ../ansible && ansible-playbook -i inventory/hosts.ini playbook.yml
  EOT
}
