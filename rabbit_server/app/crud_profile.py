from __future__ import annotations

import time
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import AdminNotification, UserInboxMessage, UserOrder, UserProfile
from app.schemas_profile import ProfileOut, ProfilePatch


def _ts_id(prefix: str) -> str:
    return f"{prefix}{int(time.time() * 1000)}"


def get_or_create_profile(db: Session, viewer_key: str) -> UserProfile:
    row = db.get(UserProfile, viewer_key)
    if row is not None:
        return row
    display = viewer_key if viewer_key not in ("", "anonymous") else "爱心用户"
    row = UserProfile(
        viewer_key=viewer_key,
        user_name=display,
        user_bio="热爱兔兔，致力于救助流浪动物",
        badges=3,
        cloud_coins=15,
        is_admin=False,
        is_logged_in=viewer_key != "anonymous",
        shipping_address="上海市浦东新区××路××号",
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    ensure_demo_order(db, viewer_key)
    return row


def ensure_demo_order(db: Session, viewer_key: str) -> None:
    stmt = select(UserOrder).where(
        UserOrder.viewer_key == viewer_key,
        UserOrder.status == "pending",
    )
    if db.scalars(stmt).first() is not None:
        return
    db.add(
        UserOrder(
            id=_ts_id("ORD"),
            viewer_key=viewer_key,
            title="爱心橱窗 · 电子照片",
            subtitle="¥5 · 演示订单",
            status="pending",
            cloud_coins_reward=5,
        )
    )
    db.commit()


def patch_profile(db: Session, viewer_key: str, body: ProfilePatch) -> UserProfile:
    row = get_or_create_profile(db, viewer_key)
    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        if k == "badges" and v is not None:
            row.badges = max(0, int(v))
        elif k == "cloud_coins" and v is not None:
            row.cloud_coins = max(0, int(v))
        elif hasattr(row, k) and v is not None:
            setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


def adjust_wallet(
    db: Session,
    viewer_key: str,
    *,
    badges_delta: int = 0,
    cloud_coins_delta: int = 0,
) -> UserProfile:
    row = get_or_create_profile(db, viewer_key)
    row.badges = max(0, (row.badges or 0) + badges_delta)
    row.cloud_coins = max(0, (row.cloud_coins or 0) + cloud_coins_delta)
    db.commit()
    db.refresh(row)
    return row


def create_inbox_message(
    db: Session,
    viewer_key: str,
    *,
    title: str,
    body: str,
) -> UserInboxMessage:
    row = UserInboxMessage(
        id=_ts_id("UM"),
        viewer_key=viewer_key,
        title=title.strip(),
        body=body.strip(),
        read=False,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_inbox_messages(db: Session, viewer_key: str) -> list[UserInboxMessage]:
    stmt = (
        select(UserInboxMessage)
        .where(UserInboxMessage.viewer_key == viewer_key)
        .order_by(UserInboxMessage.created_at.desc())
    )
    return list(db.scalars(stmt).all())


def mark_inbox_read(db: Session, viewer_key: str, message_id: str) -> bool:
    row = db.get(UserInboxMessage, message_id)
    if row is None or row.viewer_key != viewer_key:
        return False
    row.read = True
    db.commit()
    return True


def inbox_unread_count(db: Session, viewer_key: str) -> int:
    stmt = select(func.count()).select_from(UserInboxMessage).where(
        UserInboxMessage.viewer_key == viewer_key,
        UserInboxMessage.read.is_(False),
    )
    return int(db.scalar(stmt) or 0)


def create_admin_notification(
    db: Session,
    *,
    type: str,
    title: str,
    content: str,
) -> AdminNotification:
    row = AdminNotification(
        id=_ts_id("ADM"),
        type=type.strip(),
        title=title.strip(),
        content=content.strip(),
        read=False,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_admin_notifications(db: Session) -> list[AdminNotification]:
    stmt = select(AdminNotification).order_by(AdminNotification.created_at.desc())
    return list(db.scalars(stmt).all())


def mark_admin_read(db: Session, notification_id: str) -> bool:
    row = db.get(AdminNotification, notification_id)
    if row is None:
        return False
    row.read = True
    db.commit()
    return True


def admin_unread_count(db: Session) -> int:
    stmt = select(func.count()).select_from(AdminNotification).where(
        AdminNotification.read.is_(False)
    )
    return int(db.scalar(stmt) or 0)


def list_orders(db: Session, viewer_key: str) -> list[UserOrder]:
    ensure_demo_order(db, viewer_key)
    stmt = (
        select(UserOrder)
        .where(UserOrder.viewer_key == viewer_key)
        .order_by(UserOrder.created_at.desc())
    )
    return list(db.scalars(stmt).all())


def pay_order(db: Session, viewer_key: str, order_id: str) -> tuple[UserOrder, UserProfile] | None:
    row = db.get(UserOrder, order_id)
    if row is None or row.viewer_key != viewer_key:
        return None
    if row.status == "paid":
        profile = get_or_create_profile(db, viewer_key)
        return row, profile
    reward = max(0, row.cloud_coins_reward or 0)
    profile = adjust_wallet(db, viewer_key, cloud_coins_delta=reward)
    row.status = "paid"
    db.commit()
    db.refresh(row)
    create_inbox_message(
        db,
        viewer_key,
        title="订单支付成功",
        body=f"「{row.title}」已完成支付，{reward} 云养币已到账。",
    )
    create_admin_notification(
        db,
        type="payment",
        title="爱心橱窗订单待核对",
        content=f"用户 {viewer_key} 已完成支付：{row.subtitle or row.title}（已发放 {reward} 云养币）。请在管理后台核对收款与发货。",
    )
    return row, profile
