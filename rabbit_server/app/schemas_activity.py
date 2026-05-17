"""活动 Tab：横幅、线下活动、爱心橱窗（由救援帖派生）、云养确认。"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models import ActivityBanner as ActivityBannerRow
from app.models import OfflineEvent as OfflineEventRow


class ActivityBannerOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    id: str
    title: str
    subtitle: str
    image_url: str
    sort_order: int
    target_key: str

    @classmethod
    def from_row(cls, row: ActivityBannerRow) -> "ActivityBannerOut":
        return cls(
            id=row.id,
            title=row.title,
            subtitle=row.subtitle,
            image_url=row.image_url,
            sort_order=row.sort_order,
            target_key=row.target_key,
        )


class OfflineEventCreate(BaseModel):
    model_config = ConfigDict(extra="ignore")

    title: str = Field(..., min_length=1)
    date: str = ""
    location: str = ""
    image_url: str = ""
    banner_url: Optional[str] = None
    description: str = ""
    is_past: bool = False

    @model_validator(mode="before")
    @classmethod
    def aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        for camel, snake in (
            ("imageUrl", "image_url"),
            ("bannerUrl", "banner_url"),
            ("isPast", "is_past"),
        ):
            if camel in out and snake not in out:
                out[snake] = out.pop(camel)
        return out


class OfflineEventOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    id: str
    title: str
    date: str
    location: str
    image_url: str
    banner_url: Optional[str]
    description: str
    is_past: bool
    created_at: datetime

    @classmethod
    def from_row(cls, row: OfflineEventRow) -> "OfflineEventOut":
        return cls(
            id=row.id,
            title=row.title,
            date=row.date,
            location=row.location,
            image_url=row.image_url,
            banner_url=row.banner_url,
            description=row.description,
            is_past=row.is_past,
            created_at=row.created_at,
        )


class OfflineEventPatch(BaseModel):
    model_config = ConfigDict(extra="ignore")

    title: Optional[str] = None
    date: Optional[str] = None
    location: Optional[str] = None
    image_url: Optional[str] = None
    banner_url: Optional[str] = None
    description: Optional[str] = None
    is_past: Optional[bool] = None

    @model_validator(mode="before")
    @classmethod
    def patch_aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        for camel, snake in (
            ("imageUrl", "image_url"),
            ("bannerUrl", "banner_url"),
            ("isPast", "is_past"),
        ):
            if camel in out and snake not in out:
                out[snake] = out.pop(camel)
        return out


class CharityProductOut(BaseModel):
    """爱心橱窗商品：由救援帖映射，与 iOS CharityShopProduct 对齐。"""

    id: str
    title: str
    rabbit_name: str
    image: str
    description: str
    price: int = 5
    badges: int = 1
    cloud_coins: int = 5


class CloudAdoptConfirm(BaseModel):
    model_config = ConfigDict(extra="ignore")

    rescue_id: str = Field(..., min_length=1)
    amount_yuan: int = Field(100, ge=1, le=99999)

    @model_validator(mode="before")
    @classmethod
    def aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        if "rescueId" in out and "rescue_id" not in out:
            out["rescue_id"] = out.pop("rescueId")
        if "amountYuan" in out and "amount_yuan" not in out:
            out["amount_yuan"] = out.pop("amountYuan")
        return out


class CloudAdoptConfirmOut(BaseModel):
    rescue_id: str
    amount_yuan: int
    cloud_coins_granted: int
    badges_granted: int = 1
    profile: Optional[Any] = None  # ProfileOut dict when wallet updated
