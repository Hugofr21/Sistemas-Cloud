
module "centosMON_MGR" {
  source = "./modules/centosMON_MGR"

  cdn_public_key  = base64encode(local_file.cdn_public_key.content)
  cdn_private_key = base64encode(local_sensitive_file.cdn_private_key.content)

  google_cloud_zone                   = local.google_cloud_settings.zone
  google_cloud_tags                   = local.google_cloud_settings.tags
  google_cloud_service_account_email  = local.google_cloud_settings.service_account.email
  google_cloud_service_account_scopes = local.google_cloud_settings.service_account.scopes

  cdn_subnetwork_id   = module.networking.cdn_subnetwork_id
  cdn_subnetwork_cidr = module.networking.cdn_subnetwork_cidr

  depends_on = [module.networking]
}


module "centosOSD" {
  source = "./modules/centosOSD"

  cdn_public_key = base64encode(local_file.cdn_public_key.content)

  gce_zone                   = local.google_cloud_settings.zone
  gce_tags                   = local.google_cloud_settings.tags
  gce_service_account_email  = local.google_cloud_settings.service_account.email
  gce_service_account_scopes = local.google_cloud_settings.service_account.scopes

  cdn_subnetwork_id   = module.networking.cdn_subnetwork_id
  cdn_subnetwork_cidr = module.networking.cdn_subnetwork_cidr

  depends_on = [module.networking]
}

module "centosOSD_2" {
  source = "./modules/centosOSD2"

  cdn_public_key = base64encode(local_file.cdn_public_key.content)

  google_cloud_zone                   = local.google_cloud_settings.zone
  google_cloud_tags                   = local.google_cloud_settings.tags
  google_cloud_service_account_email  = local.google_cloud_settings.service_account.email
  google_cloud_service_account_scopes = local.google_cloud_settings.service_account.scopes

  cdn_subnetwork_id   = module.networking.cdn_subnetwork_id
  cdn_subnetwork_cidr = module.networking.cdn_subnetwork_cidr

  depends_on = [module.networking]
}

module "centosClient" {
  source = "./modules/centosClient"

  cdn_public_key = base64encode(local_file.cdn_public_key.content)

  ssl_private_Key = base64encode(local_file.private_key_file.content)
  ssl_cert_Key = base64encode(local_file.private_key_file.content)

  google_cloud_zone                   = local.google_cloud_settings.zone
  google_cloud_tags                   = local.google_cloud_settings.tags
  google_cloud_service_account_email  = local.google_cloud_settings.service_account.email
  google_cloud_service_account_scopes = local.google_cloud_settings.service_account.scopes

  cdn_subnetwork_id   = module.networking.cdn_subnetwork_id
  cdn_subnetwork_cidr = module.networking.cdn_subnetwork_cidr

  depends_on = [module.networking]

}

module "networking" {
  source = "./networking"
}
