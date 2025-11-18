import bcrypt
import yaml

# 사용자 정의 (username: role)
users = {
    "admin": "admin_role",
    "logs_writer": "logs_writer_role",
    "user_tenantA": "tenantA_analyst_role",
    "user_tenantB": "tenantB_analyst_role",
    "guest": "read_only_role"
}

output = {}

for username, role in users.items():
    password = username.encode("utf-8")          # password = username
    salt = bcrypt.gensalt(rounds=12)             # bcrypt cost=12
    hashed = bcrypt.hashpw(password, salt)       # bcrypt hash 생성
    hashed_str = hashed.decode("utf-8")

    # YAML 구조 구성
    output[username] = {
        "hash": hashed_str,
        "roles": [role]
    }

# 파일 저장
with open("internal_users.yml", "w") as f:
    yaml.dump(output, f, default_flow_style=False, sort_keys=False)

print("internal_users.yml 생성 완료!")
