# OvenMediaEngine 與 Sinatra 管理介面安裝指南

## 前置要求

1. 安裝 Google Cloud SDK：

   - 訪問 https://cloud.google.com/sdk/docs/install
   - 選擇您的操作系統並下載安裝程序
   - 運行安裝程序並按照提示進行操作
   - 安裝完成後，運行 'gcloud init' 進行初始化設置

2. 確保您已經登錄到 Google Cloud SDK：

   - 運行 'gcloud auth login' 並按照提示進行登錄

3. 安裝 Terraform：
   - 訪問 https://www.terraform.io/downloads.html
   - 下載適合您操作系統的版本
   - 解壓並將 terraform 二進制文件添加到您的 PATH 中

## 使用互動式安裝腳本

1. 克隆專案到本地：

   ```
   git clone <your-repo-url>
   cd <your-repo-directory>
   ```

2. 運行互動式安裝腳本：

   ```
   chmod +x interactive_setup.sh
   ./interactive_setup.sh
   ```

3. 按照提示回答問題，腳本將自動生成 Terraform 配置並執行部署。

## 使用 Docker 安裝

1. 確保您的系統已安裝 Docker 和 Docker Compose。

2. 克隆專案到本地：

   ```
   git clone <your-repo-url>
   cd <your-repo-directory>
   ```

3. 複製 .env.example 到 .env 並根據需要修改設定：

   ```
   cp .env.example .env
   ```

4. 構建並啟動容器：

   ```
   docker-compose up --build
   ```

5. 訪問管理介面：
   - 本地訪問：在瀏覽器中打開 `http://localhost`
   - 外部訪問：在瀏覽器中打開 `http://<your-server-ip>`
     請確保您的防火牆允許 80 端口的入站流量。

## 使用 Terraform 部署到 GCP

1. 安裝 Terraform 和 Google Cloud SDK。

2. 設置 Google Cloud 認證：

   ```
   gcloud auth application-default login
   ```

3. 複製 .env.example 到 .env 並根據需要修改設定：

   ```
   cp .env.example .env
   ```

   特別注意以下設定：

   - TF_MACHINE_TYPE：設置為 "n1-standard-8"
   - TF_GPU_TYPE：設置為 "nvidia-tesla-t4"
   - TF_GPU_COUNT：設置為 1（或根據需求調整）

4. 初始化 Terraform：

   ```
   terraform init
   ```

5. 部署基礎設施：

   ```
   terraform apply
   ```

6. 部署完成後，您可以通過輸出的 IP 地址訪問管理介面。

   注意：系統會自動安裝 NVIDIA GPU 驅動和 NVIDIA Container Toolkit。這個過程可能需要一些時間，請耐心等待。

7. 驗證 GPU 驅動安裝：

   SSH 進入實例後，運行以下命令來驗證 GPU 驅動是否正確安裝：

   ```
   nvidia-smi
   ```

   如果看到 GPU 信息輸出，則表示驅動已成功安裝。

注意：如果要部署到現有機器，請將 TF_CREATE_NEW_INSTANCE 設為 false，並確保 TF_EXISTING_INSTANCE_IP 設置正確。

## 注意事項

- 確保您的服務器防火牆允許以下端口的入站流量：

  - 80 (HTTP - Nginx)
  - 1935 (RTMP)
  - 3333 (WebRTC Signalling)
  - 8080 (HTTP - HLS, DASH)
  - 8081 (OvenMediaEngine API)
  - 10000-10005 (WebRTC ICE)

- 如果您在雲服務提供商（AWS、GCP、Azure 等）上運行此服務，請確保在其網絡安全組或防火牆規則中開放上述端口。

- Nginx 作為反向代理服務器，提供了額外的安全性和性能優化。如果需要進一步的配置（如 SSL/TLS），請修改 nginx.conf 文件。

- 此配置使用了 NVIDIA T4 GPU，確保您的 GCP 項目有足夠的配額來創建帶 GPU 的實例。
- 使用 GPU 可能會增加成本，請注意監控您的 GCP 使用情況。
- 確保 OvenMediaEngine 的配置充分利用了 GPU 加速功能。

- GPU 驅動和 NVIDIA Container Toolkit 的安裝過程是自動的，但可能需要一些時間。如果在部署後立即無法使用 GPU，請等待幾分鐘後再試。
- 確保您的 Docker 容器配置為使用 GPU。您可能需要在 `docker-compose.yml` 文件中為 OvenMediaEngine 服務添加 GPU 相關的設置。

- Server.xml 中的 WorkerCount 設置會根據實際的 CPU 核心數自動調整。對於大多數設置，WorkerCount 被設置為 CPU 核心數的一半，而某些特定設置（如 LLHLS 和 TcpRelayWorkerCount）則使用全部核心數。
