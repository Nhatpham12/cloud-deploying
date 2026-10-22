# Hướng dẫn deploy lên Heroku (Bước 1, 3, 5–9)

Thay `your-username` bằng tên riêng của bạn (tên app Heroku phải duy nhất toàn cầu).
Mỗi service là một git repo riêng (`git init` trong từng thư mục).

## Bước 1 – Đăng nhập
```
heroku login
```

## Bước 3 – Deploy từng service
Nhánh mặc định có thể là `master`; dùng `git branch -M main` để đồng bộ với lệnh `git push heroku main`.

### 3.1 User Service
```
cd user-service
git init
git add .
git commit -m "Initial commit - User Service"
git branch -M main
heroku create your-username-user-service
git push heroku main
heroku logs --tail
curl https://your-username-user-service.herokuapp.com/health
```

### 3.2 Product Service
```
cd ../product-service
git init && git add . && git commit -m "Initial commit - Product Service" && git branch -M main
heroku create your-username-product-service
git push heroku main
curl https://your-username-product-service.herokuapp.com/health
```

### 3.3 Order Service
```
cd ../order-service
git init && git add . && git commit -m "Initial commit - Order Service" && git branch -M main
heroku create your-username-order-service
heroku config:set USER_SERVICE_URL=https://your-username-user-service.herokuapp.com
heroku config:set PRODUCT_SERVICE_URL=https://your-username-product-service.herokuapp.com
git push heroku main
curl https://your-username-order-service.herokuapp.com/health
```

### 3.4 API Gateway
```
cd ../api-gateway
git init && git add . && git commit -m "Initial commit - API Gateway" && git branch -M main
heroku create your-username-api-gateway
heroku config:set USER_SERVICE_URL=https://your-username-user-service.herokuapp.com
heroku config:set PRODUCT_SERVICE_URL=https://your-username-product-service.herokuapp.com
heroku config:set ORDER_SERVICE_URL=https://your-username-order-service.herokuapp.com
git push heroku main
curl https://your-username-api-gateway.herokuapp.com/health
```

> Lưu ý: tên app trong `heroku create` có thể khác URL thực tế (Heroku thêm hậu tố ngẫu nhiên,
> ví dụ `your-username-user-service-1a2b3c4d5e6f.herokuapp.com`). Dùng URL do `heroku create` in ra
> khi set `*_SERVICE_URL`.

## Bước 4 – Test toàn hệ thống
```
chmod +x test-heroku.sh
./test-heroku.sh https://your-username-api-gateway.herokuapp.com
```

## Bước 5 – Logs & add-ons
```
heroku logs --tail --app your-username-user-service
heroku logs --tail --app your-username-product-service
heroku logs --tail --app your-username-order-service
heroku logs --tail --app your-username-api-gateway

heroku addons:create papertrail --app your-username-api-gateway
heroku addons:create newrelic   --app your-username-api-gateway
```
Dashboard: https://dashboard.heroku.com/apps

## Bước 6 – Config vars
```
heroku config:set NODE_ENV=production --app your-username-user-service
heroku config:set LOG_LEVEL=info      --app your-username-user-service
heroku config:set NODE_ENV=production --app your-username-api-gateway
heroku config:set RATE_LIMIT=1000     --app your-username-api-gateway
heroku config --app your-username-api-gateway
```

## Bước 7 – Custom domain & SSL
```
heroku domains:add api.yourdomain.com --app your-username-api-gateway
heroku certs:auto:enable --app your-username-api-gateway
# DNS: api.yourdomain.com  CNAME  <DNS target do heroku domains in ra>
```

## Bước 8 – CI/CD GitHub
`.github/workflows/heroku-deploy.yml` đã có sẵn (sửa tên app + email, thêm secret `HEROKU_API_KEY`).
Workflow dùng `appdir`, nên cần đặt cả 4 service trong **một** repo GitHub (git init ở thư mục gốc `heroku-microservices`).
```
heroku git:remote -a your-username-api-gateway
```

## Bước 9 – PostgreSQL cho User Service
```
heroku addons:create heroku-postgresql:essential-0 --app your-username-user-service
heroku config:get DATABASE_URL --app your-username-user-service
heroku config:set NODE_ENV=production --app your-username-user-service   # để db.js bật SSL

cd user-service
cp server.pg.js server.js        # dùng bản có PostgreSQL
git add . && git commit -m "Add PostgreSQL integration"
git push heroku main
heroku logs --tail --app your-username-user-service
```
(`heroku-postgresql:hobby-dev` trong đề đã bị Heroku ngừng; gói rẻ nhất hiện là `essential-0`, có phí. Với Postgres, `user-service` cần node >= 18 và `pg` — đã có trong package.json.)

Kiểm tra DB:
```
heroku pg:psql --app your-username-user-service
\dt
SELECT * FROM users;
SELECT COUNT(*) FROM users;     -- bảng không có cột deleted_at nên bỏ điều kiện WHERE trong đề
\q
```
Test qua gateway:
```
curl -s https://your-username-api-gateway.herokuapp.com/users | jq .
curl -s https://your-username-api-gateway.herokuapp.com/health | jq .
```
(Đề dùng `/users/health` – route này không tồn tại vì `/users/:id` bắt `health` làm id; dùng `/health` của gateway hoặc `/health` của user-service trực tiếp.)
