variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "create_new_instance" {
  description = "Whether to create a new instance or use an existing one"
  type        = bool
  default     = true
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
}

variable "gpu_type" {
  description = "GPU type"
  type        = string
  default     = ""
}

variable "gpu_count" {
  description = "Number of GPUs"
  type        = number
  default     = 0
}

variable "existing_instance_ip" {
  description = "IP address of the existing instance"
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "repo_url" {
  description = "Git repository URL"
  type        = string
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "instance_name" {
  description = "Name of the instance"
  type        = string
  default     = "ome-instance"
}
