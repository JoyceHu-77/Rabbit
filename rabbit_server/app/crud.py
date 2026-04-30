from __future__ import annotations

import json
import re
from dataclasses import dataclass
from datetime import date
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import DonationPost, RescuePost
from app.schemas import DonationCreate, RescueCreate


def list_rescues(db: Session) -> list[RescuePost]:
    return list(db.scalars(select(RescuePost).order_by(RescuePost.id)).all())


def _iso_prefix(s: str | None) -> str | None:
    if not s:
        return None
    s = s.strip()
    if len(s) >= 10 and s[4] == "-" and s[7] == "-":
        return s[:10]
    return None


def _matches_status(row: RescuePost, statuses: list[str]) -> bool:
    if not statuses:
        return True
    st = (row.status or "").strip()
    return st in statuses


def _matches_district(row: RescuePost, districts: list[str]) -> bool:
    if not districts:
        return True
    loc = row.location or ""
    dist = row.district or ""
    return any(d and (d in loc or d in dist) for d in districts)


def _rescue_date_sort_key(row: RescuePost) -> tuple:
    p = _iso_prefix(row.date)
    if p:
        return (0, p, row.id)
    return (1, row.date or "", row.id)


@dataclass
class RescueListParams:
    page: int = 1
    per_page: Optional[int] = None
    sort: Optional[str] = None
    q: Optional[str] = None
    status: Optional[str] = None
    district: Optional[str] = None
    date_from: Optional[str] = None
    date_to: Optional[str] = None
    mine: Optional[int] = None
    publisher_name: Optional[str] = None
    viewer_name: Optional[str] = None


def list_rescues_filtered(db: Session, p: RescueListParams) -> tuple[list[RescuePost], int, bool]:
    rows = list(db.scalars(select(RescuePost)).all())
    qn = (p.q or "").strip().lower()
    if qn:
        rows = [
            r
            for r in rows
            if qn in (r.title or "").lower()
            or qn in (r.description or "").lower()
            or qn in (r.id or "").lower()
        ]
    statuses = [s.strip() for s in (p.status or "").split(",") if s.strip()]
    if statuses:
        rows = [r for r in rows if _matches_status(r, statuses)]
    districts = [s.strip() for s in (p.district or "").split(",") if s.strip()]
    if districts:
        rows = [r for r in rows if _matches_district(r, districts)]
    pn = (p.publisher_name or "").strip()
    if pn:
        rows = [r for r in rows if (r.publisher_name or "").strip() == pn]
    if p.mine == 1:
        who = (p.viewer_name or "").strip()
        if who:
            rows = [r for r in rows if (r.publisher_name or "").strip() == who]
        else:
            rows = []
    df = _iso_prefix(p.date_from)
    dt = _iso_prefix(p.date_to)
    if df or dt:
        kept: list[RescuePost] = []
        for r in rows:
            rp = _iso_prefix(r.date)
            if not rp:
                continue
            if df and rp < df:
                continue
            if dt and rp > dt:
                continue
            kept.append(r)
        rows = kept
    sort = (p.sort or "").strip().lower()
    if sort:
        rev = not sort.endswith("asc")
        rows = sorted(rows, key=_rescue_date_sort_key, reverse=rev)
    else:
        rows = sorted(rows, key=lambda r: r.id or "")
    total = len(rows)
    page = max(1, p.page)
    per = p.per_page
    has_more = False
    if per is not None and per > 0:
        start = (page - 1) * per
        end = start + per
        has_more = end < total
        rows = rows[start:end]
    return rows, total, has_more


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
        "publisher_name": body.publisher_name,
        "moderation_status": body.moderation_status,
        "audit_rejection_reason": body.audit_rejection_reason,
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


@dataclass
class DonationListParams:
    page: int = 1
    per_page: Optional[int] = None
    donation_type: Optional[str] = None
    target: Optional[str] = None
    status: Optional[str] = None
    q: Optional[str] = None


def list_donations_filtered(db: Session, p: DonationListParams) -> tuple[list[DonationPost], int, bool]:
    rows = list(db.scalars(select(DonationPost).order_by(DonationPost.id.desc())).all())
    qn = (p.q or "").strip().lower()
    if qn:
        rows = [
            r
            for r in rows
            if qn in (r.title or "").lower()
            or qn in (r.description or "").lower()
            or qn in (r.id or "").lower()
        ]
    if p.donation_type and p.donation_type.strip():
        t = p.donation_type.strip()
        rows = [r for r in rows if (r.donation_type or "") == t]
    if p.target and p.target.strip():
        t = p.target.strip()
        rows = [r for r in rows if (r.target or "") == t]
    if p.status and p.status.strip():
        t = p.status.strip()
        rows = [r for r in rows if (r.status or "") == t]
    total = len(rows)
    page = max(1, p.page)
    per = p.per_page
    has_more = False
    if per is not None and per > 0:
        start = (page - 1) * per
        end = start + per
        has_more = end < total
        rows = rows[start:end]
    return rows, total, has_more


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
