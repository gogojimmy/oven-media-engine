#!/bin/bash

# Function to check if Google Cloud SDK is installed
check_gcloud() {
    if ! command -v gcloud &> /dev/null
    then
        echo "Error: Google Cloud SDK is not installed."
        echo "Please follow these steps to install Google Cloud SDK:"
        echo "1. Visit https://cloud.google.com/sdk/docs/install"
        echo "2. Choose your operating system and download the installer"
        echo "3. Run the installer and follow the prompts"
        echo "4. After installation, run 'gcloud init' to initialize the setup"
        echo "5. Once completed, please run this script again"
        exit 1
    fi
}

# Check Google Cloud SDK
check_gcloud

# Function to check Google Cloud SDK authentication
check_gcloud_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q '@'
    then
        echo "Error: Google Cloud SDK is not logged in."
        echo "Please run 'gcloud auth login' to log in, then run this script again."
        exit 1
    fi
}

# Check Google Cloud SDK authentication
check_gcloud_auth

# Function to get available machine types from GCP
get_machine_types() {
    gcloud compute machine-types list --filter="zone:$1" --format="value(name)"
}

# Function to get available zones from GCP
get_zones() {
    gcloud compute zones list --format="value(name)"
}

# Function to get available GPU types from GCP
get_gpu_types() {
    gcloud compute accelerator-types list --filter="zone:$1" --format="value(name)"
}

echo "Welcome to the OvenMediaEngine Installation Script"

read -p "Please enter your GCP Project ID: " project_id

# Ask whether to install on an existing machine
read -p "Do you want to install on an existing machine? (y/n): " install_existing
if [[ $install_existing == "y" ]]; then
    create_new_instance="false"

    # Get all instances in the project with detailed information
    echo "Fetching available instances..."
    instances=$(gcloud compute instances list --project=$project_id --format="csv[no-heading](name,zone,machineType,status,networkInterfaces[0].accessConfigs[0].natIP,guestAccelerators[0].acceleratorType,guestAccelerators[0].acceleratorCount,disks[0].diskSizeGb)")

    # Check if there are any instances
    if [[ -z "$instances" ]]; then
        echo "Error: No instances found in the specified project."
        exit 1
    fi

    # Display instances as a numbered list with a formatted table
    echo "Available instances:"
    echo "--------------------"
    echo -e "NUM NAME ZONE MACHINE_TYPE STATUS EXTERNAL_IP GPU_TYPE GPU_COUNT DISK_SIZE"
    echo "$instances" | awk -F',' '{printf "%3d %-20s %-15s %-15s %-10s %-15s %-15s %-10s %-10s\n", NR, $1, $2, $3, $4, $5, $6, $7, $8}' | column -t
    echo "--------------------"

    # Prompt user to select an instance
    while true; do
        read -p "Please select an instance by entering its number: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$(echo "$instances" | wc -l)" ]; then
            selected_instance=$(echo "$instances" | sed -n "${selection}p")
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    # Parse selected instance details
    IFS=',' read -r instance_name zone machine_type status existing_ip gpu_type gpu_count disk_size <<< "$selected_instance"

    # Get detailed instance information
    instance_details=$(gcloud compute instances describe $instance_name --zone=$zone --project=$project_id --format="yaml(name,zone,machineType,status,networkInterfaces[0].accessConfigs[0].natIP,cpuPlatform,scheduling.onHostMaintenance,scheduling.automaticRestart,guestAccelerators,disks[0].diskSizeGb)")

    # Parse instance details
    cpu_platform=$(echo "$instance_details" | grep "cpuPlatform:" | awk '{print $2}')
    on_host_maintenance=$(echo "$instance_details" | grep "onHostMaintenance:" | awk '{print $2}')
    automatic_restart=$(echo "$instance_details" | grep "automaticRestart:" | awk '{print $2}')

    # Extract region from zone
    region=$(echo $zone | awk -F- '{print $1"-"$2}')

    # If GPU type is empty, set it to "None"
    if [[ -z "$gpu_type" ]]; then
        gpu_type="None"
        gpu_count=0
    fi

    echo "Selected instance details:"
    echo "Name: $instance_name"
    echo "Zone: $zone"
    echo "Region: $region"
    echo "Machine Type: $machine_type"
    echo "CPU Platform: $cpu_platform"
    echo "On-host Maintenance: $on_host_maintenance"
    echo "Automatic Restart: $automatic_restart"
    echo "GPU Type: $gpu_type"
    echo "GPU Count: $gpu_count"
    echo "Disk Size: $disk_size GB"
    echo "IP Address: $existing_ip"

else
    create_new_instance="true"
    
    # Get and display available regions
    echo "Available regions:"
    regions=($(gcloud compute regions list --format="value(name)"))
    select region in "${regions[@]}"; do
        if [[ -n $region ]]; then
            break
        fi
    done

    # Get and display available zones in the selected region
    echo "Available zones in $region:"
    zones=($(gcloud compute zones list --filter="region:$region" --format="value(name)"))
    select zone in "${zones[@]}"; do
        if [[ -n $zone ]]; then
            break
        fi
    done

    # Get and display available machine types
    echo "Available machine types:"
    machine_types=($(get_machine_types $zone))
    select machine_type in "${machine_types[@]}"; do
        if [[ -n $machine_type ]]; then
            break
        fi
    done

    # Get and display available GPU types
    echo "Available GPU types:"
    gpu_types=($(get_gpu_types $zone))
    select gpu_type in "${gpu_types[@]}" "None"; do
        if [[ -n $gpu_type ]]; then
            break
        fi
    done

    if [[ $gpu_type != "None" ]]; then
        read -p "Please enter the number of GPUs: " gpu_count
    else
        gpu_type=""
        gpu_count=0
    fi

    # Ask for disk size
    read -p "Please enter the boot disk size in GB (default is 10): " disk_size
    disk_size=${disk_size:-10}

    # Ask for instance name
    read -p "Please enter a name for your instance: " instance_name
fi

read -p "Please enter your SSH username: " ssh_user
read -p "Please enter the path to your SSH private key: " ssh_private_key_path
read -p "Please enter your SSH public key content: " ssh_public_key

# Generate terraform.tfvars file
cat > terraform.tfvars <<EOF
project_id = "$project_id"
region = "$region"
create_new_instance = $create_new_instance
zone = "$zone"
machine_type = "$machine_type"
gpu_type = "$gpu_type"
gpu_count = $gpu_count
existing_instance_ip = "$existing_ip"
ssh_user = "$ssh_user"
ssh_private_key_path = "$ssh_private_key_path"
ssh_public_key = "$ssh_public_key"
disk_size = $disk_size
instance_name = "$instance_name"
EOF

echo "Configuration has been saved to terraform.tfvars"

# Run Terraform
read -p "Do you want to run Terraform now? (y/n): " run_terraform
if [[ $run_terraform == "y" ]]; then
    terraform init
    terraform apply
fi