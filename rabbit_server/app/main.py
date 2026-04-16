from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, Dict, List

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app import crud
from app.config import settings
from app.database import Base, SessionLocal, engine, get_db
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


@app.get("/v1/rescues")
def get_rescues(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    return [RescueOut.from_orm(r).model_dump(mode="json") for r in crud.list_rescues(db)]


@app.post("/v1/rescues", status_code=201)
def post_rescue(body: RescueCreate, db: Session = Depends(get_db)) -> Dict[str, Any]:
    row = crud.upsert_rescue(db, body)
    return RescueOut.from_orm(row).model_dump(mode="json")


@app.get("/v1/donations")
def get_donations(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    return [DonationOut.from_orm(r).model_dump(mode="json") for r in crud.list_donations(db)]


@app.post("/v1/donations", status_code=201)
def post_donation(body: DonationCreate, db: Session = Depends(get_db)) -> Dict[str, Any]:
    row = crud.create_donation(db, body)
    return DonationOut.from_orm(row).model_dump(mode="json")
