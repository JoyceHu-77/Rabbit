from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app import crud, crud_activity, crud_adoption, crud_profile
from app.config import settings
from app.database import Base, SessionLocal, engine, get_db
from app.db_migrate import apply_sqlite_migrations
from app.schemas import DonationCreate, DonationOut, RescueCreate, RescueOut
from app.schemas_adoption import (
    AdoptionIntentCreate,
    AdoptionIntentOut,
    AdoptionIntentStatusPatch,
    CommunityPostCreate,
    CommunityPostOut,
)
from app.schemas_activity import (
    ActivityBannerOut,
    CloudAdoptConfirm,
    CloudAdoptConfirmOut,
    OfflineEventCreate,
    OfflineEventOut,
    OfflineEventPatch,
)
from app.schemas_profile import (
    AdminNotificationOut,
    InboxMessageOut,
    OrderOut,
    OrderPayOut,
    ProfileOut,
    ProfilePatch,
    WalletAdjust,
)
from app.seed_activity import seed_default_banners, seed_default_offline_events
from app.seed_rabbit import seed_default_donations, seed_rescues_from_json


def _resolve_seed_json_path():
    import os

    env = os.getenv("SEED_JSON_PATH", "").strip()
    if env:
        p = Path(env)
        return p if p.is_file() else None
    here = Path(__file__).resolve()
    for c in (
        here.parent.parent / "data" / "rabbit_seed.json",
        here.parent.parent / "seed" / "rabbit_seed.json",
        here.parents[2] / "Rabbit_iOS" / "Rabbit_iOS" / "rabbit_seed.json",
    ):
        if c.is_file():
            return c
    return None


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    apply_sqlite_migrations(engine)
    with SessionLocal() as db:
        seed_default_banners(db)
        seed_default_offline_events(db)
    if settings.run_seed_on_empty:
        with SessionLocal() as db:
            if crud.count_rescues(db) == 0:
                seed_path = _resolve_seed_json_path()
                if seed_path:
                    seed_rescues_from_json(db, seed_path)
            if crud.count_donations(db) == 0:
                seed_default_donations(db)
    yield


app = FastAPI(title="Rabbit API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/healthz")
def healthz() -> Dict[str, str]:
    return {"status": "ok"}


def _viewer_from_auth(authorization: Optional[str]) -> Optional[str]:
    if not authorization:
        return None
    if authorization.lower().startswith("bearer "):
        return authorization[7:].strip() or None
    return None


def _viewer_key(authorization: Optional[str]) -> str:
    return _viewer_from_auth(authorization) or "anonymous"


# --- 活动 Tab：横幅、线下活动、橱窗商品（派生）、云养确认 ---


