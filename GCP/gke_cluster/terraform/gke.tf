
resource "google_container_cluster" "k8s_backend_cluster" {
  name               = "backend-${var.env}-private-cluster"
  location           = var.gke_location
  initial_node_count = 1
  remove_default_node_pool = true

  #  autopilot {
  #    enabled = true
  #  }

  network    = google_compute_network.k8s_vpc.name
  subnetwork = google_compute_subnetwork.k8s_backend_subnet.name

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = var.backend_control_panel_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "${google_compute_instance.bastion_vm.network_interface[0].network_ip}/32"  # IP ranges that need to access the Kubernetes API server
      display_name = "Authorized Network"
    }
  }

  # Add labels and metadata
  resource_labels = {
    env  = var.env
  }

  # Disable deletion protection
  deletion_protection = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_container_node_pool" "k8s_backend_node_pool" {
  name     = "backend-${var.env}-private-node-pool"
  location = google_container_cluster.k8s_backend_cluster.location
  cluster  = google_container_cluster.k8s_backend_cluster.name

#  node_locations = ["asia-southeast1-a", "asia-southeast1-c"]

  node_config {
    disk_size_gb = 30
    machine_type = var.backend_node_type
    image_type   = "UBUNTU_CONTAINERD"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    tags = ["backend-${var.env}-cluster"]

    labels = {
      env  = var.env
      team = "tc"
    }

    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "MODE_UNSPECIFIED"
    }

#    service_account = google_service_account.rte_node_service_account.email
  }

  # Optional: Configure node pool autoscaling
  autoscaling {
    min_node_count = 1
    max_node_count = var.node_max_number
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 1
  }
}

resource "google_container_cluster" "frontend_cluster" {
  name               = "frontend-${var.env}-frontend-cluster"
  location           = var.gke_location
  initial_node_count = 1
  remove_default_node_pool = true
  network    = google_compute_network.k8s_vpc.name
  subnetwork = google_compute_subnetwork.k8s_frontend_subnet.name

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = var.frontend_control_panel_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "${google_compute_instance.bastion_vm.network_interface[0].network_ip}/32"  # IP ranges that need to access the Kubernetes API server
      display_name = "Authorized Network"
    }
  }

  # Add labels and metadata
  resource_labels = {
    env  = var.env
  }

  # Disable deletion protection
  deletion_protection = false
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_project_iam_member" "portal_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.portal_node_service_account.email}"
}
resource "google_project_iam_member" "portal_repository_access" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.portal_node_service_account.email}"
}
resource "google_service_account" "portal_node_service_account" {
  account_id   = "frontend-${var.env}-frontend-node-sa"
  display_name = "frontend-${var.env}-frontend-node service account"
  project      = var.project_id
}

resource "google_project_iam_member" "rte_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.rte_node_service_account.email}"
}
resource "google_project_iam_member" "rte_repository_access" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.rte_node_service_account.email}"
}
resource "google_service_account" "rte_node_service_account" {
  account_id   = "rte-${var.env}-private-node-sa"
  display_name = "rte-${var.env}-private-node service account"
  project      = var.project_id
}

resource "google_container_node_pool" "frontend_node_pool" {
  name     = "frontend-${var.env}-frontend-node-pool"
  location = google_container_cluster.frontend_cluster.location
  cluster  = google_container_cluster.frontend_cluster.name

#  node_locations = ["asia-southeast1-a", "asia-southeast1-c"]

  node_config {
    disk_size_gb = 30
    machine_type = var.frontend_node_type
    image_type   = "UBUNTU_CONTAINERD"

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    tags = ["frontend-${var.env}-cluster", "frontend-${var.env}-instance-group"]

    labels = {
      env  = var.env
      team = "tc"
    }

    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "MODE_UNSPECIFIED"
    }
  }

  # Optional: Configure node pool autoscaling
  autoscaling {
    min_node_count = 1
    max_node_count = var.node_max_number
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 1
  }

}

resource "google_compute_disk" "shared_disk" {
  name  = "shared-disk-${var.env}"
  type  = "pd-ssd" # or "pd-standard"
  size  = 30 # Size in GB
  zone  = "asia-southeast1-a" # The zone where the disk is created
}
