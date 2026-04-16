from __future__ import annotations

from collections.abc import Generator
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import settings


def _sqlite_connect_args(url: str) -> dict:
    return {"check_same_thread": False} if url.startswith("sqlite") else {}


_db_url = settings.database_url
if _db_url.startswith("sqlite:///"):
    _raw = _db_url[len("sqlite:///") :]
    Path(_raw).expanduser().resolve().parent.mkdir(parents=True, exist_ok=True)

engine = create_engine(
    _db_url,
    connect_args=_sqlite_connect_args(_db_url),
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
