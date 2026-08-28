from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import sqlite3
import subprocess
import sys
from pathlib import Path


REQUIRED_TABLES = {
    "lexemes",
    "senses",
    "glosses",
    "noun_forms",
    "verb_forms",
}

REQUIRED_COLUMNS = {
    "lexemes": {
        "id",
        "language_code",
        "part_of_speech",
        "lemma",
    },
    "senses": {
        "id",
        "lexeme_id",
        "sense_no",
    },
    "glosses": {
        "id",
        "sense_id",
        "language_code",
        "text",
    },
    "noun_forms": {
        "id",
        "lexeme_id",
        "form",
        "canonical_key",
        "number",
        "possessive",
        "case_name",
        "interrogative",
        "special",
    },
    "verb_forms": {
        "id",
        "lexeme_id",
        "form",
        "canonical_key",
        "form_type",
        "tense",
        "person",
        "negative",
    },
}


def fail(message: str) -> "NoReturn":
    print(f"\nERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def run(
    command: list[str],
    *,
    cwd: Path,
    label: str,
) -> None:
    print(f"\n== {label} ==")
    print(" ".join(command))

    executable = shutil.which(command[0])

    if executable is None:
        fail(
            f"Cannot find executable: {command[0]}"
        )

    resolved_command = [
        executable,
        *command[1:],
    ]

    if (
        os.name == "nt"
        and Path(executable).suffix.lower()
        in {".bat", ".cmd"}
    ):
        resolved_command = [
            "cmd.exe",
            "/d",
            "/c",
            executable,
            *command[1:],
        ]

    result = subprocess.run(
        resolved_command,
        cwd=cwd,
    )

    if result.returncode != 0:
        fail(
            f"{label} failed with exit code "
            f"{result.returncode}."
        )


def resolve_generator_root(
    flutter_root: Path,
    explicit: str | None,
) -> Path:
    candidates: list[Path] = []

    if explicit:
        candidates.append(
            Path(explicit).expanduser(),
        )

    env_value = os.environ.get(
        "KYRGYZ_GENERATOR_ROOT",
    )

    if env_value:
        candidates.append(
            Path(env_value).expanduser(),
        )

    candidates.extend(
        [
            flutter_root.parent
            / "Python"
            / "kyrgyz-inflection-generator",
            flutter_root.parent
            / "kyrgyz-inflection-generator",
        ]
    )

    for candidate in candidates:
        candidate = candidate.resolve()

        if (
            (candidate / "src" / "main.py").is_file()
            and (
                candidate
                / "src"
                / "canonical.py"
            ).is_file()
        ):
            return candidate

    checked = "\n".join(
        f"  - {candidate.resolve()}"
        for candidate in candidates
    )

    fail(
        "Cannot find kyrgyz-inflection-generator.\n"
        "Checked:\n"
        f"{checked}\n"
        "Use --generator-root PATH or set "
        "KYRGYZ_GENERATOR_ROOT."
    )


def resolve_generator_python(
    generator_root: Path,
    explicit: str | None,
) -> str:
    if explicit:
        return explicit

    candidates = [
        generator_root
        / ".venv"
        / "Scripts"
        / "python.exe",
        generator_root
        / "venv"
        / "Scripts"
        / "python.exe",
    ]

    for candidate in candidates:
        if candidate.is_file():
            return str(candidate)

    return sys.executable


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()

    with path.open("rb") as handle:
        for chunk in iter(
            lambda: handle.read(1024 * 1024),
            b"",
        ):
            digest.update(chunk)

    return digest.hexdigest()


def table_columns(
    connection: sqlite3.Connection,
    table: str,
) -> set[str]:
    rows = connection.execute(
        f'PRAGMA table_info("{table}")'
    ).fetchall()

    return {
        str(row[1])
        for row in rows
    }


