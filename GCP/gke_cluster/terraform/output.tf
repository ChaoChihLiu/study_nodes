# data "google_secret_manager_secret_version" "cloudsql_private_ip_secret_version" {
#   secret  = google_secret_manager_secret.cloudsql_private_ip_secret.id
#   version = "latest"
# }


# output "cloudsql_private_ip_secret_data" {
#   value = base64decode(data.google_secret_manager_secret_version.cloudsql_private_ip_secret_version.secret_data)
#   sensitive = true  # Hides the output during terraform apply
# }

output "nat_ip_address" {
  description = "The NAT IP address allocated"
  value       = google_compute_address.nat_ip.address
}

output "cloudsql_private_ip" {
  description = "cloud sql private ip"
  value = google_sql_database_instance.k8s_instance.private_ip_address
}

output "bastion_vm_public_ip" {
  value = google_compute_instance.bastion_vm.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the test VM"
}

output "bastion_vm_private_ip" {
  value = google_compute_instance.bastion_vm.network_interface[0].network_ip
}