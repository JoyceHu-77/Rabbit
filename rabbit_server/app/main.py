from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

from fastapi import Depends, FastAPI, Header, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app import crud
from app.config import settings
from app.database import Base, SessionLocal, engine, get_db
from app.db_migrate import apply_sqlite_migrations
from app.schemas import DonationCreate, DonationOut, RescueCreate, RescueOut
from app.seed_rabbit import seed_default_donations, seed_rescues_from_json


def _resolve_seed_json_path():
    import os

    env = os.getenv("SEED_JSON_PATH", "").strip()
    if env:
        p = Path(env)
        return p if p.is_file() else None
    here = Path(__file__).resolve()
    for c in (
        here.parent.parent / "data" / "rabbit_seed.json",
        here.parent.parent / "seed" / "rabbit_seed.json",
        here.parents[2] / "Rabbit_iOS" / "Rabbit_iOS" / "rabbit_seed.json",
    ):
        if c.is_file():
            return c
    return None


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    apply_sqlite_migrations(engine)
    if settings.run_seed_on_empty:
        with SessionLocal() as db:
            if crud.count_rescues(db) == 0:
                seed_path = _resolve_seed_json_path()
                if seed_path:
                    seed_rescues_from_json(db, seed_path)
            if crud.count_donations(db) == 0:
                seed_default_donations(db)
    yield


app = FastAPI(title="Rabbit API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/healthz")
def healthz() -> Dict[str, str]:
    return {"status": "ok"}


def _viewer_from_auth(authorization: Optional[str]) -> Optional[str]:
    if not authorization:
        return None
    if authorization.lower().startswith("bearer "):
        return authorization[7:].strip() or None
    return None


@app.get("/v1/rescues")
def get_rescues(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
    page: int = Query(1, ge=1),
    per_page: Optional[int] = Query(None, ge=1),
    sort: Optional[str] = None,
    q: Optional[str] = None,
    status: Optional[str] = None,
    district: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    mine: Optional[int] = Query(None, ge=0, le=1),
    publisher_name: Optional[str] = None,
    envelope: bool = False,
) -> Union[List[Dict[str, Any]], Dict[str, Any]]:
    viewer = _viewer_from_auth(authorization)
    params = crud.RescueListParams(
        page=page,
        per_page=per_page,
        sort=sort,
        q=q,
        status=status,
        district=district,
        date_from=date_from,
        date_to=date_to,
        mine=mine,
        publisher_name=publisher_name,
        viewer_name=viewer,
    )
    rows, total, has_more = crud.list_rescues_filtered(db, params)
    data = [RescueOut.from_orm(r).model_dump(mode="json") for r in rows]
    if envelope:
        return {
            "data": data,
            "meta": {
                "total": total,
                "page": page,
                "per_page": per_page,
                "has_more": has_more,
            },
        }
    return data


@app.post("/v1/rescues", status_code=201)
def post_rescue(body: RescueCreate, db: Session = Depends(get_db)) -> Dict[str, Any]:
    row = crud.upsert_rescue(db, body)
    return RescueOut.from_orm(row).model_dump(mode="json")


@app.patch("/v1/rescues/{rescue_id}")
def patch_rescue(
    rescue_id: str,
    body: RescueCreate,
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    fixed = body.model_copy(update={"id": rescue_id})
    row = crud.upsert_rescue(db, fixed)
    return RescueOut.from_orm(row).model_dump(mode="json")


@app.get("/v1/donations")
def get_donations(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: Optional[int] = Query(None, ge=1),
    donation_type: Optional[str] = Query(None, alias="type"),
    target: Optional[str] = None,
    status: Optional[str] = None,
    q: Optional[str] = None,
    envelope: bool = False,
) -> Union[List[Dict[str, Any]], Dict[str, Any]]:
    params = crud.DonationListParams(
        page=page,
        per_page=per_page,
        donation_type=donation_type,
        target=target,
        status=status,
        q=q,
    )
    rows, total, has_more = crud.list_donations_filtered(db, params)
    data = [DonationOut.from_orm(r).model_dump(mode="json") for r in rows]
    if envelope:
        return {
            "data": data,
            "meta": {
                "total": total,
                "page": page,
                "per_page": per_page,
                "has_more": has_more,
            },
        }
    return data


@app.post("/v1/donations", status_code=201)
def post_donation(body: DonationCreate, db: Session = Depends(get_db)) -> Dict[str, Any]:
    row = crud.create_donation(db, body)
    return DonationOut.from_orm(row).model_dump(mode="json")
