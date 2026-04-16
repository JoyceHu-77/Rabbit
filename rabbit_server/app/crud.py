from __future__ import annotations

import json
import re
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import DonationPost, RescuePost
from app.schemas import DonationCreate, RescueCreate


def list_rescues(db: Session) -> list[RescuePost]:
    return list(db.scalars(select(RescuePost).order_by(RescuePost.id)).all())


def upsert_rescue(db: Session, body: RescueCreate) -> RescuePost:
    row = db.get(RescuePost, body.id)
    payload = {
        "id": body.id,
        "title": body.title,
        "description": body.description,
        "images_json": json.dumps(body.images),
        "location": body.location,
        "city": body.city,
        "district": body.district,
        "date": body.date,
        "status": body.status,
        "finder_name": body.finder_name,
        "finder_contact": body.finder_contact,
        "finder_is_public": body.finder_is_public,
        "organizer_name": body.organizer_name,
        "organizer_contact": body.organizer_contact,
        "organizer_is_public": body.organizer_is_public,
        "wechat_qr": body.wechat_qr,
        "health_status": body.health_status,
        "sterilized_status": body.sterilized_status,
        "source_rabbit_id": body.source_rabbit_id,
    }
    if row is None:
        row = RescuePost(**payload)
        db.add(row)
    else:
        for k, v in payload.items():
            setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


def list_donations(db: Session) -> list[DonationPost]:
    return list(db.scalars(select(DonationPost).order_by(DonationPost.id.desc())).all())


def _next_donation_numeric_id(db: Session) -> int:
    rows = db.scalars(select(DonationPost.id)).all()
    mx = 0
    for sid in rows:
        m = re.match(r"D(\d+)$", sid or "")
        if m:
            mx = max(mx, int(m.group(1)))
    return mx + 1


def create_donation(db: Session, body: DonationCreate) -> DonationPost:
    nid = _next_donation_numeric_id(db)
    did = f"D{nid:03d}"
    row = DonationPost(
        id=did,
        title=body.title,
        description=body.description,
        image=body.image,
        donation_type=body.type,
        target=body.target,
        status="待领取",
        contact_name=body.contact_name,
        contact_phone=body.contact_phone,
        date=date.today().isoformat(),
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def count_rescues(db: Session) -> int:
    return int(db.scalar(select(func.count(RescuePost.id))) or 0)


def count_donations(db: Session) -> int:
    return int(db.scalar(select(func.count(DonationPost.id))) or 0)
