resource "google_compute_subnetwork" "bastion_subnet" {
  name          = "k8s-${var.env}-bastion-subnet"
  network       = google_compute_network.k8s_vpc.id
  ip_cidr_range  = var.bastion_subnet_cidr
  region         = var.region
  project        = var.project_id

  private_ip_google_access = true

  log_config {
      aggregation_interval = "INTERVAL_5_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "bastion_allow_access_inbound" {
  name    = "bastion-${var.env}-allow-access-inbound"
  network = google_compute_network.k8s_vpc.id
  project = var.project_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = var.bastion_allow_access_ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion-${var.env}-firewall-rule"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  priority = 1000
}

resource "google_compute_instance" "bastion_vm" {
  name         = "k8s-${var.env}-bastionvm"
  machine_type = "e2-small"
  zone         = var.bastion_vm_zone
  deletion_protection = var.bastion_deletion_protection

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-1604-xenial-v20240712"
    }
  }

  network_interface {
    network = google_compute_network.k8s_vpc.name
    subnetwork = google_compute_subnetwork.bastion_subnet.name

    access_config {
      // This creates a new ephemeral public IP for the VM
    }
  }

  metadata = {
#    ssh-keys = "your-username:ssh-rsa AAAAB3...your-ssh-key..."
    ssh-keys = var.vm_access_key
  }

  tags = ["bastion-${var.env}-firewall-rule"]

  // Allow the instance to be stopped and restarted for updates
  lifecycle {
    ignore_changes = [
      machine_type,
      min_cpu_platform,
      service_account,
      enable_display,
      shielded_instance_config,
      network_interface
    ]
    create_before_destroy = true
  }

  service_account {
    email  = google_service_account.bastion_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("./bastion_startup_script.sh")

#  shielded_instance_config {
#    secure_boot          = true
#    vtp_m_enabled        = true
#    integrity_monitoring = true
#  }
}

# Define the service account
resource "google_service_account" "bastion_service_account" {
  account_id   = "k8s-${var.env}-bastion-sa"
  display_name = "k8s-${var.env} Bastion Service Account"
  project      = var.project_id
}

resource "google_service_account_key" "bastion_key" {
  service_account_id = google_service_account.bastion_service_account.email
  key_algorithm      = "KEY_ALG_RSA_2048"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"

  // This will output the key file as a base64 encoded string
  // need to handle this output appropriately
}

resource "google_project_iam_member" "bastion_sa_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.bastion_service_account.email}"
}

resource "google_project_iam_member" "bastion_sa_gke_admin" {
  project = var.project_id
  role    = "roles/container.admin"  # GKE Admin role
  member  = "serviceAccount:${google_service_account.bastion_service_account.email}"
}

resource "google_project_iam_member" "bastion_sa_lb_admin" {
  project = var.project_id
  role    = "roles/compute.loadBalancerAdmin" 
  member  = "serviceAccount:${google_service_account.bastion_service_account.email}"
}