def validate_database(path: Path) -> None:
    print(f"\n== Validate SQLite: {path} ==")

    if not path.is_file():
        fail(f"Database does not exist: {path}")

    try:
        connection = sqlite3.connect(
            f"file:{path.as_posix()}?mode=ro",
            uri=True,
        )
    except sqlite3.Error as error:
        fail(f"Cannot open SQLite database: {error}")

    try:
        quick_check = connection.execute(
            "PRAGMA quick_check"
        ).fetchone()

        if (
            quick_check is None
            or quick_check[0] != "ok"
        ):
            fail(
                "PRAGMA quick_check failed: "
                f"{quick_check}"
            )

        foreign_key_errors = (
            connection.execute(
                "PRAGMA foreign_key_check"
            ).fetchall()
        )

        if foreign_key_errors:
            fail(
                "PRAGMA foreign_key_check "
                f"returned {foreign_key_errors}"
            )

        tables = {
            row[0]
            for row in connection.execute(
                """
                SELECT name
                FROM sqlite_master
                WHERE type = 'table'
                """
            )
        }

        missing_tables = (
            REQUIRED_TABLES - tables
        )

        if missing_tables:
            fail(
                "Missing canonical tables: "
                f"{sorted(missing_tables)}"
            )

        for table, required in (
            REQUIRED_COLUMNS.items()
        ):
            missing_columns = (
                required
                - table_columns(
                    connection,
                    table,
                )
            )

            if missing_columns:
                fail(
                    f"{table} missing columns: "
                    f"{sorted(missing_columns)}"
                )

        validate_verb_form_count(
            connection,
            lemma="айтуу",
            expected=46,
        )

        validate_verb_form_count(
            connection,
            lemma="алуу",
            expected=46,
        )

        validate_noun_form_count(
            connection,
            lemma="мугалим",
            expected=414,
        )

        validate_aldym_reverse_lookup(
            connection,
        )

        for language_code, gloss in [
            ("en", "buy"),
            ("zh", "买"),
            ("ru", "покупать"),
        ]:
            validate_gloss_lookup(
                connection,
                language_code=language_code,
                gloss=gloss,
                lemma="алуу",
            )

        sense_count = connection.execute(
            """
            SELECT COUNT(*)
            FROM senses
            JOIN lexemes
              ON lexemes.id = senses.lexeme_id
            WHERE lexemes.language_code = 'ky'
              AND lexemes.part_of_speech = 'verb'
              AND lexemes.lemma = 'алуу'
            """
        ).fetchone()[0]

        if sense_count < 3:
            fail(
                "Expected at least 3 senses for "
                f"алуу, got {sense_count}."
            )

        print("SQLite validation passed.")
    finally:
        connection.close()


def validate_verb_form_count(
    connection: sqlite3.Connection,
    *,
    lemma: str,
    expected: int,
) -> None:
    row = connection.execute(
        """
        SELECT COUNT(*)
        FROM verb_forms
        JOIN lexemes
          ON lexemes.id = verb_forms.lexeme_id
        WHERE lexemes.language_code = 'ky'
          AND lexemes.part_of_speech = 'verb'
          AND lexemes.lemma = ?
        """,
        (lemma,),
    ).fetchone()

    actual = int(row[0])

    if actual != expected:
        fail(
            f"Expected {lemma} to have "
            f"{expected} verb forms, got {actual}."
        )

    print(
        f"OK verb {lemma}: {actual} forms"
    )


def validate_noun_form_count(
    connection: sqlite3.Connection,
    *,
    lemma: str,
    expected: int,
) -> None:
    row = connection.execute(
        """
        SELECT COUNT(*)
        FROM noun_forms
        JOIN lexemes
          ON lexemes.id = noun_forms.lexeme_id
        WHERE lexemes.language_code = 'ky'
          AND lexemes.part_of_speech = 'noun'
          AND lexemes.lemma = ?
        """,
        (lemma,),
    ).fetchone()

    actual = int(row[0])

    if actual != expected:
        fail(
            f"Expected {lemma} to have "
            f"{expected} noun forms, got {actual}."
        )

    print(
        f"OK noun {lemma}: {actual} forms"
    )


def validate_aldym_reverse_lookup(
    connection: sqlite3.Connection,
) -> None:
    rows = connection.execute(
        """
        SELECT
          lexemes.lemma,
          verb_forms.tense,
          verb_forms.person,
          verb_forms.negative
        FROM verb_forms
        JOIN lexemes
          ON lexemes.id = verb_forms.lexeme_id
        WHERE lexemes.language_code = 'ky'
          AND verb_forms.form = 'алдым'
        """
    ).fetchall()

    matching = [
        row
        for row in rows
        if row[0] == "алуу"
        and row[1] == "past"
        and row[2] == "1sg"
        and int(row[3]) == 0
    ]

    if not matching:
        fail(
            "Expected алдым -> алуу with "
            "past / 1sg / affirmative."
        )

    print(
        "OK reverse form: "
        "алдым -> алуу (past, 1sg)"
    )


