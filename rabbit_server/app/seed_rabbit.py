"""将 iOS 同款 rabbit_seed.json 转为与客户端一致的救援记录。"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from sqlalchemy.orm import Session

from app.models import DonationPost, RescuePost


def _strip_health_lines(desc: str | None) -> str:
    if not desc:
        return ""
    clean = desc
    for pattern in [r"健康状况：[^；]+；?", r"绝育状态：[^；]+；?"]:
        clean = re.sub(pattern, "", clean)
    clean = re.sub(r"；\s*$", "", clean)
    return clean.strip()


def _extract(desc: str | None, label: str) -> str | None:
    if not desc:
        return None
    pat = label + r"：([^；]+)"
    m = re.search(pat, desc)
    return m.group(1).strip() if m else None


def rabbit_dict_to_rescue_row(r: dict[str, Any]) -> dict[str, Any]:
    rid = int(r["id"])
    post_id = f"R{rid:03d}"
    location = r.get("location") or ""
    parts = location.split("-")
    city = parts[0] if parts else location
    district = parts[1] if len(parts) > 1 else ""

    name = (r.get("name") or "").strip()
    age = (r.get("age") or "").strip()
    title = f"{name} - {age}" if name else (age or "兔兔")

    raw_desc = r.get("description")
    health = _extract(raw_desc, "健康状况")
    steril = _extract(raw_desc, "绝育状态")
    description = _strip_health_lines(raw_desc)

    finder = r.get("finder") or {}
    org = r.get("organizer") or {}

    return {
        "id": post_id,
        "title": title,
        "description": description,
        "images_json": json.dumps([r.get("photo") or ""]),
        "location": location,
        "city": city,
        "district": district,
        "date": r.get("registrationDate") or "未知",
        "status": r.get("status") or "未知",
        "finder_name": finder.get("name"),
        "finder_contact": finder.get("contact"),
        "finder_is_public": bool(finder.get("isPublic", False)),
        "organizer_name": org.get("name"),
        "organizer_contact": org.get("contact"),
        "organizer_is_public": bool(org.get("isPublic", False)),
        "wechat_qr": r.get("wechatQRCode"),
        "health_status": health,
        "sterilized_status": steril,
        "source_rabbit_id": rid,
        "publisher_name": None,
        "moderation_status": "approved",
        "audit_rejection_reason": None,
    }


def seed_rescues_from_json(db: Session, path: Path) -> int:
    if not path.is_file():
        return 0
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        return 0
    n = 0
    for item in raw:
        if not isinstance(item, dict):
            continue
        row = rabbit_dict_to_rescue_row(item)
        db.merge(RescuePost(**row))
        n += 1
    db.commit()
    return n


def seed_default_donations(db: Session) -> int:
    rows = [
        DonationPost(
            id="D001",
            title="兔粮500g × 3包",
            description="多买了几包兔粮，家里兔兔吃不完，希望能帮助到需要的兔兔",
            image="https://images.unsplash.com/photo-1578164252938-1da0cd4caa30?w=400",
            donation_type="捐赠",
            target="共享",
            status="待领取",
            contact_name="李女士",
            contact_phone="138****1234",
            date="2026-04-10",
        ),
        DonationPost(
            id="D002",
            title="兔笼 + 饮水器",
            description="九成新兔笼，配饮水器和食盆，可置换其他用品或捐赠",
            image="https://images.unsplash.com/photo-1695826809879-6bc04b19e56d?w=400",
            donation_type="置换",
            target="共享",
            status="待领取",
            contact_name="王先生",
            contact_phone="139****5678",
            date="2026-04-09",
        ),
        DonationPost(
            id="D003",
            title="干草 2kg",
            description="指定捐赠给爱兔会，用于救助兔兔",
            image="https://images.unsplash.com/photo-1695826809742-b3e2e7483efd?w=400",
            donation_type="捐赠",
            target="爱兔会",
            status="已完成",
            contact_name="张女士",
            contact_phone="136****9012",
            date="2026-04-08",
        ),
        DonationPost(
            id="D004",
            title="兔兔玩具套装",
            description="咬咬球、草编玩具等，家里兔兔不喜欢，可以置换其他玩具",
            image="https://images.unsplash.com/photo-1564326140-fa771b2c0c5d?w=400",
            donation_type="置换",
            target="共享",
            status="待领取",
            contact_name="陈女士",
            contact_phone="137****3456",
            date="2026-04-07",
        ),
    ]
    for r in rows:
        db.merge(r)
    db.commit()
    return len(rows)
