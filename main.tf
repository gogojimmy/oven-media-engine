provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  create_new_instance = tobool(var.create_new_instance)
}

resource "google_compute_instance" "ome_instance" {
  count        = local.create_new_instance ? 1 : 0
  name         = "ome-instance"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # 獲取 CPU 核心數
    CPU_CORES=$(nproc)
    
    # 更新系統並安裝必要的套件
    apt-get update
    apt-get install -y docker.io docker-compose

    # 安裝 NVIDIA GPU 驅動
    apt-get install -y linux-headers-$(uname -r)
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
    wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-$distribution.pin
    mv cuda-$distribution.pin /etc/apt/preferences.d/cuda-repository-pin-600
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/7fa2af80.pub
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64 /" | tee /etc/apt/sources.list.d/cuda.list
    apt-get update
    apt-get install -y cuda-drivers

    # 安裝 NVIDIA Container Toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
    apt-get update
    apt-get install -y nvidia-docker2
    systemctl restart docker

    # 克隆專案並設置
    git clone ${var.repo_url} /app
    cd /app
    cp .env.example .env
    sed -i 's/OME_HOST=.*/OME_HOST=${self.network_interface[0].access_config[0].nat_ip}/' .env
    echo "CPU_CORES=$CPU_CORES" >> .env

    # 啟動 Docker 容器
    docker-compose up -d
  EOF

  tags = ["http-server", "https-server", "ome-server"]

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }
}

resource "google_compute_firewall" "ome_firewall" {
  name    = "ome-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "1935", "3333", "8080", "8081"]
  }

  allow {
    protocol = "udp"
    ports    = ["10000-10005"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ome-server"]
}

resource "null_resource" "deploy" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = local.create_new_instance ? google_compute_instance.ome_instance[0].network_interface[0].access_config[0].nat_ip : var.existing_instance_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io docker-compose",
      "git clone ${var.repo_url} /app",
      "cd /app",
      "cp .env.example .env",
      "sed -i 's/OME_HOST=.*/OME_HOST=${local.create_new_instance ? google_compute_instance.ome_instance[0].network_interface[0].access_config[0].nat_ip : var.existing_instance_ip}/' .env",
      "docker-compose up -d"
    ]
  }
}
