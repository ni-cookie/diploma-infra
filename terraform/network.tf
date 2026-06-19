resource "oci_core_vcn" "k3s_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "k3s-network"
}

resource "oci_core_internet_gateway" "k3s_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k3s_vcn.id
  enabled        = true
}

resource "oci_core_route_table" "k3s_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k3s_vcn.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.k3s_igw.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "k3s_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k3s_vcn.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Открываем нужные порты
  dynamic "ingress_security_rules" {
    for_each = [22, 80, 443, 6443]
    content {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }
}

resource "oci_core_subnet" "k3s_subnet" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.k3s_vcn.id
  route_table_id    = oci_core_route_table.k3s_route_table.id
  security_list_ids = [oci_core_security_list.k3s_security_list.id]
}