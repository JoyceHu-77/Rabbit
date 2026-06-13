package com.rabbit.android.base

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import java.time.LocalDate
import java.util.UUID
import kotlinx.coroutines.flow.first
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

private val Context.rabbitDataStore by preferencesDataStore(name = "rabbit_android")

class RabbitRepository(private val context: Context) {
    private val api = RabbitApiFactory.create()
    private val json = Json { ignoreUnknownKeys = true }

    private object Keys {
        val isLoggedIn = booleanPreferencesKey("is_logged_in")
        val isAdmin = booleanPreferencesKey("is_admin")
        val localUserId = stringPreferencesKey("local_user_id")
        val userName = stringPreferencesKey("user_name")
        val userBio = stringPreferencesKey("user_bio")
        val badges = intPreferencesKey("badges")
        val cloudCoins = intPreferencesKey("cloud_coins")
        val shippingAddress = stringPreferencesKey("shipping_address")
        val rescues = stringPreferencesKey("rescues")
        val donations = stringPreferencesKey("donations")
        val community = stringPreferencesKey("community")
        val orders = stringPreferencesKey("orders")
        val inbox = stringPreferencesKey("inbox")
    }

    suspend fun loadProfile(): ProfileSnapshot {
        val prefs = context.rabbitDataStore.data.first()
        return ProfileSnapshot(
            userName = prefs[Keys.userName] ?: "爱心用户",
            userBio = prefs[Keys.userBio] ?: "热爱兔兔，致力于救助流浪动物",
            badges = prefs[Keys.badges] ?: 3,
            cloudCoins = prefs[Keys.cloudCoins] ?: 15,
            isAdmin = prefs[Keys.isAdmin] ?: false,
            isLoggedIn = prefs[Keys.isLoggedIn] ?: false,
            shippingAddress = prefs[Keys.shippingAddress] ?: "",
            localUserId = prefs[Keys.localUserId],
        )
    }

    suspend fun saveProfile(profile: ProfileSnapshot) {
        context.rabbitDataStore.edit { prefs ->
            prefs[Keys.isLoggedIn] = profile.isLoggedIn
            prefs[Keys.isAdmin] = profile.isAdmin
            prefs[Keys.userName] = profile.userName
            prefs[Keys.userBio] = profile.userBio
            prefs[Keys.badges] = profile.badges
            prefs[Keys.cloudCoins] = profile.cloudCoins
            prefs[Keys.shippingAddress] = profile.shippingAddress
            profile.localUserId?.let { prefs[Keys.localUserId] = it } ?: prefs.remove(Keys.localUserId)
        }
    }

    suspend fun loadRescues(viewerName: String): List<RescuePost> {
        val remote = runCatching {
            api?.fetchRescues(authHeader(viewerName))
        }.getOrNull()
        val posts = remote?.takeIf { it.isNotEmpty() } ?: loadLocal(Keys.rescues, MockData.rescues)
        saveList(Keys.rescues, posts)
        return posts
    }

    suspend fun loadDonations(viewerName: String): List<DonationPost> {
        val remote = runCatching {
            api?.fetchDonations(authHeader(viewerName))
        }.getOrNull()
        val posts = remote?.takeIf { it.isNotEmpty() } ?: loadLocal(Keys.donations, MockData.donations)
        saveList(Keys.donations, posts)
        return posts
    }

    suspend fun loadCommunity(): List<CommunityPost> = loadLocal(Keys.community, MockData.community)

    suspend fun loadOrders(): List<RabbitOrder> = loadLocal(Keys.orders, MockData.orders)

    suspend fun loadInbox(): List<InboxMessage> = loadLocal(Keys.inbox, MockData.inbox)

    suspend fun saveRescues(posts: List<RescuePost>) = saveList(Keys.rescues, posts)

    suspend fun saveDonations(posts: List<DonationPost>) = saveList(Keys.donations, posts)

    suspend fun saveCommunity(posts: List<CommunityPost>) = saveList(Keys.community, posts)

    suspend fun saveOrders(orders: List<RabbitOrder>) = saveList(Keys.orders, orders)

    suspend fun saveInbox(messages: List<InboxMessage>) = saveList(Keys.inbox, messages)

    suspend fun createRescue(post: RescuePost, viewerName: String): RescuePost {
        return runCatching {
            api?.createRescue(authHeader(viewerName), post.toCreateBody())
        }.getOrNull() ?: post
    }

    suspend fun updateRescue(post: RescuePost, viewerName: String): RescuePost {
        return runCatching {
            api?.updateRescue(authHeader(viewerName), post.id, post.toCreateBody())
        }.getOrNull() ?: post
    }

    suspend fun createDonation(post: DonationPost, viewerName: String): DonationPost {
        val body = DonationCreateBody(
            title = post.title,
            description = post.description,
            image = post.image,
            type = post.type,
            target = post.target,
            contactName = post.contactName,
            contactPhone = post.contactPhone,
            publisherName = post.publisherName,
        )
        return runCatching {
            api?.createDonation(authHeader(viewerName), body)
        }.getOrNull() ?: post
    }

