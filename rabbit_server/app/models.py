from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class RescuePost(Base):
    __tablename__ = "rescue_posts"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    title: Mapped[str] = mapped_column(String(512), default="")
    description: Mapped[str] = mapped_column(Text, default="")
    images_json: Mapped[str] = mapped_column(Text, default="[]")  # JSON array of strings
    location: Mapped[str] = mapped_column(String(256), default="")
    city: Mapped[str] = mapped_column(String(128), default="")
    district: Mapped[str] = mapped_column(String(128), default="")
    date: Mapped[str] = mapped_column(String(64), default="")
    status: Mapped[str] = mapped_column(String(64), default="")
    finder_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    finder_contact: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    finder_is_public: Mapped[bool] = mapped_column(Boolean, default=False)
    organizer_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    organizer_contact: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    organizer_is_public: Mapped[bool] = mapped_column(Boolean, default=False)
    wechat_qr: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    health_status: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    sterilized_status: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    source_rabbit_id: Mapped[int] = mapped_column(Integer, default=0)
    publisher_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    moderation_status: Mapped[str] = mapped_column(String(32), default="approved")
    audit_rejection_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)


class DonationPost(Base):
    __tablename__ = "donation_posts"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    title: Mapped[str] = mapped_column(String(512), default="")
    description: Mapped[str] = mapped_column(Text, default="")
    image: Mapped[str] = mapped_column(String(1024), default="")
    donation_type: Mapped[str] = mapped_column("type", String(32), default="捐赠")
    target: Mapped[str] = mapped_column(String(64), default="共享")
    status: Mapped[str] = mapped_column(String(32), default="待领取")
    contact_name: Mapped[str] = mapped_column(String(128), default="")
    contact_phone: Mapped[str] = mapped_column(String(128), default="")
    date: Mapped[str] = mapped_column(String(32), default="")


class AdoptionIntent(Base):
    """领养 Tab — 用户提交的领养意向（关联救援帖 id）。"""

    __tablename__ = "adoption_intents"

    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    rescue_id: Mapped[str] = mapped_column(String(32), index=True)
    applicant_name: Mapped[str] = mapped_column(String(128), default="")
    applicant_phone: Mapped[str] = mapped_column(String(64), default="")
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(32), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class CommunityPost(Base):
    """领养 Tab — 爱兔社区动态。"""

    __tablename__ = "rabbit_community_posts"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    author_name: Mapped[str] = mapped_column(String(128), default="")
    title: Mapped[str] = mapped_column(String(512), default="")
    content: Mapped[str] = mapped_column(Text, default="")
    images_json: Mapped[str] = mapped_column(Text, default="[]")
    likes: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class CommunityPostLike(Base):
    """点赞记录（viewer_key 可与 Bearer 占位一致）。"""

    __tablename__ = "community_post_likes"

    post_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    viewer_key: Mapped[str] = mapped_column(String(256), primary_key=True)


class ActivityBanner(Base):
    """活动 Tab 顶部轮播/子活动入口。"""

    __tablename__ = "activity_banners"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    title: Mapped[str] = mapped_column(String(256), default="")
    subtitle: Mapped[str] = mapped_column(String(512), default="")
    image_url: Mapped[str] = mapped_column(String(1024), default="")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    # 与客户端子区块对应：checkin | cloud
    target_key: Mapped[str] = mapped_column(String(32), default="checkin")


class OfflineEvent(Base):
    """活动 Tab — 线下活动。"""

    __tablename__ = "offline_events"

    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    title: Mapped[str] = mapped_column(String(512), default="")
    date: Mapped[str] = mapped_column(String(64), default="")
    location: Mapped[str] = mapped_column(String(256), default="")
    image_url: Mapped[str] = mapped_column(String(1024), default="")
    banner_url: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)
    description: Mapped[str] = mapped_column(Text, default="")
    is_past: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class UserProfile(Base):
    """个人页 — 按 Bearer（viewer_key）区分用户。"""

    __tablename__ = "user_profiles"

    viewer_key: Mapped[str] = mapped_column(String(256), primary_key=True)
    user_name: Mapped[str] = mapped_column(String(128), default="爱心用户")
    user_bio: Mapped[str] = mapped_column(String(512), default="")
    badges: Mapped[int] = mapped_column(Integer, default=0)
    cloud_coins: Mapped[int] = mapped_column(Integer, default=0)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    is_logged_in: Mapped[bool] = mapped_column(Boolean, default=True)
    shipping_address: Mapped[str] = mapped_column(String(512), default="")


class UserInboxMessage(Base):
    __tablename__ = "user_inbox_messages"

    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    viewer_key: Mapped[str] = mapped_column(String(256), index=True)
    title: Mapped[str] = mapped_column(String(256), default="")
    body: Mapped[str] = mapped_column(Text, default="")
    read: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class AdminNotification(Base):
    """管理员待办通知（全局队列）。"""

    __tablename__ = "admin_notifications"

    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    type: Mapped[str] = mapped_column(String(32), default="")
    title: Mapped[str] = mapped_column(String(256), default="")
    content: Mapped[str] = mapped_column(Text, default="")
    read: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class UserOrder(Base):
    __tablename__ = "user_orders"

    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    viewer_key: Mapped[str] = mapped_column(String(256), index=True)
    title: Mapped[str] = mapped_column(String(256), default="")
    subtitle: Mapped[str] = mapped_column(String(256), default="")
    status: Mapped[str] = mapped_column(String(32), default="pending")
    cloud_coins_reward: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
