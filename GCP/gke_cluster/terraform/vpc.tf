resource "google_compute_network" "k8s_vpc" {
  name                    = "k8s-${var.env}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
  mtu                     = 1500
}

resource "google_compute_subnetwork" "k8s_frontend_subnet" {
  name          = "k8s-${var.env}-frontend-subnet"
  network       = google_compute_network.k8s_vpc.id
  ip_cidr_range  = var.frontend_subnet_cidr
  region         = var.region
  project        = var.project_id

  private_ip_google_access = true

  log_config {
      aggregation_interval = "INTERVAL_5_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "k8s_backend_subnet" {
  name          = "k8s-${var.env}-backend-subnet"
  network       = google_compute_network.k8s_vpc.id
  ip_cidr_range  = var.backend_subnet_cidr
  region         = var.region 
  project        = var.project_id

  private_ip_google_access = true

  log_config {
      aggregation_interval = "INTERVAL_5_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "k8s_router" {
  name    = "k8s-${var.env}-router"
  network = google_compute_network.k8s_vpc.id
  region  = var.region  
  project = var.project_id
}

resource "google_compute_router_nat" "k8s_nat" {
  name   = "k8s-${var.env}-nat"
  router = google_compute_router.k8s_router.name
  region = google_compute_router.k8s_router.region
  project = var.project_id

  nat_ip_allocate_option = "AUTO_ONLY"
  
#  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

    subnetwork {
      name = google_compute_subnetwork.k8s_frontend_subnet.name
      source_ip_ranges_to_nat = var.frontend_source_ranges_cidr
    }

    subnetwork {
      name = google_compute_subnetwork.k8s_backend_subnet.name
      source_ip_ranges_to_nat = var.backend_source_ranges_cidr
    }
}

resource "google_compute_address" "nat_ip" {
  name   = "k8s-${var.env}-nat-ip"
  region = var.region
  project = var.project_id
}

resource "google_compute_firewall" "cloudsql_allow_backend_inbound" {
  name    = "cloudsql-${var.env}-allow-backend-inbound"
  network = google_compute_network.k8s_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [google_compute_subnetwork.k8s_backend_subnet.ip_cidr_range,
                    google_compute_subnetwork.k8s_frontend_subnet.ip_cidr_range]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "gke_allow_backend_inbound" {
  name    = "gke-${var.env}-allow-backend-inbound"
  network = google_compute_network.k8s_vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = var.backend_gke_allow_inbound_ports  # Typically, GKE uses port 443 for the Kubernetes API server
  }

  source_ranges = [var.backend_subnet_cidr, var.frontend_subnet_cidr] # Replace with the CIDR range of your VM subnet
  target_tags   = ["k8s-${var.env}-cluster"]    # Replace with a tag used by your GKE nodes if applicable

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "gke_allow_frontend_inbound" {
  name    = "gke-${var.env}-allow-frontend-inbound"
  network = google_compute_network.k8s_vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = var.frontend_gke_allow_inbound_ports  # Typically, GKE uses port 443 for the Kubernetes API server
  }

  source_ranges = ["0.0.0.0/0"] # Replace with the CIDR range of your VM subnet
  target_tags   = ["frontend-${var.env}-cluster"]    # Replace with a tag used by your GKE nodes if applicable

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
