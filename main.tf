terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.48.0"
    }
  }
}

#vars.json file
locals {
  local_data = jsondecode(file("${path.module}/var.json"))
}



provider "openstack" {
    user_name   = local.local_data.user_name
    tenant_name = local.local_data.tenant_name
    password    = local.local_data.password
    auth_url    = "http://10.150.1.251:5000"
    region      = "RegionOne"
    #domain_name = "Default"

}

resource "openstack_networking_port_v2" "port_1" {
    name = "port_1"
    admin_state_up = "true"
    network_id = "f0ad3870-01d3-41e1-b6dd-dccf6f424de4"
}



resource "openstack_compute_keypair_v2" "test-keypair" {
  name = local.local_data.key_pair
  //command = "chmod 400 '${openstack_compute_keypair_v2.test-key_pair.name}.key'"
}




resource "openstack_compute_instance_v2" "mert" {
    name            = "mert"
    image_id        = local.local_data.image_id
    flavor_id       = local.local_data.flavor_id
    key_pair        = "${openstack_compute_keypair_v2.test-keypair.name}"
    network {
      name = "Internal"
    }
}

output "fingerprint" {
    value = openstack_compute_keypair_v2.test-keypair.fingerprint
}

output "public_key" {
    value = openstack_compute_keypair_v2.test-keypair.public_key
}


output "private_key" {
    value = openstack_compute_keypair_v2.test-keypair.private_key
}


resource "openstack_networking_floatingip_v2" "admin" {
  pool = "External"
}



output "pool" {
  value       = openstack_networking_floatingip_v2.admin
}



resource "openstack_compute_floatingip_associate_v2" "admin" {
  floating_ip = "${openstack_networking_floatingip_v2.admin.address}"
  instance_id = "${openstack_compute_instance_v2.mert.id}"
}



resource "null_resource" "remote-exec" {
  provisioner "remote-exec" {
    connection {
      type ="ssh"
      agent = false
      user = "ubuntu"
      private_key = "${openstack_compute_keypair_v2.test-keypair.private_key}"
      host = "${openstack_networking_floatingip_v2.admin.address}"
    }
    inline = [
        "sudo apt update -y"
    ]
  }
}
