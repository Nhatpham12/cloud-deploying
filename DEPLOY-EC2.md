# Deploy lên AWS EC2 bằng GitHub Actions

Kiến trúc: 1 EC2 chạy Docker Compose với 4 container. Chỉ `api-gateway` mở ra ngoài (cổng 80);
3 service còn lại chỉ gọi nhau qua mạng nội bộ của Docker.

## 1. Tạo EC2
- AMI: **Amazon Linux 2023**, loại `t2.micro`/`t3.micro` (free tier).
- Key pair: tạo mới, tải file `.pem` (dùng làm secret ở bước 3).
- Security Group, inbound:
  - TCP **22** (SSH) – nguồn: Anywhere (để GitHub Actions kết nối được; hoặc giới hạn theo IP của runner nếu muốn chặt hơn).
  - TCP **80** (HTTP) – nguồn: Anywhere.

## 2. Cài Docker trên EC2 (làm 1 lần)
```
scp -i key.pem ec2-setup.sh ec2-user@<EC2_PUBLIC_IP>:~
ssh -i key.pem ec2-user@<EC2_PUBLIC_IP> "bash ec2-setup.sh"
```
Hoặc dán nội dung `ec2-setup.sh` vào mục *User data* khi tạo instance.

## 3. Tạo repo GitHub và secrets
```
cd heroku-microservices
git init && git add . && git commit -m "Microservices on EC2" && git branch -M main
git remote add origin https://github.com/<ban>/<repo>.git
git push -u origin main
```
Vào *Settings → Secrets and variables → Actions → New repository secret*:

| Secret | Giá trị |
|---|---|
| `EC2_HOST` | Public IPv4 (hoặc DNS) của EC2 |
| `EC2_USER` | `ec2-user` |
| `EC2_SSH_KEY` | Toàn bộ nội dung file `.pem` (gồm cả dòng BEGIN/END) |

## 4. Deploy
Mỗi lần `git push` lên `main`, workflow `.github/workflows/deploy-ec2.yml` sẽ:
rsync code lên EC2 → `docker compose up -d --build` → gọi `/health` để kiểm tra.
Cũng chạy tay được ở tab *Actions → Deploy to AWS EC2 → Run workflow*.

## 5. Test
```
./test-heroku.sh http://<EC2_PUBLIC_IP>
```

## Xử lý lỗi hay gặp
- `Permission denied (publickey)`: sai `EC2_SSH_KEY` hoặc `EC2_USER` (Amazon Linux là `ec2-user`, Ubuntu là `ubuntu`).
- Smoke test timeout: Security Group chưa mở cổng 80, hoặc `docker compose logs` trên EC2 để xem lỗi container.
- `docker: permission denied`: chưa đăng xuất/đăng nhập lại sau `ec2-setup.sh`.
- Public IP đổi mỗi lần stop/start instance; gắn **Elastic IP** nếu muốn cố định (nhớ cập nhật `EC2_HOST`).
