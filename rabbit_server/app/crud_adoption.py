from __future__ import annotations

import json
import time
from typing import Optional

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models import AdoptionIntent, CommunityPost, CommunityPostLike, RescuePost
from app.schemas_adoption import AdoptionIntentCreate, CommunityPostCreate


def _new_intent_id() -> str:
    return f"AI{int(time.time() * 1000)}"


def _new_post_id() -> str:
    return f"RC{int(time.time() * 1000)}"


def create_adoption_intent(
    db: Session,
    body: AdoptionIntentCreate,
    *,
    viewer_key: str = "anonymous",
) -> AdoptionIntent:
    rescue = db.get(RescuePost, body.rescue_id)
    if rescue is None:
        raise ValueError("rescue_not_found")
    row = AdoptionIntent(
        id=_new_intent_id(),
        rescue_id=body.rescue_id,
        applicant_name=body.applicant_name.strip(),
        applicant_phone=body.applicant_phone.strip(),
        note=(body.note or "").strip() or None,
        status="pending",
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    rabbit_name = (rescue.title or "").split(" - ", 1)[0].strip() or body.rescue_id
    from app import crud_profile

    if viewer_key and viewer_key != "anonymous":
        crud_profile.create_inbox_message(
            db,
            viewer_key,
            title="领养申请已提交",
            body=f"您已提交对 {rabbit_name}（{body.rescue_id}）的领养意向，请等待管理员审核。",
        )
    crud_profile.create_admin_notification(
        db,
        type="adopt",
        title="新领养意向",
        content=f"救援帖 {body.rescue_id}（{rabbit_name}）收到领养申请，联系人 {body.applicant_name}。",
    )
    return row


def list_adoption_intents(
    db: Session,
    *,
    rescue_id: Optional[str] = None,
    status: Optional[str] = None,
    page: int = 1,
    per_page: Optional[int] = None,
) -> tuple[list[AdoptionIntent], int, bool]:
    q = select(AdoptionIntent).order_by(AdoptionIntent.created_at.desc())
    if rescue_id:
        q = q.where(AdoptionIntent.rescue_id == rescue_id)
    if status:
        q = q.where(AdoptionIntent.status == status)
    rows = list(db.scalars(q).all())
    total = len(rows)
    page = max(1, page)
    per = per_page
    has_more = False
    if per is not None and per > 0:
        start = (page - 1) * per
        end = start + per
        has_more = end < total
        rows = rows[start:end]
    return rows, total, has_more


def get_adoption_intent(db: Session, intent_id: str) -> AdoptionIntent | None:
    return db.get(AdoptionIntent, intent_id)


def patch_adoption_intent_status(db: Session, intent_id: str, status: str) -> AdoptionIntent | None:
    row = db.get(AdoptionIntent, intent_id)
    if row is None:
        return None
    row.status = status
    db.commit()
    db.refresh(row)
    return row


def list_community_posts(
    db: Session,
    *,
    page: int = 1,
    per_page: Optional[int] = None,
    viewer_key: str,
) -> tuple[list[tuple[CommunityPost, bool]], int, bool]:
    q = select(CommunityPost).order_by(CommunityPost.created_at.desc())
    rows = list(db.scalars(q).all())
    total = len(rows)
    page = max(1, page)
    per = per_page
    has_more = False
    if per is not None and per > 0:
        start = (page - 1) * per
        end = start + per
        has_more = end < total
        rows = rows[start:end]

    out: list[tuple[CommunityPost, bool]] = []
    for r in rows:
        stmt = select(CommunityPostLike).where(
            CommunityPostLike.post_id == r.id,
            CommunityPostLike.viewer_key == viewer_key,
        )
        liked = db.scalars(stmt).first() is not None
        out.append((r, liked))
    return out, total, has_more


def create_community_post(db: Session, body: CommunityPostCreate) -> CommunityPost:
    row = CommunityPost(
        id=_new_post_id(),
        author_name=(body.author_name or "爱心网友").strip() or "爱心网友",
        title=(body.title or "分享").strip() or "分享",
        content=body.content or "",
        images_json=json.dumps(body.images or []),
        likes=0,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def get_community_post(db: Session, post_id: str) -> CommunityPost | None:
    return db.get(CommunityPost, post_id)


def delete_community_post(db: Session, post_id: str) -> bool:
    row = db.get(CommunityPost, post_id)
    if row is None:
        return False
    db.execute(delete(CommunityPostLike).where(CommunityPostLike.post_id == post_id))
    db.delete(row)
    db.commit()
    return True


def toggle_community_like(
    db: Session, post_id: str, viewer_key: str
) -> tuple[CommunityPost, bool] | None:
    row = db.get(CommunityPost, post_id)
    if row is None:
        return None
    stmt = select(CommunityPostLike).where(
        CommunityPostLike.post_id == post_id,
        CommunityPostLike.viewer_key == viewer_key,
    )
    existing = db.scalars(stmt).first()
    if existing is not None:
        db.delete(existing)
        row.likes = max(0, (row.likes or 0) - 1)
        liked = False
    else:
        db.add(CommunityPostLike(post_id=post_id, viewer_key=viewer_key))
        row.likes = (row.likes or 0) + 1
        liked = True
    db.commit()
    db.refresh(row)
    return row, liked
