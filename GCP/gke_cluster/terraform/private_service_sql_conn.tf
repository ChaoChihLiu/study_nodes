resource "google_compute_global_address" "private_service_connection" {
  name = "${var.env}-private-service-connection"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 24
  network = google_compute_network.k8s_vpc.id
}

resource "google_service_networking_connection" "postgresql" {
  network                 = google_compute_network.k8s_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_connection.name]
}

resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering              = google_service_networking_connection.postgresql.peering
  network              = google_compute_network.k8s_vpc.name
  import_custom_routes = true
  export_custom_routes = true
}
