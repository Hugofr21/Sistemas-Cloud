resource "google_compute_instance" "node02" {
  name         = local.host_name
  machine_type = "e2-custom-2-4096"
  zone         = var.gce_zone

  allow_stopping_for_update = true
  can_ip_forward            = false
  deletion_protection       = false
  enable_display            = true


  tags = var.gce_tags

  labels = {
    goog-ec-src = "vm_add-tf"
  }


  boot_disk {
    auto_delete = true
    device_name = local.host_name

    initialize_params {
      image = "projects/centos-cloud/global/images/centos-stream-8-v20231115"
      size  = 40
      type  = "pd-ssd"
    }

    mode = "READ_WRITE"
  }

  network_interface {
    access_config {
      network_tier = "PREMIUM"
      /*    nat_ip       = local.ip_nat_external */
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
    email  = var.gce_service_account_email
    scopes = var.gce_service_account_scopes
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  metadata_startup_script = templatefile("${path.module}/files/install.sh", {
  SSH_PUBLIC_KEY = var.cdn_public_key })

}


# disk
resource "google_compute_disk" "adicional_disk_osd" {
  name = "diskosd"
  size = 5
  type = "pd-ssd"
}

# connect compute & disk
resource "google_compute_attached_disk" "adicional_disk_osd" {
  disk       = google_compute_disk.adicional_disk_osd.id
  instance   = google_compute_instance.node02.id
  depends_on = [google_compute_instance.node02]
}
