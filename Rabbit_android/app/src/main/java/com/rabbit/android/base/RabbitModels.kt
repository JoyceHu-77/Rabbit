package com.rabbit.android.base

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class RescuePost(
    val id: String,
    val title: String,
    val description: String,
    val images: List<String> = emptyList(),
    val location: String,
    val city: String,
    val district: String,
    val date: String,
    val status: String,
    val finderName: String? = null,
    val finderContact: String? = null,
    val finderIsPublic: Boolean = false,
    val organizerName: String? = null,
    val organizerContact: String? = null,
    val organizerIsPublic: Boolean = false,
    val wechatQR: String? = null,
    val healthStatus: String? = null,
    val sterilizedStatus: String? = null,
    val sourceRabbitId: Int = 0,
    val publisherName: String? = null,
    val moderationStatus: String = ModerationStatus.Approved.value,
    val auditRejectionReason: String? = null,
) {
    fun isListedFor(viewerName: String, isAdmin: Boolean): Boolean {
        return moderationStatus == ModerationStatus.Approved.value ||
            isAdmin ||
            publisherName == viewerName
    }
}

@Serializable
data class DonationPost(
    val id: String,
    val title: String,
    val description: String,
    val image: String = "",
    val type: String,
    val target: String,
    val contactName: String,
    val contactPhone: String,
    val status: String = "进行中",
    val date: String,
    val publisherName: String? = null,
)

@Serializable
data class CommunityPost(
    val id: String,
    val author: String,
    val content: String,
    val likes: Int = 0,
    val likedByMe: Boolean = false,
    val date: String,
)

@Serializable
data class OfflineEvent(
    val id: String,
    val title: String,
    val date: String,
    val location: String,
    val description: String,
    val upcoming: Boolean,
)

@Serializable
data class CharityProduct(
    val id: String,
    val title: String,
    val description: String,
    val price: Int,
    val coins: Int,
)

@Serializable
data class RabbitOrder(
    val id: String,
    val title: String,
    val amount: Int,
    val status: String,
    val date: String,
)

@Serializable
data class InboxMessage(
    val id: String,
    val title: String,
    val body: String,
    val date: String,
    val unread: Boolean = true,
    val adminOnly: Boolean = false,
)

@Serializable
data class ProfileSnapshot(
    val userName: String,
    val userBio: String,
    val badges: Int,
    val cloudCoins: Int,
    val isAdmin: Boolean,
    val isLoggedIn: Boolean,
    val shippingAddress: String = "",
    val localUserId: String? = null,
)

enum class ModerationStatus(val value: String, val label: String) {
    Pending("pending", "待审核"),
    Approved("approved", "已通过"),
    Rejected("rejected", "已驳回");
}

enum class MainTab(val label: String) {
    Rescue("爱兔救援"),
    Adoption("爱兔领养"),
    Donation("物资捐换"),
    Activity("爱兔活动"),
    Profile("个人页"),
}

data class LocalAuthAccount(
    val id: String,
    val displayName: String,
    val bio: String,
    val badges: Int,
    val cloudCoins: Int,
    val isAdmin: Boolean,
)

object LocalAuthCatalog {
    val admin = LocalAuthAccount(
        id = "1",
        displayName = "爱兔管理员",
        bio = "负责审核救援信息与维护爱兔会演示数据",
        badges = 12,
        cloudCoins = 188,
        isAdmin = true,
    )
    val member = LocalAuthAccount(
        id = "2",
        displayName = "爱心用户",
        bio = "热爱兔兔，致力于救助流浪动物",
        badges = 3,
        cloudCoins = 15,
        isAdmin = false,
    )

    fun accountFor(id: String): LocalAuthAccount? = when (id.trim()) {
        admin.id -> admin
        member.id -> member
        else -> null
    }
}

@Serializable
data class RescueCreateBody(
    val id: String,
    val title: String,
    val description: String,
    val images: List<String>,
    val location: String,
    val city: String,
    val district: String,
    val date: String,
    val status: String,
    @SerialName("finder_name") val finderName: String?,
    @SerialName("finder_contact") val finderContact: String?,
    @SerialName("finder_is_public") val finderIsPublic: Boolean,
    @SerialName("organizer_name") val organizerName: String?,
    @SerialName("organizer_contact") val organizerContact: String?,
    @SerialName("organizer_is_public") val organizerIsPublic: Boolean,
    @SerialName("wechat_qr") val wechatQR: String?,
    @SerialName("health_status") val healthStatus: String?,
    @SerialName("sterilized_status") val sterilizedStatus: String?,
    @SerialName("source_rabbit_id") val sourceRabbitId: Int,
    @SerialName("publisher_name") val publisherName: String?,
    @SerialName("moderation_status") val moderationStatus: String,
    @SerialName("audit_rejection_reason") val auditRejectionReason: String?,
)

@Serializable
data class DonationCreateBody(
    val title: String,
    val description: String,
    val image: String,
    val type: String,
    val target: String,
    @SerialName("contact_name") val contactName: String,
    @SerialName("contact_phone") val contactPhone: String,
    @SerialName("publisher_name") val publisherName: String?,
)
