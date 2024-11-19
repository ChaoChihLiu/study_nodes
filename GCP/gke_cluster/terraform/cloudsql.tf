resource "google_sql_database_instance" "k8s_instance" {
  name                = "k8s-instance-${var.env}"
  database_version    = var.sql_instance_version
  region              = var.region
  deletion_protection = var.sql_deletion_protection

  settings {
    tier         = var.sql_instance_type
    disk_size    = var.sql_storage_size
    disk_type    = "PD_SSD"
    availability_type = var.sql_ha_type

    ip_configuration {
      private_network = "projects/${var.project_id}/global/networks/${google_compute_network.k8s_vpc.name}"
      ipv4_enabled    = false
    }

    backup_configuration {
      enabled            = true
      start_time         = "03:00"  # Specify the time to start the daily backup
      point_in_time_recovery_enabled = true
    }
  }

  depends_on = [google_service_networking_connection.postgresql]
}

# Create the database in the Cloud SQL instance
resource "google_sql_database" "k8sdb" {
  name     = "k8sdb"
  instance = google_sql_database_instance.k8s_instance.name
}

# SQL User for cloudsql
resource "google_sql_user" "k8s_user" {
  name     = var.sql_username
  instance = google_sql_database_instance.k8s_instance.name
  password = var.sql_password
}

# SQL User for Kong
resource "google_sql_user" "kong_user" {
  name     = var.sql_username
  instance = google_sql_database_instance.k8s_instance.name
  password = var.sql_password
}

resource "google_secret_manager_secret" "cloudsql_private_ip_secret" {
  secret_id = "cloudsql-${var.env}-private-ip"
  project  = var.project_id
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}
# Storing the private IP of the SQL instance in Secret Manager
resource "google_secret_manager_secret_version" "cloudsql_private_ip_secret_version" {
  secret = google_secret_manager_secret.cloudsql_private_ip_secret.id
  secret_data = google_sql_database_instance.k8s_instance.private_ip_address
}