    fun newId(prefix: String): String = "$prefix-${UUID.randomUUID().toString().take(8)}"

    fun today(): String = LocalDate.now().toString()

    private fun authHeader(viewerName: String): String = "Bearer $viewerName"

    private suspend inline fun <reified T> loadLocal(
        key: androidx.datastore.preferences.core.Preferences.Key<String>,
        fallback: List<T>,
    ): List<T> {
        val raw = context.rabbitDataStore.data.first()[key]
        return raw?.let { runCatching { json.decodeFromString<List<T>>(it) }.getOrNull() } ?: fallback
    }

    private suspend inline fun <reified T> saveList(
        key: androidx.datastore.preferences.core.Preferences.Key<String>,
        value: List<T>,
    ) {
        context.rabbitDataStore.edit { prefs ->
            prefs[key] = json.encodeToString(value)
        }
    }
}

object MockData {
    val rescues = listOf(
        RescuePost(
            id = "r-001",
            title = "公园草丛发现受伤垂耳兔",
            description = "后腿疑似受伤，已临时安置在纸箱内，需要志愿者接力送医。",
            images = listOf("https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308"),
            location = "人民公园东门",
            city = "杭州",
            district = "西湖区",
            date = "2026-06-12",
            status = "待救援",
            finderName = "小林",
            finderContact = "13800000001",
            finderIsPublic = false,
            healthStatus = "疑似骨折",
            sterilizedStatus = "未知",
            publisherName = "爱心用户",
            moderationStatus = ModerationStatus.Approved.value,
        ),
        RescuePost(
            id = "r-002",
            title = "小区地下车库白兔求助",
            description = "精神状态尚可，物业允许志愿者进入，需带笼具。",
            images = listOf("https://images.unsplash.com/photo-1591561582301-7ce6588cc286"),
            location = "未来社区 3 幢车库",
            city = "上海",
            district = "浦东新区",
            date = "2026-06-10",
            status = "救援中",
            organizerName = "爱兔救援队",
            organizerContact = "service@rabbit.local",
            organizerIsPublic = true,
            healthStatus = "待检查",
            sterilizedStatus = "未绝育",
            publisherName = "爱兔管理员",
            moderationStatus = ModerationStatus.Approved.value,
        ),
        RescuePost(
            id = "r-003",
            title = "待审核：校园门口发现幼兔",
            description = "学生提交的线索，等待管理员确认。",
            images = emptyList(),
            location = "大学城南门",
            city = "杭州",
            district = "余杭区",
            date = "2026-06-13",
            status = "待救援",
            finderName = "匿名同学",
            finderContact = "13900000002",
            publisherName = "爱心用户",
            moderationStatus = ModerationStatus.Pending.value,
        ),
    )

    val donations = listOf(
        DonationPost(
            id = "d-001",
            title = "九成新兔笼可捐",
            description = "60cm 基础兔笼，适合作为短期隔离笼。",
            image = "https://images.unsplash.com/photo-1556838803-cc94986cb631",
            type = "捐赠",
            target = "杭州自提",
            contactName = "阿远",
            contactPhone = "13600000001",
            status = "可领取",
            date = "2026-06-09",
            publisherName = "爱心用户",
        ),
        DonationPost(
            id = "d-002",
            title = "求购提摩西草",
            description = "救助站临时缺草，希望同城低价转让。",
            image = "",
            type = "求助",
            target = "上海",
            contactName = "救助站",
            contactPhone = "service@rabbit.local",
            status = "进行中",
            date = "2026-06-08",
            publisherName = "爱兔管理员",
        ),
    )

    val community = listOf(
        CommunityPost("c-001", "云养家长", "今天被领养的小白开始主动吃草啦。", 18, false, "2026-06-11"),
        CommunityPost("c-002", "爱心用户", "分享一个清洗饮水器的小技巧。", 9, true, "2026-06-10"),
    )

    val offlineEvents = listOf(
        OfflineEvent("e-001", "周末救助站开放日", "2026-06-21", "杭州爱兔基地", "参观寄养区并学习基础护理。", true),
        OfflineEvent("e-002", "春季义卖回顾", "2026-04-12", "上海公益市集", "义卖收益已用于 6 只兔兔体检。", false),
    )

    val products = listOf(
        CharityProduct("p-001", "兔兔护理公益包", "基础清洁用品，收益进入救助基金。", 39, 8),
        CharityProduct("p-002", "云养月卡", "支持一只寄养兔 30 天口粮。", 99, 30),
        CharityProduct("p-003", "爱兔会帆布袋", "公益周边，适合日常通勤。", 49, 10),
    )

    val orders = listOf(
        RabbitOrder("o-001", "云养月卡", 99, "已支付", "2026-06-01"),
    )

    val inbox = listOf(
        InboxMessage("m-001", "欢迎来到爱兔会", "你可以浏览救援、提交线索、参与云养和公益活动。", "2026-06-01"),
        InboxMessage("m-002", "管理员通知", "有新的救援帖等待审核。", "2026-06-13", adminOnly = true),
    )
}
