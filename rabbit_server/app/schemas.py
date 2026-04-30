from __future__ import annotations

import json
from typing import Any, Optional

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, model_validator

from app.models import DonationPost, RescuePost


class RescueOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    id: str
    title: str
    description: str
    images: list[str]
    location: str
    city: str
    district: str
    date: str
    status: str
    finder_name: Optional[str] = None
    finder_contact: Optional[str] = None
    finder_is_public: Optional[bool] = False
    organizer_name: Optional[str] = None
    organizer_contact: Optional[str] = None
    organizer_is_public: Optional[bool] = False
    wechat_qr: Optional[str] = None
    health_status: Optional[str] = None
    sterilized_status: Optional[str] = None
    source_rabbit_id: Optional[int] = 0
    publisher_name: Optional[str] = None
    moderation_status: Optional[str] = "approved"
    audit_rejection_reason: Optional[str] = None

    @classmethod
    def from_orm(cls, row: RescuePost) -> "RescueOut":
        try:
            imgs: list[str] = json.loads(row.images_json or "[]")
        except json.JSONDecodeError:
            imgs = []
        return cls(
            id=row.id,
            title=row.title,
            description=row.description,
            images=imgs,
            location=row.location,
            city=row.city,
            district=row.district,
            date=row.date,
            status=row.status,
            finder_name=row.finder_name,
            finder_contact=row.finder_contact,
            finder_is_public=row.finder_is_public,
            organizer_name=row.organizer_name,
            organizer_contact=row.organizer_contact,
            organizer_is_public=row.organizer_is_public,
            wechat_qr=row.wechat_qr,
            health_status=row.health_status,
            sterilized_status=row.sterilized_status,
            source_rabbit_id=row.source_rabbit_id,
            publisher_name=row.publisher_name,
            moderation_status=row.moderation_status or "approved",
            audit_rejection_reason=row.audit_rejection_reason,
        )


class RescueCreate(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    title: str
    description: str
    images: list[str]
    location: str
    city: str
    district: str
    date: str
    status: str
    finder_name: Optional[str] = None
    finder_contact: Optional[str] = None
    finder_is_public: bool = False
    organizer_name: Optional[str] = None
    organizer_contact: Optional[str] = None
    organizer_is_public: bool = False
    wechat_qr: Optional[str] = None
    health_status: Optional[str] = None
    sterilized_status: Optional[str] = None
    source_rabbit_id: int = 0
    publisher_name: Optional[str] = None
    moderation_status: str = "pending"
    audit_rejection_reason: Optional[str] = None

    @model_validator(mode="before")
    @classmethod
    def accept_aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        key_map = {
            "finderName": "finder_name",
            "finderContact": "finder_contact",
            "finderIsPublic": "finder_is_public",
            "organizerName": "organizer_name",
            "organizerContact": "organizer_contact",
            "organizerIsPublic": "organizer_is_public",
            "wechatQR": "wechat_qr",
            "healthStatus": "health_status",
            "sterilizedStatus": "sterilized_status",
            "sourceRabbitId": "source_rabbit_id",
            "publisherName": "publisher_name",
            "moderationStatus": "moderation_status",
            "auditRejectionReason": "audit_rejection_reason",
        }
        for camel, snake in key_map.items():
            if camel in out and snake not in out:
                out[snake] = out.pop(camel)
        return out


class DonationOut(BaseModel):
    model_config = ConfigDict(protected_namespaces=(), from_attributes=False)

    id: str
    title: str
    description: str
    image: str
    type: str
    target: str
    status: str
    contact_name: str
    contact_phone: str
    date: str

    @classmethod
    def from_orm(cls, row: DonationPost) -> "DonationOut":
        return cls(
            id=row.id,
            title=row.title,
            description=row.description,
            image=row.image,
            type=row.donation_type,
            target=row.target,
            status=row.status,
            contact_name=row.contact_name,
            contact_phone=row.contact_phone,
            date=row.date,
        )


class DonationCreate(BaseModel):
    model_config = ConfigDict(protected_namespaces=(), extra="ignore")

    title: str
    description: str
    image: str
    type: str
    target: str
    contact_name: str = Field(validation_alias=AliasChoices("contact_name", "contactName"))
    contact_phone: str = Field(validation_alias=AliasChoices("contact_phone", "contactPhone"))
