from __future__ import annotations

import json
import time
from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import ActivityBanner, OfflineEvent, RescuePost
from app.schemas_activity import CharityProductOut, OfflineEventCreate, OfflineEventPatch


def _new_offline_id() -> str:
    return f"OE{int(time.time() * 1000)}"


def list_banners(db: Session) -> list[ActivityBanner]:
    return list(
        db.scalars(select(ActivityBanner).order_by(ActivityBanner.sort_order, ActivityBanner.id)).all()
    )


def list_offline_events(
    db: Session,
    *,
    is_past: Optional[bool] = None,
    page: int = 1,
    per_page: Optional[int] = None,
) -> tuple[list[OfflineEvent], int, bool]:
    q = select(OfflineEvent).order_by(OfflineEvent.created_at.desc())
    if is_past is not None:
        q = q.where(OfflineEvent.is_past == is_past)
    rows = list(db.scalars(q).all())
    total = len(rows)
    page = max(1, page)
    has_more = False
    if per_page is not None and per_page > 0:
        start = (page - 1) * per_page
        end = start + per_page
        has_more = end < total
        rows = rows[start:end]
    return rows, total, has_more


def create_offline_event(db: Session, body: OfflineEventCreate) -> OfflineEvent:
    row = OfflineEvent(
        id=_new_offline_id(),
        title=body.title.strip(),
        date=(body.date or "").strip() or "日期待定",
        location=(body.location or "").strip() or "地点待定",
        image_url=(body.image_url or "").strip()
        or "https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600",
        banner_url=(body.banner_url or "").strip() or None,
        description=(body.description or "").strip() or "活动内容待定，敬请关注。",
        is_past=body.is_past,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def get_offline_event(db: Session, event_id: str) -> OfflineEvent | None:
    return db.get(OfflineEvent, event_id)


def patch_offline_event(db: Session, event_id: str, body: OfflineEventPatch) -> OfflineEvent | None:
    row = db.get(OfflineEvent, event_id)
    if row is None:
        return None
    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


def delete_offline_event(db: Session, event_id: str) -> bool:
    row = db.get(OfflineEvent, event_id)
    if row is None:
        return False
    db.delete(row)
    db.commit()
    return True


def _rabbit_short_name(title: str) -> str:
    if " - " in title:
        return title.split(" - ", 1)[0].strip()
    return title.strip()


def list_charity_products(db: Session) -> list[CharityProductOut]:
    rows = list(db.scalars(select(RescuePost)).all())
    out: list[CharityProductOut] = []
    for r in rows:
        mod = (r.moderation_status or "").strip()
        if mod and mod != "approved":
            continue
        st = (r.status or "").strip()
        if st in ("已去世", "已领养"):
            continue
        imgs: list[str] = []
        try:
            raw = json.loads(r.images_json or "[]")
            if isinstance(raw, list):
                imgs = [str(x) for x in raw]
        except json.JSONDecodeError:
            pass
        name = _rabbit_short_name(r.title or "")
        out.append(
            CharityProductOut(
                id=r.id,
                title=f"{name}的电子照片",
                rabbit_name=name,
                image=imgs[0] if imgs else "",
                description=f"云养{name}兔兔的一点心意，用于粮草、医疗与生活支出。",
                price=5,
                badges=1,
                cloud_coins=5,
            )
        )
    return out


def validate_rescue_for_cloud(db: Session, rescue_id: str) -> RescuePost | None:
    row = db.get(RescuePost, rescue_id)
    if row is None:
        return None
    mod = (row.moderation_status or "").strip()
    if mod and mod != "approved":
        return None
    if (row.status or "").strip() in ("已去世", "已领养"):
        return None
    return row
