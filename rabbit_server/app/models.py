from __future__ import annotations

from typing import Optional

from sqlalchemy import Boolean, Integer, String, Text
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
