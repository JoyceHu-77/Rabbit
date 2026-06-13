package com.rabbit.android.common

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.rabbit.android.base.CharityProduct
import com.rabbit.android.base.CommunityPost
import com.rabbit.android.base.DonationPost
import com.rabbit.android.base.InboxMessage
import com.rabbit.android.base.LocalAuthCatalog
import com.rabbit.android.base.MainTab
import com.rabbit.android.base.MockData
import com.rabbit.android.base.ModerationStatus
import com.rabbit.android.base.OfflineEvent
import com.rabbit.android.base.ProfileSnapshot
import com.rabbit.android.base.RabbitOrder
import com.rabbit.android.base.RabbitRepository
import com.rabbit.android.base.RescuePost
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class AppUiState(
    val isLoading: Boolean = true,
    val selectedTab: MainTab = MainTab.Rescue,
    val profile: ProfileSnapshot = ProfileSnapshot(
        userName = "爱心用户",
        userBio = "热爱兔兔，致力于救助流浪动物",
        badges = 3,
        cloudCoins = 15,
        isAdmin = false,
        isLoggedIn = false,
    ),
    val rescues: List<RescuePost> = emptyList(),
    val donations: List<DonationPost> = emptyList(),
    val community: List<CommunityPost> = emptyList(),
    val offlineEvents: List<OfflineEvent> = MockData.offlineEvents,
    val products: List<CharityProduct> = MockData.products,
    val orders: List<RabbitOrder> = emptyList(),
    val inbox: List<InboxMessage> = emptyList(),
    val rescueSearch: String = "",
    val rescueStatusFilter: String = "全部",
    val rescueMineOnly: Boolean = false,
    val toast: String? = null,
) {
    val visibleRescues: List<RescuePost>
        get() = rescues
            .filter { it.isListedFor(profile.userName, profile.isAdmin) }
            .filter { rescueSearch.isBlank() || it.title.contains(rescueSearch, true) || it.location.contains(rescueSearch, true) }
            .filter { rescueStatusFilter == "全部" || it.status == rescueStatusFilter }
            .filter { !rescueMineOnly || it.publisherName == profile.userName }

    val unreadInboxCount: Int
        get() = inbox.count { it.unread && (!it.adminOnly || profile.isAdmin) }
}

class AppStateViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = RabbitRepository(application.applicationContext)
    private val _uiState = MutableStateFlow(AppUiState())
    val uiState: StateFlow<AppUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            val profile = repository.loadProfile()
            _uiState.update { it.copy(profile = profile) }
            refreshAll()
        }
    }

    fun login(userId: String) {
        val account = LocalAuthCatalog.accountFor(userId)
        if (account == null) {
            showToast("无效的用户 ID，请使用 1（管理员）或 2（普通用户）")
            return
        }
        val profile = ProfileSnapshot(
            userName = account.displayName,
            userBio = account.bio,
            badges = account.badges,
            cloudCoins = account.cloudCoins,
            isAdmin = account.isAdmin,
            isLoggedIn = true,
            localUserId = account.id,
        )
        viewModelScope.launch {
            repository.saveProfile(profile)
            _uiState.update { it.copy(profile = profile) }
            refreshAll()
            showToast("欢迎回来，${account.displayName}")
        }
    }

    fun logout() {
        viewModelScope.launch {
            val profile = _uiState.value.profile.copy(
                isLoggedIn = false,
                isAdmin = false,
                localUserId = null,
            )
            repository.saveProfile(profile)
            _uiState.update { it.copy(profile = profile, selectedTab = MainTab.Rescue) }
        }
    }

    fun selectTab(tab: MainTab) {
        _uiState.update { it.copy(selectedTab = tab) }
    }

    fun updateRescueSearch(value: String) {
        _uiState.update { it.copy(rescueSearch = value) }
    }

    fun updateRescueStatusFilter(value: String) {
        _uiState.update { it.copy(rescueStatusFilter = value) }
    }

    fun setMineOnly(value: Boolean) {
        _uiState.update { it.copy(rescueMineOnly = value) }
    }

    fun openMyRescuePosts() {
        _uiState.update {
            it.copy(
                selectedTab = MainTab.Rescue,
                rescueMineOnly = true,
                rescueStatusFilter = "全部",
                rescueSearch = "",
            )
        }
    }

    fun refreshAll() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val viewerName = _uiState.value.profile.userName
            val rescues = repository.loadRescues(viewerName)
            val donations = repository.loadDonations(viewerName)
            val community = repository.loadCommunity()
            val orders = repository.loadOrders()
            val inbox = repository.loadInbox()
            _uiState.update {
                it.copy(
                    isLoading = false,
                    rescues = rescues,
                    donations = donations,
                    community = community,
                    orders = orders,
                    inbox = inbox,
                )
            }
        }
    }

    fun createRescue(title: String, description: String, location: String, contact: String) {
        val state = _uiState.value
        val post = RescuePost(
            id = repository.newId("rescue"),
            title = title.ifBlank { "新的救援线索" },
            description = description.ifBlank { "请补充救援情况。" },
            images = emptyList(),
            location = location.ifBlank { "待补充位置" },
            city = "杭州",
            district = "待确认",
            date = repository.today(),
            status = "待救援",
            finderName = state.profile.userName,
            finderContact = contact,
            finderIsPublic = false,
            healthStatus = "待检查",
            sterilizedStatus = "未知",
            publisherName = state.profile.userName,
            moderationStatus = ModerationStatus.Pending.value,
        )
        viewModelScope.launch {
            val saved = repository.createRescue(post, state.profile.userName)
            val list = listOf(saved) + _uiState.value.rescues
            repository.saveRescues(list)
            addInbox("救援帖已提交", "你的救援线索已进入审核队列。")
            _uiState.update { it.copy(rescues = list) }
            showToast("已提交，等待管理员审核")
        }
    }

    fun moderateRescue(post: RescuePost, approved: Boolean) {
        val updated = post.copy(
            moderationStatus = if (approved) ModerationStatus.Approved.value else ModerationStatus.Rejected.value,
            auditRejectionReason = if (approved) null else "信息不完整，请补充定位与联系方式",
        )
        updateRescue(updated, if (approved) "已通过审核" else "已驳回")
    }

    fun updateRescueStatus(post: RescuePost, status: String) {
        updateRescue(post.copy(status = status), "救援状态已更新")
    }

    private fun updateRescue(post: RescuePost, message: String) {
        viewModelScope.launch {
            val saved = repository.updateRescue(post, _uiState.value.profile.userName)
            val list = _uiState.value.rescues.map { if (it.id == saved.id) saved else it }
            repository.saveRescues(list)
            _uiState.update { it.copy(rescues = list) }
            showToast(message)
        }
    }

    fun createDonation(title: String, description: String, type: String, target: String, phone: String) {
        val state = _uiState.value
        val post = DonationPost(
            id = repository.newId("donation"),
            title = title.ifBlank { "新的捐换信息" },
            description = description.ifBlank { "请补充物资说明。" },
            type = type,
            target = target.ifBlank { "同城" },
            contactName = state.profile.userName,
            contactPhone = phone.ifBlank { "站内信联系" },
            date = repository.today(),
            publisherName = state.profile.userName,
        )
        viewModelScope.launch {
            val saved = repository.createDonation(post, state.profile.userName)
            val list = listOf(saved) + _uiState.value.donations
            repository.saveDonations(list)
            addInbox("捐换信息已发布", "你的物资捐换信息已展示在列表中。")
            _uiState.update { it.copy(donations = list) }
            showToast("捐换信息已发布")
        }
    }

    fun submitAdoptionIntent(rabbitTitle: String) {
        addInbox("领养意向已提交", "我们已收到你对“$rabbitTitle”的领养意向，会尽快联系你。")
        showToast("领养意向已提交")
    }

    fun addCommunityPost(content: String) {
        if (content.isBlank()) return
        viewModelScope.launch {
            val post = CommunityPost(
                id = repository.newId("community"),
                author = _uiState.value.profile.userName,
                content = content,
                likes = 0,
                date = repository.today(),
            )
            val list = listOf(post) + _uiState.value.community
            repository.saveCommunity(list)
            _uiState.update { it.copy(community = list) }
        }
    }

    fun toggleLike(post: CommunityPost) {
        viewModelScope.launch {
            val list = _uiState.value.community.map {
                if (it.id == post.id) {
                    it.copy(
                        likedByMe = !it.likedByMe,
                        likes = (it.likes + if (it.likedByMe) -1 else 1).coerceAtLeast(0),
                    )
                } else {
                    it
                }
            }
            repository.saveCommunity(list)
            _uiState.update { it.copy(community = list) }
        }
    }

    fun deleteCommunityPost(post: CommunityPost) {
        if (!_uiState.value.profile.isAdmin) return
        viewModelScope.launch {
            val list = _uiState.value.community.filterNot { it.id == post.id }
            repository.saveCommunity(list)
            _uiState.update { it.copy(community = list) }
            showToast("社区帖已删除")
        }
    }

    fun addOfflineEvent(title: String, location: String) {
        if (!_uiState.value.profile.isAdmin) return
        val event = OfflineEvent(
            id = repository.newId("event"),
            title = title.ifBlank { "新的线下活动" },
            date = repository.today(),
            location = location.ifBlank { "待确认地点" },
            description = "管理员新增的线下活动，详情待补充。",
            upcoming = true,
        )
        _uiState.update { it.copy(offlineEvents = listOf(event) + it.offlineEvents) }
        showToast("线下活动已新增")
    }

    fun confirmCloudAdoption() {
        updateProfile(_uiState.value.profile.copy(cloudCoins = _uiState.value.profile.cloudCoins + 5))
        addInbox("云养成功", "感谢你支持寄养兔兔，本次获得 5 云养币。")
        showToast("云养确认成功，+5 云养币")
    }

    fun placeOrder(product: CharityProduct) {
        viewModelScope.launch {
            val order = RabbitOrder(
                id = repository.newId("order"),
                title = product.title,
                amount = product.price,
                status = "已支付",
                date = repository.today(),
            )
            val orders = listOf(order) + _uiState.value.orders
            repository.saveOrders(orders)
            updateProfile(_uiState.value.profile.copy(cloudCoins = _uiState.value.profile.cloudCoins + product.coins))
            _uiState.update { it.copy(orders = orders) }
            addInbox("订单支付成功", "你购买了“${product.title}”，获得 ${product.coins} 云养币。")
            showToast("支付成功，+${product.coins} 云养币")
        }
    }

    fun saveAddress(address: String) {
        updateProfile(_uiState.value.profile.copy(shippingAddress = address))
        showToast("收货地址已保存")
    }

    fun saveProfile(name: String, bio: String) {
        updateProfile(_uiState.value.profile.copy(userName = name.ifBlank { "爱心用户" }, userBio = bio))
        showToast("资料已更新")
    }

    fun clearToast() {
        _uiState.update { it.copy(toast = null) }
    }

    private fun updateProfile(profile: ProfileSnapshot) {
        viewModelScope.launch {
            repository.saveProfile(profile)
            _uiState.update { it.copy(profile = profile) }
        }
    }

    private fun addInbox(title: String, body: String) {
        viewModelScope.launch {
            val message = InboxMessage(
                id = repository.newId("message"),
                title = title,
                body = body,
                date = repository.today(),
                unread = true,
            )
            val list = listOf(message) + _uiState.value.inbox
            repository.saveInbox(list)
            _uiState.update { it.copy(inbox = list) }
        }
    }

    private fun showToast(message: String) {
        _uiState.update { it.copy(toast = message) }
    }
}
