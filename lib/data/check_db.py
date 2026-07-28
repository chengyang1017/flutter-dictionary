import sqlite3
from pathlib import Path

db_path = Path(
    r"C:\Users\USER\Documents\flutter_application_1\assets\databases\vi.db"
)

connection = sqlite3.connect(db_path)
cursor = connection.cursor()

table_name = "vn_词汇_table"

columns = cursor.execute(
    f'PRAGMA table_info("{table_name}")'
).fetchall()

print("字段：")

for column in columns:
    print(
        f"{column[1]} | {column[2]}"
    )

print("\n第一条数据：")

row = cursor.execute(
    f'SELECT * FROM "{table_name}" LIMIT 1'
).fetchone()

print(row)

connection.close()