def validate_gloss_lookup(
    connection: sqlite3.Connection,
    *,
    language_code: str,
    gloss: str,
    lemma: str,
) -> None:
    rows = connection.execute(
        """
        SELECT DISTINCT lexemes.lemma
        FROM glosses
        JOIN senses
          ON senses.id = glosses.sense_id
        JOIN lexemes
          ON lexemes.id = senses.lexeme_id
        WHERE lexemes.language_code = 'ky'
          AND glosses.language_code = ?
          AND glosses.text = ?
        """,
        (
            language_code,
            gloss,
        ),
    ).fetchall()

    lemmas = {
        row[0]
        for row in rows
    }

    if lemma not in lemmas:
        fail(
            f"Expected gloss {gloss!r} "
            f"({language_code}) -> {lemma}."
        )

    print(
        f"OK gloss {language_code}: "
        f"{gloss} -> {lemma}"
    )


def atomic_copy(
    source: Path,
    destination: Path,
) -> None:
    destination.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    temporary = destination.with_name(
        destination.name + ".tmp"
    )

    if temporary.exists():
        temporary.unlink()

    try:
        shutil.copy2(
            source,
            temporary,
        )
        os.replace(
            temporary,
            destination,
        )
    finally:
        if temporary.exists():
            temporary.unlink()


def generator_revision(
    generator_root: Path,
) -> tuple[str, str]:
    try:
        branch = subprocess.check_output(
            [
                "git",
                "-C",
                str(generator_root),
                "branch",
                "--show-current",
            ],
            text=True,
        ).strip()

        head = subprocess.check_output(
            [
                "git",
                "-C",
                str(generator_root),
                "rev-parse",
                "--short",
                "HEAD",
            ],
            text=True,
        ).strip()

        return branch, head
    except (
        subprocess.CalledProcessError,
        FileNotFoundError,
    ):
        return "unknown", "unknown"


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Generate, validate, and import "
            "the canonical Kyrgyz SQLite DB "
            "into flutter-dictionary."
        )
    )

    parser.add_argument(
        "--generator-root",
        help=(
            "Path to kyrgyz-inflection-generator. "
            "Defaults to KYRGYZ_GENERATOR_ROOT, "
            "then ../Python/kyrgyz-inflection-generator."
        ),
    )

    parser.add_argument(
        "--generator-python",
        help=(
            "Python interpreter used by the "
            "generator. Defaults to its .venv "
            "or the current Python."
        ),
    )

    parser.add_argument(
        "--skip-flutter-test",
        action="store_true",
        help=(
            "Skip the real ky.db Flutter "
            "asset smoke test."
        ),
    )

    args = parser.parse_args()

    flutter_root = (
        Path(__file__).resolve().parents[1]
    )

    generator_root = resolve_generator_root(
        flutter_root,
        args.generator_root,
    )

    generator_python = (
        resolve_generator_python(
            generator_root,
            args.generator_python,
        )
    )

    generated_db = (
        generator_root
        / "output"
        / "canonical"
        / "kyrgyz.db"
    )

    destination_db = (
        flutter_root
        / "assets"
        / "databases"
        / "ky.db"
    )

    branch, head = generator_revision(
        generator_root,
    )

    print(
        "Generator: "
        f"{generator_root}"
    )
    print(
        "Generator revision: "
        f"{branch} @ {head}"
    )
    print(
        "Generator Python: "
        f"{generator_python}"
    )

    if generated_db.exists():
        generated_db.unlink()

    run(
        [
            generator_python,
            "src/main.py",
            "--locale",
            "en",
        ],
        cwd=generator_root,
        label="Generate canonical Kyrgyz data",
    )

    validate_database(
        generated_db,
    )

    source_hash = sha256_file(
        generated_db,
    )

    print(
        "\nGenerated DB:"
        f"\n  path: {generated_db}"
        f"\n  size: {generated_db.stat().st_size} bytes"
        f"\n  sha256: {source_hash}"
    )

    atomic_copy(
        generated_db,
        destination_db,
    )

    destination_hash = sha256_file(
        destination_db,
    )

    if destination_hash != source_hash:
        fail(
            "Copied asset SHA-256 does not "
            "match generated database."
        )

    validate_database(
        destination_db,
    )

    print(
        "\nFlutter asset updated:"
        f"\n  path: {destination_db}"
        f"\n  size: {destination_db.stat().st_size} bytes"
        f"\n  sha256: {destination_hash}"
    )

    if not args.skip_flutter_test:
        run(
            [
                "flutter",
                "test",
                "test/kyrgyz_asset_database_test.dart",
            ],
            cwd=flutter_root,
            label="Flutter real ky.db asset smoke test",
        )

    print(
        "\nSUCCESS: Kyrgyz dictionary "
        "generation/import pipeline passed."
    )


if __name__ == "__main__":
    main()