@app.get("/v1/activity/banners", tags=["activity"])
def get_activity_banners(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    rows = crud_activity.list_banners(db)
    return [ActivityBannerOut.from_row(r).model_dump(mode="json") for r in rows]


@app.get("/v1/activity/offline-events", tags=["activity"])
def get_offline_events(
    db: Session = Depends(get_db),
    is_past: Optional[bool] = None,
    page: int = Query(1, ge=1),
    per_page: Optional[int] = Query(None, ge=1),
    envelope: bool = False,
) -> Union[List[Dict[str, Any]], Dict[str, Any]]:
    rows, total, has_more = crud_activity.list_offline_events(
        db, is_past=is_past, page=page, per_page=per_page
    )
    data = [OfflineEventOut.from_row(r).model_dump(mode="json") for r in rows]
    if envelope:
        return {
            "data": data,
            "meta": {"total": total, "page": page, "per_page": per_page, "has_more": has_more},
        }
    return data


@app.post("/v1/activity/offline-events", status_code=201, tags=["activity"])
def post_offline_event(
    body: OfflineEventCreate,
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    row = crud_activity.create_offline_event(db, body)
    return OfflineEventOut.from_row(row).model_dump(mode="json")


@app.patch("/v1/activity/offline-events/{event_id}", tags=["activity"])
def patch_offline_event_route(
    event_id: str,
    body: OfflineEventPatch,
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    row = crud_activity.patch_offline_event(db, event_id, body)
    if row is None:
        raise HTTPException(status_code=404, detail="event_not_found")
    return OfflineEventOut.from_row(row).model_dump(mode="json")


@app.delete("/v1/activity/offline-events/{event_id}", status_code=204, tags=["activity"])
def delete_offline_event_route(event_id: str, db: Session = Depends(get_db)) -> Response:
    if not crud_activity.delete_offline_event(db, event_id):
        raise HTTPException(status_code=404, detail="event_not_found")
    return Response(status_code=204)


@app.get("/v1/activity/charity/products", tags=["activity"])
def get_charity_products(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    items = crud_activity.list_charity_products(db)
    return [p.model_dump(mode="json") for p in items]


@app.post("/v1/activity/cloud-adopt/confirm", tags=["activity"])
def post_cloud_adopt_confirm(
    body: CloudAdoptConfirm,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, Any]:
    row = crud_activity.validate_rescue_for_cloud(db, body.rescue_id)
    if row is None:
        raise HTTPException(
            status_code=404,
            detail="rescue_not_found_or_not_eligible",
        )
    coins = max(1, body.amount_yuan // 10)
    vk = _viewer_key(authorization)
    profile_row = crud_profile.adjust_wallet(
        db, vk, badges_delta=1, cloud_coins_delta=coins
    )
    rabbit_name = (row.title or "").split(" - ", 1)[0].strip() or body.rescue_id
    if vk != "anonymous":
        crud_profile.create_inbox_message(
            db,
            vk,
            title="云养成功",
            body=f"您已为 {rabbit_name} 完成云养（¥{body.amount_yuan}），{coins} 云养币已到账。",
        )
    crud_profile.create_admin_notification(
        db,
        type="cloudAdopt",
        title="云养支付待核对",
        content=f"用户 {vk} 云养 {body.rescue_id}（{rabbit_name}）¥{body.amount_yuan}，已发放 {coins} 云养币。",
    )
    prof = ProfileOut.from_row(profile_row)
    out = CloudAdoptConfirmOut(
        rescue_id=body.rescue_id,
        amount_yuan=body.amount_yuan,
        cloud_coins_granted=coins,
        badges_granted=1,
        profile=prof.model_dump(mode="json"),
    )
    return out.model_dump(mode="json")


# --- 领养 Tab：意向与爱兔社区（救援兔兔列表仍用 GET /v1/rescues） ---


@app.post("/v1/adoption/intents", status_code=201, tags=["adoption"])
def create_adoption_intent(
    body: AdoptionIntentCreate,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, Any]:
    vk = _viewer_key(authorization)
    try:
        row = crud_adoption.create_adoption_intent(db, body, viewer_key=vk)
    except ValueError as e:
        if str(e) == "rescue_not_found":
            raise HTTPException(status_code=404, detail="rescue_not_found")
        raise
    return AdoptionIntentOut.from_row(row).model_dump(mode="json")


@app.get("/v1/adoption/intents", tags=["adoption"])
def list_adoption_intents(
    db: Session = Depends(get_db),
    rescue_id: Optional[str] = None,
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: Optional[int] = Query(None, ge=1),
    envelope: bool = False,
) -> Union[List[Dict[str, Any]], Dict[str, Any]]:
    rows, total, has_more = crud_adoption.list_adoption_intents(
        db,
        rescue_id=rescue_id,
        status=status,
        page=page,
        per_page=per_page,
    )
    data = [AdoptionIntentOut.from_row(r).model_dump(mode="json") for r in rows]
    if envelope:
        return {
            "data": data,
            "meta": {"total": total, "page": page, "per_page": per_page, "has_more": has_more},
        }
    return data


@app.patch("/v1/adoption/intents/{intent_id}", tags=["adoption"])
def patch_adoption_intent(
    intent_id: str,
    body: AdoptionIntentStatusPatch,
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    row = crud_adoption.patch_adoption_intent_status(db, intent_id, body.status)
    if row is None:
        raise HTTPException(status_code=404, detail="intent_not_found")
    return AdoptionIntentOut.from_row(row).model_dump(mode="json")


@app.get("/v1/adoption/community/posts", tags=["adoption"])
def list_community_posts(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
    page: int = Query(1, ge=1),
    per_page: Optional[int] = Query(None, ge=1),
    envelope: bool = False,
) -> Union[List[Dict[str, Any]], Dict[str, Any]]:
    vk = _viewer_key(authorization)
    rows_pairs, total, has_more = crud_adoption.list_community_posts(
        db, page=page, per_page=per_page, viewer_key=vk
    )
    data = [
        CommunityPostOut.from_row(r, liked_by_user=liked).model_dump(mode="json")
        for r, liked in rows_pairs
    ]
    if envelope:
        return {
            "data": data,
            "meta": {"total": total, "page": page, "per_page": per_page, "has_more": has_more},
        }
    return data


@app.post("/v1/adoption/community/posts", status_code=201, tags=["adoption"])
def create_community_post_route(
    body: CommunityPostCreate,
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    row = crud_adoption.create_community_post(db, body)
    return CommunityPostOut.from_row(row, liked_by_user=False).model_dump(mode="json")


@app.delete("/v1/adoption/community/posts/{post_id}", status_code=204, tags=["adoption"])
def delete_community_post_route(post_id: str, db: Session = Depends(get_db)) -> Response:
    if not crud_adoption.delete_community_post(db, post_id):
        raise HTTPException(status_code=404, detail="post_not_found")
    return Response(status_code=204)


@app.post("/v1/adoption/community/posts/{post_id}/like", tags=["adoption"])
def toggle_community_like(
    post_id: str,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, Any]:
    vk = _viewer_key(authorization)
    pair = crud_adoption.toggle_community_like(db, post_id, vk)
    if pair is None:
        raise HTTPException(status_code=404, detail="post_not_found")
    row, liked = pair
    return CommunityPostOut.from_row(row, liked_by_user=liked).model_dump(mode="json")


@app.get("/v1/rescues")
def get_rescues(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
    page: int = Query(1, ge=1),
    per_page: Optional[int] = Query(None, ge=1),
    sort: Optional[str] = None,
    q: Optional[str] = None,
    status: Optional[str] = None,
    district: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    mine: Optional[int] = Query(None, ge=0, le=1),
    publisher_name: Optional[str] = None,
    envelope: bool = False,
) -> Union[List[Dict[str, Any]], Dict[str, Any]]:
    viewer = _viewer_from_auth(authorization)
    params = crud.RescueListParams(
        page=page,
        per_page=per_page,
        sort=sort,
        q=q,
        status=status,
        district=district,
        date_from=date_from,
        date_to=date_to,
        mine=mine,
        publisher_name=publisher_name,
        viewer_name=viewer,
    )
    rows, total, has_more = crud.list_rescues_filtered(db, params)
    data = [RescueOut.from_orm(r).model_dump(mode="json") for r in rows]
    if envelope:
        return {
            "data": data,
            "meta": {
                "total": total,
                "page": page,
                "per_page": per_page,
                "has_more": has_more,
            },
        }
    return data


@app.post("/v1/rescues", status_code=201)
def post_rescue(body: RescueCreate, db: Session = Depends(get_db)) -> Dict[str, Any]:
    row = crud.upsert_rescue(db, body)
    return RescueOut.from_orm(row).model_dump(mode="json")


@app.patch("/v1/rescues/{rescue_id}")
def patch_rescue(
    rescue_id: str,
    body: RescueCreate,
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    fixed = body.model_copy(update={"id": rescue_id})
    row = crud.upsert_rescue(db, fixed)
    return RescueOut.from_orm(row).model_dump(mode="json")


@app.get("/v1/donations")
def get_donations(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: Optional[int] = Query(None, ge=1),
    donation_type: Optional[str] = Query(None, alias="type"),
    target: Optional[str] = None,
    status: Optional[str] = None,
    q: Optional[str] = None,
    envelope: bool = False,
) -> Union[List[Dict[str, Any]], Dict[str, Any]]:
    params = crud.DonationListParams(
        page=page,
        per_page=per_page,
        donation_type=donation_type,
        target=target,
        status=status,
        q=q,
    )
    rows, total, has_more = crud.list_donations_filtered(db, params)
    data = [DonationOut.from_orm(r).model_dump(mode="json") for r in rows]
    if envelope:
        return {
            "data": data,
            "meta": {
                "total": total,
                "page": page,
                "per_page": per_page,
                "has_more": has_more,
            },
        }
    return data


@app.post("/v1/donations", status_code=201)
def post_donation(body: DonationCreate, db: Session = Depends(get_db)) -> Dict[str, Any]:
    row = crud.create_donation(db, body)
    return DonationOut.from_orm(row).model_dump(mode="json")


# --- 个人页：资料、站内信、管理通知、订单 ---


@app.get("/v1/profile/me", tags=["profile"])
def get_profile_me(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, Any]:
    vk = _viewer_key(authorization)
    row = crud_profile.get_or_create_profile(db, vk)
    return ProfileOut.from_row(row).model_dump(mode="json")


@app.patch("/v1/profile/me", tags=["profile"])
def patch_profile_me(
    body: ProfilePatch,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, Any]:
    vk = _viewer_key(authorization)
    row = crud_profile.patch_profile(db, vk, body)
    return ProfileOut.from_row(row).model_dump(mode="json")


@app.post("/v1/profile/wallet/adjust", tags=["profile"])
def post_profile_wallet_adjust(
    body: WalletAdjust,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, Any]:
    vk = _viewer_key(authorization)
    row = crud_profile.adjust_wallet(
        db,
        vk,
        badges_delta=body.badges_delta,
        cloud_coins_delta=body.cloud_coins_delta,
    )
    return ProfileOut.from_row(row).model_dump(mode="json")


@app.get("/v1/profile/inbox", tags=["profile"])
def get_profile_inbox(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> List[Dict[str, Any]]:
    vk = _viewer_key(authorization)
    rows = crud_profile.list_inbox_messages(db, vk)
    return [InboxMessageOut.from_row(r).model_dump(mode="json") for r in rows]


@app.post("/v1/profile/inbox/{message_id}/read", tags=["profile"])
def post_profile_inbox_read(
    message_id: str,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, str]:
    vk = _viewer_key(authorization)
    if not crud_profile.mark_inbox_read(db, vk, message_id):
        raise HTTPException(status_code=404, detail="message_not_found")
    return {"status": "ok"}


@app.get("/v1/profile/admin-notifications", tags=["profile"])
def get_profile_admin_notifications(
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    rows = crud_profile.list_admin_notifications(db)
    return [AdminNotificationOut.from_row(r).model_dump(mode="json") for r in rows]


@app.post("/v1/profile/admin-notifications/{notification_id}/read", tags=["profile"])
def post_profile_admin_notification_read(
    notification_id: str,
    db: Session = Depends(get_db),
) -> Dict[str, str]:
    if not crud_profile.mark_admin_read(db, notification_id):
        raise HTTPException(status_code=404, detail="notification_not_found")
    return {"status": "ok"}


@app.get("/v1/profile/orders", tags=["profile"])
def get_profile_orders(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> List[Dict[str, Any]]:
    vk = _viewer_key(authorization)
    rows = crud_profile.list_orders(db, vk)
    return [OrderOut.from_row(r).model_dump(mode="json") for r in rows]


@app.post("/v1/profile/orders/{order_id}/pay", tags=["profile"])
def post_profile_order_pay(
    order_id: str,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None),
) -> Dict[str, Any]:
    vk = _viewer_key(authorization)
    pair = crud_profile.pay_order(db, vk, order_id)
    if pair is None:
        raise HTTPException(status_code=404, detail="order_not_found")
    order_row, profile_row = pair
    out = OrderPayOut(
        order_id=order_row.id,
        cloud_coins_granted=order_row.cloud_coins_reward,
        profile=ProfileOut.from_row(profile_row),
    )
    return out.model_dump(mode="json")
