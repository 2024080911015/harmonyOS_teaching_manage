# 测试数据说明

`seed_data.py` 会生成 2000 个可登录测试账号，并为每个账号创建对应角色档案；同时覆盖院系、班级、教室、学期、课程、排课、选课、通知、请假、调课、教室预约、审批、操作日志和 Token 数据。

## 默认账号分布

| 角色 | 数量 | 账号示例 |
| --- | ---: | --- |
| 学生 | 1800 | `test_student_0001` ～ `test_student_1800` |
| 教师 | 150 | `test_teacher_001` ～ `test_teacher_150` |
| 教务 | 40 | `test_staff_001` ～ `test_staff_040` |
| 管理员 | 10 | `test_admin_01` ～ `test_admin_10` |

所有测试账号默认密码均为 `Test123456`。

## 生成命令

```powershell
python seed_data.py
```

脚本默认保护已有数据：只要数据库中已有用户就会停止。确实需要清空全部现有业务数据并重建时，必须显式执行：

```powershell
python seed_data.py --replace
```

可通过参数调整账号总数、密码和随机种子：

```powershell
python seed_data.py --users 2000 --password Test123456 --seed 20260711
```

生成后的实际逐表数量会写入 `data/test_data_summary.json`。脚本在提交事务前会自动检查 SQLite 完整性、全部外键、用户/档案数量、班级人数、课程已选人数以及密码可登录性；任何检查失败都会整体回滚。

> `--replace` 会删除数据库中的全部现有业务数据，只应在测试数据库中使用。
