// Get all the Availability Domains for the region and default backup policies
data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}

data "oci_core_volume_backup_policies" "default_backup_policies" {}

locals {
  ADs = [
    // Iterate through data.oci_identity_availability_domains.ad and create a list containing AD names
    for i in data.oci_identity_availability_domains.ad.availability_domains : i.name
  ]
  backup_policies = {
    // Iterate through data.oci_core_volume_backup_policies.default_backup_policies and create a map containing name & ocid
    // This is used to specify a backup policy id by name
    for i in data.oci_core_volume_backup_policies.default_backup_policies.volume_backup_policies : i.display_name => i.id
  }
}

data "oci_core_subnets" "subnets" {
  compartment_id = var.compartment_ocid
}

locals {
  subnet_info = { for subnet in data.oci_core_subnets.subnets.subnets : subnet.display_name => subnet.id }
}

locals {
  subnet_ocids = [ for subnet_name, subnet_id in local.subnet_info : subnet_id if subnet_name == var.subnet_name ]
}

####################
# Subnet Datasource
####################
data "oci_core_subnet" "instance_subnet" {
  count     = length(var.subnet_ocids)
  subnet_id = element(var.subnet_ocids, count.index)
}

############
# Shapes
############

// Create a data source for compute shapes.
// Filter on current AD to remove duplicates and give all the shapes supported on the AD.
// This will not check quota and limits for AD requested at resource creation
data "oci_core_shapes" "current_ad" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.ad_number == null ? element(local.ADs, 0) : element(local.ADs, var.ad_number - 1)
}

locals {
  shapes_config = {
    // prepare data with default values for flex shapes. Used to populate shape_config block with default values
    // Iterate through data.oci_core_shapes.current_ad.shapes (this exclude duplicate data in multi-ad regions) and create a map { name = { memory_in_gbs = "xx"; ocpus = "xx" } }
    for i in data.oci_core_shapes.current_ad.shapes : i.name => {
      memory_in_gbs = i.memory_in_gbs
      ocpus         = i.ocpus
    }
  }
  shape_is_flex = length(regexall("^*.Flex", var.shape)) > 0 # evaluates to boolean true when var.shape contains .Flex
}


##################################
# Image Datasource
##################################
data "oci_core_images" "main" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "7.9"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

##################################
# Instance Credentials Datasource
##################################
data "oci_core_instance_credentials" "credential" {
  count       = var.resource_platform != "linux" ? var.instance_count : 0
  instance_id = oci_core_instance.instance[count.index].id
}

####################
# Networking
####################
data "oci_core_vnic_attachments" "vnic_attachment" {
  count          = var.instance_count
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.instance[count.index].id

  depends_on = [
    oci_core_instance.instance
  ]
}

data "oci_core_private_ips" "private_ips" {
  count   = var.instance_count
  vnic_id = data.oci_core_vnic_attachments.vnic_attachment[count.index].vnic_attachments[0].vnic_id

  depends_on = [
    oci_core_instance.instance
  ]
}

