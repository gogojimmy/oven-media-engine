# OvenMediaEngine 與 Sinatra 管理介面安裝指南

## 使用 Docker 安裝

1. 確保您的系統已安裝 Docker 和 Docker Compose。

2. 克隆專案到本地：

   ```
   git clone <your-repo-url>
   cd <your-repo-directory>
   ```

3. 構建並啟動容器：

   ```
   docker-compose up --build
   ```

4. 訪問管理介面：
   - 本地訪問：在瀏覽器中打開 `http://localhost`
   - 外部訪問：在瀏覽器中打開 `http://<your-server-ip>`
     請確保您的防火牆允許 80 端口的入站流量。

## 手動安裝（不使用 Docker）

... (保留原有的手動安裝步驟)

## 注意事項

- 確保您的服務器防火牆允許以下端口的入站流量：

  - 80 (HTTP - Nginx)
  - 1935 (RTMP)
  - 3333 (WebRTC Signalling)
  - 8080 (HTTP - HLS, DASH)
  - 8081 (OvenMediaEngine API)
  - 10000-10005 (WebRTC ICE)

- 如果您在雲服務提供商（如 AWS、GCP、Azure 等）上運行此服務，請確保在其網絡安全組或防火牆規則中開放上述端口。

- Nginx 作為反向代理服務器，提供了額外的安全性和性能優化。如果需要進一步的配置（如 SSL/TLS），請修改 nginx.conf 文件。
