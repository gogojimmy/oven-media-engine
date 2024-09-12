#!/bin/bash

# 設定日誌檔案
LOG_FILE="setup_log.txt"

# 函數：記錄訊息到日誌檔案和控制台
log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# 函數：檢查命令執行結果
check_result() {
    if [ $? -ne 0 ]; then
        log_message "錯誤：$1"
        exit 1
    else
        log_message "成功：$1"
    fi
}

# 開始安裝過程
log_message "開始 OvenMediaEngine 安裝過程"

# 1. 系統需求檢查
log_message "開始系統需求檢查"

# 檢查 Ubuntu 版本
ubuntu_version=$(lsb_release -rs)
if [ "$ubuntu_version" != "20.04" ]; then
    log_message "錯誤：Ubuntu 版本必須是 20.04，目前版本是 $ubuntu_version"
    exit 1
fi
log_message "Ubuntu 版本檢查通過：$ubuntu_version"

# 檢查 GPU
if ! lspci | grep -i nvidia > /dev/null; then
    log_message "錯誤：未檢測到 NVIDIA GPU"
    exit 1
fi
log_message "NVIDIA GPU 檢查通過"

# 檢查 CUDA 版本
cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
if [ -z "$cuda_version" ] || [ "${cuda_version%.*}" -lt 12 ]; then
    log_message "錯誤：CUDA 版本必須是 12.6 或更高，目前版本是 $cuda_version"
    exit 1
fi
log_message "CUDA 版本檢查通過：$cuda_version"

# 檢查可用記憶體
available_memory=$(free -m | awk '/^Mem:/{print $7}')
if [ "$available_memory" -lt 8192 ]; then
    log_message "錯誤：可用記憶體必須至少 8GB，目前可用 ${available_memory}MB"
    exit 1
fi
log_message "可用記憶體檢查通過：${available_memory}MB"

# 檢查可用磁碟空間
available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_space" -lt 20 ]; then
    log_message "錯誤：可用磁碟空間必須至少 20GB，目前可用 ${available_space}GB"
    exit 1
fi
log_message "可用磁碟空間檢查通過：${available_space}GB"

# 2. 安裝相依套件
log_message "開始安裝相依套件"
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y curl tar build-essential
check_result "安裝相依套件"

# 3. 安裝 NVIDIA 驅動程式和 CUDA（如果尚未安裝）
if ! command -v nvidia-smi &> /dev/null; then
    log_message "開始安裝 NVIDIA 驅動程式和 CUDA"
    sudo apt-get install -y nvidia-driver-470 nvidia-cuda-toolkit
    check_result "安裝 NVIDIA 驅動程式和 CUDA"
    log_message "請重新啟動系統以完成 NVIDIA 驅動程式和 CUDA 安裝"
    exit 0
fi

# 4. 安裝 OvenMediaEngine
log_message "開始安裝 OvenMediaEngine"
curl -LOJ https://github.com/AirenSoft/OvenMediaEngine/archive/master.tar.gz
tar xvfz OvenMediaEngine-master.tar.gz
cd OvenMediaEngine-master
./misc/prerequisites.sh --enable-nvc
cd src
make release
sudo make install
check_result "安裝 OvenMediaEngine"

# 5. 設定 OvenMediaEngine
log_message "開始設定 OvenMediaEngine"
sudo cp /opt/ovenmediaengine/bin/origin_conf/Server.xml /opt/ovenmediaengine/bin/origin_conf/Server.xml.bak
# 注意：這裡需要手動編輯 Server.xml 檔案
log_message "請手動編輯 /opt/ovenmediaengine/bin/origin_conf/Server.xml 檔案"

# 6. 啟動 OvenMediaEngine
log_message "啟動 OvenMediaEngine 服務"
sudo systemctl start ovenmediaengine
sudo systemctl enable ovenmediaengine
check_result "啟動 OvenMediaEngine 服務"

# 7. 驗證安裝
log_message "驗證 OvenMediaEngine 安裝"
if sudo systemctl is-active --quiet ovenmediaengine; then
    log_message "OvenMediaEngine 服務正在運行"
else
    log_message "錯誤：OvenMediaEngine 服務未運行"
    exit 1
fi

# 8. 設定防火牆
log_message "設定防火牆"
sudo ufw allow 1935/tcp # RTMP
sudo ufw allow 3333/tcp # WebRTC Signalling
sudo ufw allow 10000:10005/udp # WebRTC ICE
sudo ufw allow 8080/tcp # HTTP (HLS, DASH)
sudo ufw allow 8081/tcp # API
sudo ufw reload
check_result "設定防火牆"

log_message "OvenMediaEngine 安裝和設定完成"
log_message "請參考 SETUP.md 檔案以獲取更多使用說明和故障排除資訊"