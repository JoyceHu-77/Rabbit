"""领养 Tab：领养意向、爱兔社区帖子的请求/响应模型。"""

from __future__ import annotations

import json
from datetime import datetime
from typing import Any, List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models import AdoptionIntent as AdoptionIntentRow
from app.models import CommunityPost as CommunityPostRow


class AdoptionIntentCreate(BaseModel):
    model_config = ConfigDict(extra="ignore")

    rescue_id: str = Field(..., min_length=1)
    applicant_name: str = Field(..., min_length=1)
    applicant_phone: str = Field(..., min_length=3)
    note: Optional[str] = None

    @model_validator(mode="before")
    @classmethod
    def aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        if "rescueId" in out and "rescue_id" not in out:
            out["rescue_id"] = out.pop("rescueId")
        if "applicantName" in out and "applicant_name" not in out:
            out["applicant_name"] = out.pop("applicantName")
        if "applicantPhone" in out and "applicant_phone" not in out:
            out["applicant_phone"] = out.pop("applicantPhone")
        return out


class AdoptionIntentOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    id: str
    rescue_id: str
    applicant_name: str
    applicant_phone: str
    note: Optional[str]
    status: str
    created_at: datetime

    @classmethod
    def from_row(cls, row: AdoptionIntentRow) -> "AdoptionIntentOut":
        return cls(
            id=row.id,
            rescue_id=row.rescue_id,
            applicant_name=row.applicant_name,
            applicant_phone=row.applicant_phone,
            note=row.note,
            status=row.status,
            created_at=row.created_at,
        )


class AdoptionIntentStatusPatch(BaseModel):
    """管理员审核：更新意向状态。"""

    status: Literal["pending", "approved", "rejected"]


class CommunityPostCreate(BaseModel):
    model_config = ConfigDict(extra="ignore")

    author_name: str = ""
    title: str = ""
    content: str = ""
    images: List[str] = Field(default_factory=list)

    @model_validator(mode="before")
    @classmethod
    def aliases(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        out = dict(data)
        for camel, snake in (
            ("authorName", "author_name"),
            ("createdAt", "created_at"),
        ):
            if camel in out and snake not in out:
                out[snake] = out.pop(camel)
        return out


class CommunityPostOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    id: str
    author_name: str
    title: str
    content: str
    images: List[str]
    created_at: datetime
    likes: int
    liked_by_user: bool = False

    @classmethod
    def from_row(
        cls,
        row: CommunityPostRow,
        *,
        liked_by_user: bool = False,
    ) -> "CommunityPostOut":
        imgs: List[str] = []
        try:
            raw = json.loads(row.images_json or "[]")
            if isinstance(raw, list):
                imgs = [str(x) for x in raw]
        except json.JSONDecodeError:
            pass
        return cls(
            id=row.id,
            author_name=row.author_name,
            title=row.title,
            content=row.content,
            images=imgs,
            created_at=row.created_at,
            likes=row.likes,
            liked_by_user=liked_by_user,
        )

