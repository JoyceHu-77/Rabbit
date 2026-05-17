"""个人页 API 模型。"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models import AdminNotification as AdminNotificationRow
from app.models import UserInboxMessage as UserInboxRow
from app.models import UserOrder as UserOrderRow
from app.models import UserProfile as UserProfileRow


class ProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    viewer_key: str
    user_name: str
    user_bio: str
    badges: int
    cloud_coins: int
    is_admin: bool
    is_logged_in: bool
    shipping_address: str

    @classmethod
    def from_row(cls, row: UserProfileRow) -> "ProfileOut":
        return cls(
            viewer_key=row.viewer_key,
            user_name=row.user_name,
            user_bio=row.user_bio,
            badges=row.badges,
            cloud_coins=row.cloud_coins,
            is_admin=row.is_admin,
            is_logged_in=row.is_logged_in,
            shipping_address=row.shipping_address or "",
        )


class ProfilePatch(BaseModel):
    model_config = ConfigDict(extra="ignore")

    user_name: Optional[str] = None
    user_bio: Optional[str] = None
    badges: Optional[int] = None
    cloud_coins: Optional[int] = None
    is_admin: Optional[bool] = None
    is_logged_in: Optional[bool] = None
    shipping_address: Optional[str] = None

    @model_validator(mode="before")
    @classmethod
    def aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        for camel, snake in (
            ("userName", "user_name"),
            ("userBio", "user_bio"),
            ("cloudCoins", "cloud_coins"),
            ("isAdmin", "is_admin"),
            ("isLoggedIn", "is_logged_in"),
            ("shippingAddress", "shipping_address"),
        ):
            if camel in out and snake not in out:
                out[snake] = out.pop(camel)
        return out


class WalletAdjust(BaseModel):
    badges_delta: int = 0
    cloud_coins_delta: int = 0

    @model_validator(mode="before")
    @classmethod
    def aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        for camel, snake in (
            ("badgesDelta", "badges_delta"),
            ("cloudCoinsDelta", "cloud_coins_delta"),
        ):
            if camel in out and snake not in out:
                out[snake] = out.pop(camel)
        return out


class InboxMessageOut(BaseModel):
    id: str
    title: str
    body: str
    created_at: datetime
    read: bool

    @classmethod
    def from_row(cls, row: UserInboxRow) -> "InboxMessageOut":
        return cls(
            id=row.id,
            title=row.title,
            body=row.body,
            created_at=row.created_at,
            read=row.read,
        )


class AdminNotificationOut(BaseModel):
    id: str
    type: str
    title: str
    content: str
    created_at: datetime
    read: bool

    @classmethod
    def from_row(cls, row: AdminNotificationRow) -> "AdminNotificationOut":
        return cls(
            id=row.id,
            type=row.type,
            title=row.title,
            content=row.content,
            created_at=row.created_at,
            read=row.read,
        )


class OrderOut(BaseModel):
    id: str
    title: str
    subtitle: str
    status: str
    cloud_coins_reward: int
    created_at: datetime

    @classmethod
    def from_row(cls, row: UserOrderRow) -> "OrderOut":
        return cls(
            id=row.id,
            title=row.title,
            subtitle=row.subtitle,
            status=row.status,
            cloud_coins_reward=row.cloud_coins_reward,
            created_at=row.created_at,
        )


class OrderPayOut(BaseModel):
    order_id: str
    cloud_coins_granted: int
    profile: ProfileOut
