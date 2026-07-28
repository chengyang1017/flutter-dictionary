import json
import re
import sqlite3
from pathlib import Path
from typing import Any

import pandas as pd


BASE_DIR = Path(__file__).resolve().parent
RAW_DATA_DIR = BASE_DIR / "data" / "raw_data"
DB_DIR = BASE_DIR / "data" / "db"
JS_FILE = BASE_DIR / "static" / "js" / "lang-schemas.js"
JSON_FILE = BASE_DIR / "static" / "js" / "lang-schemas.json"

DB_DIR.mkdir(parents=True, exist_ok=True)


HEADWORD_CANDIDATES = [
    "单词",
    "词汇",
    "喃字",
    "国语字",
    "日语",
    "未完成体不定式",
    "完成体不定式",
    "不定式",
    "原形",
    "词根",
    "主格",
    "单数",
    "意思",
]

MEANING_CANDIDATES = [
    "意思",
    "中文",
    "释义",
    "解释",
    "翻译",
    "meaning",
    "meanings",
]

TYPE_CANDIDATES = [
    "词性",
    "类型",
    "type",
]


def load_schemas() -> dict[str, Any]:
    if JSON_FILE.exists():
        with JSON_FILE.open(
            "r",
            encoding="utf-8",
        ) as file:
            return json.load(file)

    if not JS_FILE.exists():
        raise FileNotFoundError(
            f"找不到 Schema：{JSON_FILE} 或 {JS_FILE}"
        )

    text = JS_FILE.read_text(
        encoding="utf-8",
    )

    text = re.sub(
        r"^const\s+LANG_SCHEMAS\s*=\s*",
        "",
        text.strip(),
        flags=re.M,
    )
    text = re.sub(r";\s*$", "", text)
    text = re.sub(r"//.*", "", text)
    text = re.sub(r"'([^']*)'", r'"\1"', text)
    text = re.sub(r",(\s*[\]}])", r"\1", text)

    schemas = json.loads(text)

    JSON_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    JSON_FILE.write_text(
        json.dumps(
            schemas,
            ensure_ascii=False,
            indent=4,
        ),
        encoding="utf-8",
    )

    print(f"✅ 已生成 JSON Schema：{JSON_FILE}")

    return schemas


def clean_value(value: Any) -> Any:
    if value is None:
        return None

    try:
        if pd.isna(value):
            return None
    except (TypeError, ValueError):
        pass

    if hasattr(value, "item"):
        try:
            value = value.item()
        except (ValueError, TypeError):
            pass

    if isinstance(value, pd.Timestamp):
        return value.isoformat()

    if isinstance(value, dict):
        return {
            str(key): clean_value(item)
            for key, item in value.items()
        }

    if isinstance(value, (list, tuple)):
        return [
            clean_value(item)
            for item in value
        ]

    if isinstance(value, str):
        text = value.strip()
        return text or None

    return value


def clean_row(
    row: pd.Series,
) -> dict[str, Any]:
    return {
        str(key): clean_value(value)
        for key, value in row.to_dict().items()
    }


def has_value(value: Any) -> bool:
    if value is None:
        return False

    if isinstance(value, str):
        return bool(value.strip())

    return True


def schema_keys(
    schema: dict[str, Any],
) -> list[str]:
    result: list[str] = []

    for key, section in schema.items():
        if not key.startswith("section"):
            continue

        if not isinstance(section, dict):
            continue

        keys = section.get("keys")

        if not isinstance(keys, list):
            continue

        for field in keys:
            field_name = str(field)

            if field_name not in result:
                result.append(field_name)

    return result


def pick_value(
    data: dict[str, Any],
    candidates: list[str],
) -> Any:
    for key in candidates:
        value = data.get(key)

        if has_value(value):
            return value

    return None


def pick_headword(
    data: dict[str, Any],
    schema: dict[str, Any],
) -> str:
    configured_key = schema.get("headwordKey")

    if isinstance(configured_key, str):
        configured_value = data.get(
            configured_key,
        )

        if has_value(configured_value):
            return str(configured_value)

    preferred = pick_value(
        data,
        HEADWORD_CANDIDATES,
    )

    if has_value(preferred):
        return str(preferred)

    for key in schema_keys(schema):
        value = data.get(key)

        if has_value(value):
            return str(value)

    return "未知"


