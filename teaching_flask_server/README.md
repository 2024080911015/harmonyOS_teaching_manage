# 教学过程管理系统 Flask 服务端

本项目直接适配用户提供的 SQLite 数据库，并通过 `migrate.py` 补充以下结构：

- `semester`：学期起止日期，用于将预约日期换算为教学周并检查课程占用；
- `notification.expires_at`：通知截止时间；
- `leave_request_course`：请假与受影响课程的多对多关系；
- `room_booking_log`：教室申请完整操作日志；
- 修正选课单双周冲突触发器。

## 1. 安装

```bash
python -m pip install -r requirements.txt
```

## 2. 放置数据库

将数据库文件放到：

```text
data/teaching.db
```

也可通过环境变量指定：

```powershell
$env:TEACHING_DB="D:\path\teaching.db"
```

## 3. 执行迁移

```bash
python migrate.py
```

迁移脚本可重复执行。

## 4. 创建首个管理员

```bash
python create_admin.py --account admin --password Admin123456 --name 系统管理员
```

所有其他学生、教师、教务和管理员账号均通过管理员接口预先创建，不提供公开注册接口。

## 5. 启动

```bash
python app.py
```

默认监听：

```text
http://0.0.0.0:8080
```

真机访问时应使用电脑局域网 IP，例如：

```text
http://192.168.1.100:8080
```

## 6. 请求头

登录以外的接口携带：

```http
Authorization: Bearer <token>
Content-Type: application/json
```

## 7. 统一响应

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

`code=0` 表示成功；非0表示失败。
