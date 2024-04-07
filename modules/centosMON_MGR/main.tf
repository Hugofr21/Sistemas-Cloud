resource "google_compute_instance" "node01" {
  name         = local.host_name
  machine_type = "e2-custom-2-4096"
  zone         = "europe-west1-d"

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = true

  tags = var.google_cloud_tags

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
      /*  nat_ip = local.ip_nat_external */
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
    ssh_private_key = var.cdn_private_key
    ssh_public_key  = var.cdn_public_key
    ssh_config      = filebase64("${path.module}/files/ssh_config")
    ceph_conf       = base64encode(data.template_file.ceph_conf.rendered)
    cephmon_te      = base64encode(file("${path.module}/files/cephmon.te"))
    rync_conf       = base64encode(file("${path.module}/files/rsync.conf"))
  })
}

data "template_file" "ceph_conf" {
  template = file("${path.module}/files/ceph.conf")
  vars = {
    cluster_network = var.cdn_subnetwork_cidr
    public_network  = var.cdn_subnetwork_cidr
    mon_ip          = local.ip
    cluster_uuid    = random_uuid.ceph_cluster_uuid.result
    mon_hosts       = local.host_name
  }
}

#ceph conf id cluster uuid
resource "random_uuid" "ceph_cluster_uuid" {}

# disk
resource "google_compute_disk" "adicional_disk_mon" {
  name = "diskmon"
  size = 10
  type = "pd-ssd"
  zone = "europe-west1-d"
}

# connect compute & disk
resource "google_compute_attached_disk" "compute_disk_mon" {
  disk       = google_compute_disk.adicional_disk_mon.id
  instance   = google_compute_instance.node01.id
  depends_on = [google_compute_instance.node01]
}
