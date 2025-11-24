# Sử dụng base image Node.js chính thức (nhẹ và bảo mật)
FROM node:18-alpine

# Thiết lập thư mục làm việc trong container
WORKDIR /usr/src/app

# Sao chép file package.json và package-lock.json (nếu có)
COPY package*.json ./

# Cài đặt các dependencies
RUN npm install 

# Sao chép toàn bộ mã nguồn còn lại vào container
COPY . .

# Mở port mà ứng dụng sẽ chạy
EXPOSE 3000

# Lệnh khởi chạy ứng dụng
CMD ["node", "server.js"]

