"""活动 Tab 默认横幅与线下活动（与 iOS 演示数据对齐）。"""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import ActivityBanner, OfflineEvent


def count_banners(db: Session) -> int:
    return int(db.scalar(select(func.count(ActivityBanner.id))) or 0)


def count_offline_events(db: Session) -> int:
    return int(db.scalar(select(func.count(OfflineEvent.id))) or 0)


def seed_default_banners(db: Session) -> int:
    if count_banners(db) > 0:
        return 0
    rows = [
        ActivityBanner(
            id="checkin",
            title="只取心滴",
            subtitle="日行一善公益打卡活动",
            image_url="https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600",
            sort_order=0,
            target_key="checkin",
        ),
        ActivityBanner(
            id="cloud",
            title="爱心云养计划",
            subtitle="公益云养小兔活动",
            image_url="https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600",
            sort_order=1,
            target_key="cloud",
        ),
    ]
    for r in rows:
        db.merge(r)
    db.commit()
    return len(rows)


def seed_default_offline_events(db: Session) -> int:
    if count_offline_events(db) > 0:
        return 0
    rows = [
        OfflineEvent(
            id="OE_SEED_PAST_1",
            title="春日兔友百人聚 - 上海首场",
            date="2026-04-05",
            location="市中心 6600㎡ 超大场馆",
            image_url="https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600",
            banner_url="https://images.unsplash.com/photo-1650199321281-978455fbff64?w=600",
            description="超过 150 位兔友齐聚一堂，分享养兔经验，交流爱心故事。",
            is_past=True,
        ),
        OfflineEvent(
            id="OE_SEED_UP_1",
            title="春日兔友百人聚",
            date="2026-04-29",
            location="市中心 6600㎡ 超大场馆 | 品牌商家赞助",
            image_url="https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600",
            banner_url="https://images.unsplash.com/photo-1765401237810-e403bf6b888d?w=600",
            description="丰富礼品、专业服务与知识分享，欢迎所有爱兔人士参加。",
            is_past=False,
        ),
        OfflineEvent(
            id="OE_SEED_UP_2",
            title="爱兔会公益活动",
            date="2026-05-15",
            location="上海市区待定",
            image_url="https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600",
            banner_url="https://images.unsplash.com/photo-1649750291679-1ee88c324527?w=600",
            description="流浪兔救助知识、科学养兔交流、领养咨询与爱心义卖。",
            is_past=False,
        ),
    ]
    for r in rows:
        db.merge(r)
    db.commit()
    return len(rows)
