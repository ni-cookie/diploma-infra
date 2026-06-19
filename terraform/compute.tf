# 1. Получаем список доступных доменов (Availability Domains)
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# 2. АВТОПОИСК ОБРАЗА: Ищем самый свежий стандартный образ Ubuntu 22.04 для AMD
data "oci_core_images" "ubuntu_arm_image" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E3.Flex" # Фильтр, чтобы образ точно подходил под AMD
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"                # Берем самый новый
}

# 3. Создаем сервер
resource "oci_core_instance" "k3s_server" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "k3s-master-node"
  shape               = "VM.Standard.E3.Flex" # Указываем AMD архитектуру

  shape_config {
    ocpus         = 4   # Забираем максимум из Free Tier
    memory_in_gbs = 24
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.k3s_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    # Теперь мы не вписываем OCID руками, а берем ID первого найденного образа из блока data
    source_id   = data.oci_core_images.ubuntu_arm_image.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

output "public_ip" {
  value = oci_core_instance.k3s_server.public_ip
}