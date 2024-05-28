resource "google_compute_instance" "cdn" {
  name         = local.host_name
  machine_type = "e2-medium"
  zone         = var.google_cloud_zone

  can_ip_forward      = true
  deletion_protection = false
  enable_display      = false

  tags = var.google_cloud_tags

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  boot_disk {
    auto_delete = true
    device_name = local.host_name

    initialize_params {
      image = "projects/centos-cloud/global/images/centos-stream-8-v20231115"
      size  = 25
      type  = "pd-ssd"
    }

    mode = "READ_WRITE"
  }

  network_interface {
    access_config {
      network_tier = "PREMIUM"
      # nat_ip       = local.ip_nat_external
    }

    subnetwork = var.cdn_subnetwork_id
    network_ip = local.ip
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  service_account {
    email  = var.google_cloud_service_account_email
    scopes = var.google_cloud_service_account_scopes
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  metadata_startup_script = templatefile("${path.module}/files/install.sh", {
    NAMED_CONF = base64encode(file("${path.module}/files/named.conf"))
    VIDEO_DB = base64encode(file("${path.module}/files/video.world.db"))
    NAMED_SYSCONFIG = base64encode(file("${path.module}/files/named"))
    INVERSA_DB = base64encode(file("${path.module}/files/10.0.16.172.db"))
  })
}


