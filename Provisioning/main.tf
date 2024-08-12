# Copyright (c) 2018, 2022 Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl



############
# Instance
############
resource "oci_core_instance" "instance" {
  count = length(var.instances)
  // If no explicit AD number, spread instances on all ADs in round-robin. Looping to the first when last AD is reached
  availability_domain  = var.ad_number == null ? element(local.ADs, count.index) : element(local.ADs, var.ad_number - 1)
  compartment_id       = var.compartment_ocid
  display_name         = var.instances[count.index]
  extended_metadata    = var.extended_metadata
  ipxe_script          = var.ipxe_script
  preserve_boot_volume = var.preserve_boot_volume
  state                = var.instance_state
  shape                = var.shape
  shape_config {
    // If shape name contains ".Flex" and instance_flex inputs are not null, use instance_flex inputs values for shape_config block
    // Else use values from data.oci_core_shapes.current_ad for var.shape
    memory_in_gbs             = local.shape_is_flex == true && var.instance_flex_memory_in_gbs != null ? var.instance_flex_memory_in_gbs : local.shapes_config[var.shape]["memory_in_gbs"]
    ocpus                     = local.shape_is_flex == true && var.instance_flex_ocpus != null ? var.instance_flex_ocpus : local.shapes_config[var.shape]["ocpus"]
    baseline_ocpu_utilization = var.baseline_ocpu_utilization
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    # ! provider seems to have a bug with plugin_config stanzas below
    // this configuration is applied at first resource creation
    // subsequent updates are detected as changes by terraform but seems to be ignored by the provider ...
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"autonomous_linux","ENABLED")
      name          = "Oracle Autonomous Linux"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"bastion","ENABLED")
      name          = "Bastion"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"block_volume_mgmt","DISABLED")
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"custom_logs","ENABLED")
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"management","DISABLED")
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"monitoring","ENABLED")
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"osms","ENABLED")
      name          = "OS Management Service Agent"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"run_command","ENABLED")
      name          = "Compute Instance Run Command"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"vulnerability_scanning","ENABLED")
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins,"java_management_service","DISABLED")
      name = "Oracle Java Management Service"
    }
  }

  create_vnic_details {
    assign_public_ip = var.public_ip == "NONE" ? var.assign_public_ip : false
    display_name     = var.vnic_name == "" ? "" : var.instance_count != "1" ? "${var.vnic_name}_${count.index + 1}" : var.vnic_name
    hostname_label   = var.hostname_label == "" ? "" : var.instance_count != "1" ? "${var.hostname_label}-${count.index + 1}" : var.hostname_label
    private_ip = element(
      concat(var.private_ips, [""]),
      length(var.private_ips) == 0 ? 0 : count.index,
    )
    skip_source_dest_check = var.skip_source_dest_check
    // Current implementation requires providing a list of subnets when using ad-specific subnets
    subnet_id = data.oci_core_subnet.instance_subnet[count.index % length(data.oci_core_subnet.instance_subnet.*.id)].id
    nsg_ids   = var.primary_vnic_nsg_ids

    freeform_tags = local.merged_freeform_tags
    defined_tags  = var.defined_tags
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_keys != null ? file(var.ssh_public_keys) : file(var.ssh_authorized_keys)
    #user_data           = var.user_data
  }

  source_details {
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    source_id               = data.oci_core_images.main.images[0].id
    source_type             = var.source_type
  }

  freeform_tags = {"Owner"= var.compute_instance_owner}
  defined_tags  = var.defined_tags

  timeouts {
    create = var.instance_timeout
  }
  
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
}



