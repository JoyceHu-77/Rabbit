"""启动时为 SQLite 追加列，避免与 iOS 新字段不一致导致崩溃。"""

from __future__ import annotations

from sqlalchemy import Engine, text


def apply_sqlite_migrations(engine: Engine) -> None:
    if "sqlite" not in str(engine.url).lower():
        return
    with engine.connect() as conn:
        r = conn.execute(text("PRAGMA table_info(rescue_posts)"))
        cols = {row[1] for row in r}
        alters: list[str] = []
        if "publisher_name" not in cols:
            alters.append("ALTER TABLE rescue_posts ADD COLUMN publisher_name VARCHAR(128)")
        if "moderation_status" not in cols:
            alters.append(
                "ALTER TABLE rescue_posts ADD COLUMN moderation_status VARCHAR(32) DEFAULT 'approved'"
            )
        if "audit_rejection_reason" not in cols:
            alters.append("ALTER TABLE rescue_posts ADD COLUMN audit_rejection_reason TEXT")
        for sql in alters:
            conn.execute(text(sql))
        conn.commit()