def pick_meanings(
    data: dict[str, Any],
    schema: dict[str, Any],
) -> str:
    configured_key = schema.get("meaningsKey")

    if isinstance(configured_key, str):
        configured_value = data.get(
            configured_key,
        )

        if has_value(configured_value):
            return str(configured_value)

    value = pick_value(
        data,
        MEANING_CANDIDATES,
    )

    return (
        str(value)
        if has_value(value)
        else "未命名"
    )


def pick_type(
    data: dict[str, Any],
    schema: dict[str, Any],
    sheet_name: str,
) -> str:
    configured_key = schema.get("typeKey")

    if isinstance(configured_key, str):
        configured_value = data.get(
            configured_key,
        )

        if has_value(configured_value):
            return str(configured_value)

    value = pick_value(
        data,
        TYPE_CANDIDATES,
    )

    if has_value(value):
        return str(value)

    return sheet_name


def quote_identifier(
    identifier: str,
) -> str:
    escaped = identifier.replace('"', '""')
    return f'"{escaped}"'


def create_table(
    cursor: sqlite3.Cursor,
    table_name: str,
) -> None:
    table = quote_identifier(table_name)

    cursor.execute(
        f"DROP TABLE IF EXISTS {table}"
    )

    cursor.execute(
        f"""
        CREATE TABLE {table} (
            word TEXT PRIMARY KEY,
            meanings TEXT,
            type TEXT,
            data JSON
        )
        """
    )

    cursor.execute(
        f"""
        CREATE INDEX IF NOT EXISTS
        {quote_identifier(f"idx_{table_name}_meanings")}
        ON {table} (meanings)
        """
    )

    cursor.execute(
        f"""
        CREATE INDEX IF NOT EXISTS
        {quote_identifier(f"idx_{table_name}_type")}
        ON {table} (type)
        """
    )


def convert_language(
    lang: str,
    classes: dict[str, Any],
) -> None:
    excel_file = (
        RAW_DATA_DIR / f"{lang}_words.xlsx"
    )

    db_file = DB_DIR / f"{lang}.db"

    if not excel_file.exists():
        print(
            f"⚠️ Excel 文件缺失：{excel_file}，跳过 {lang}"
        )
        return

    print(f"\n📥 开始处理语言：{lang}")

    all_sheets = pd.read_excel(
        excel_file,
        sheet_name=None,
    )

    connection = sqlite3.connect(db_file)

    try:
        cursor = connection.cursor()
        language_total = 0

        for sheet_name, frame in all_sheets.items():
            schema = classes.get(sheet_name)

            if not isinstance(schema, dict):
                print(
                    "⚠️ 忽略没有配置 Schema 的工作表："
                    f"{sheet_name}"
                )
                continue

            table_name = (
                f"{lang}_{sheet_name}_table"
            )

            create_table(
                cursor,
                table_name,
            )

            table = quote_identifier(
                table_name,
            )

            inserted = 0

            for _, row in frame.iterrows():
                data = clean_row(row)

                if not any(
                    has_value(value)
                    for value in data.values()
                ):
                    continue

                word = pick_headword(
                    data,
                    schema,
                )

                meanings = pick_meanings(
                    data,
                    schema,
                )

                word_type = pick_type(
                    data,
                    schema,
                    sheet_name,
                )

                json_data = json.dumps(
                    data,
                    ensure_ascii=False,
                    allow_nan=False,
                )

                cursor.execute(
                    f"""
                    INSERT OR REPLACE INTO {table}
                    (word, meanings, type, data)
                    VALUES (?, ?, ?, ?)
                    """,
                    (
                        word,
                        meanings,
                        word_type,
                        json_data,
                    ),
                )

                inserted += 1

            language_total += inserted

            print(
                f"  ✅ {sheet_name}：{inserted} 条"
                f" -> {table_name}"
            )

        connection.commit()

        print(
            f"🎯 {lang} 转换完成，共 "
            f"{language_total} 条 -> {db_file}"
        )

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


def main() -> None:
    schemas = load_schemas()

    for lang, classes in schemas.items():
        if not isinstance(classes, dict):
            continue

        convert_language(
            str(lang),
            classes,
        )


if __name__ == "__main__":
    main()
