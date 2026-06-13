package com.rabbit.android

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Mail
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.VolunteerActivism
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.rabbit.android.base.CharityProduct
import com.rabbit.android.base.CommunityPost
import com.rabbit.android.base.DonationPost
import com.rabbit.android.base.InboxMessage
import com.rabbit.android.base.MainTab
import com.rabbit.android.base.ModerationStatus
import com.rabbit.android.base.OfflineEvent
import com.rabbit.android.base.RabbitOrder
import com.rabbit.android.base.RabbitPink
import com.rabbit.android.base.RabbitRose
import com.rabbit.android.base.RabbitRoseDark
import com.rabbit.android.base.RabbitTheme
import com.rabbit.android.base.RescuePost
import com.rabbit.android.common.AppStateViewModel
import com.rabbit.android.common.AppUiState

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val viewModel: AppStateViewModel = viewModel()
            val state by viewModel.uiState.collectAsStateWithLifecycle()
            RabbitTheme {
                RabbitApp(state = state, viewModel = viewModel)
            }
        }
    }
}

@Composable
private fun RabbitApp(state: AppUiState, viewModel: AppStateViewModel) {
    val context = LocalContext.current
    LaunchedEffect(state.toast) {
        state.toast?.let {
            Toast.makeText(context, it, Toast.LENGTH_SHORT).show()
            viewModel.clearToast()
        }
    }
    Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        if (state.profile.isLoggedIn) {
            MainScaffold(state, viewModel)
        } else {
            LoginScreen(onLogin = viewModel::login)
        }
    }
}

@Composable
private fun LoginScreen(onLogin: (String) -> Unit) {
    var userId by remember { mutableStateOf("2") }
    Box(
        Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(Color(0xFFFFF7F8), Color(0xFFFFE4EA), Color.White),
                ),
            )
            .padding(24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Card(shape = RoundedCornerShape(28.dp), elevation = CardDefaults.cardElevation(8.dp)) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Text("爱兔会", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
                Text("救援、领养、捐换、活动与个人中心的 Android 演示版。")
                OutlinedTextField(
                    value = userId,
                    onValueChange = { userId = it },
                    label = { Text("用户 ID：1 管理员 / 2 普通用户") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Button(onClick = { onLogin(userId) }, modifier = Modifier.fillMaxWidth()) {
                    Text("进入爱兔会")
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = { userId = "1"; onLogin("1") }, modifier = Modifier.weight(1f)) {
                        Text("管理员")
                    }
                    OutlinedButton(onClick = { userId = "2"; onLogin("2") }, modifier = Modifier.weight(1f)) {
                        Text("普通用户")
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainScaffold(state: AppUiState, viewModel: AppStateViewModel) {
    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = { Text(state.selectedTab.label, fontWeight = FontWeight.Bold) },
                actions = {
                    if (state.isLoading) {
                        CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                    } else {
                        IconButton(onClick = viewModel::refreshAll) {
                            Icon(Icons.Default.Refresh, contentDescription = "刷新")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFFFFF7F8)),
            )
        },
        bottomBar = {
            NavigationBar(containerColor = Color.White) {
                MainTab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = state.selectedTab == tab,
                        onClick = { viewModel.selectTab(tab) },
                        icon = {
                            if (tab == MainTab.Profile && state.unreadInboxCount > 0) {
                                BadgedBox(badge = { Badge { Text(state.unreadInboxCount.toString()) } }) {
                                    Icon(tab.icon, contentDescription = tab.label)
                                }
                            } else {
                                Icon(tab.icon, contentDescription = tab.label)
                            }
                        },
                        label = { Text(tab.label) },
                    )
                }
            }
        },
    ) { padding ->
        Box(Modifier.padding(padding)) {
            when (state.selectedTab) {
                MainTab.Rescue -> RescueScreen(state, viewModel)
                MainTab.Adoption -> AdoptionScreen(state, viewModel)
                MainTab.Donation -> DonationScreen(state, viewModel)
                MainTab.Activity -> ActivityScreen(state, viewModel)
                MainTab.Profile -> ProfileScreen(state, viewModel)
            }
        }
    }
}

private val MainTab.icon: ImageVector
    get() = when (this) {
        MainTab.Rescue -> Icons.Default.VolunteerActivism
        MainTab.Adoption -> Icons.Default.Favorite
        MainTab.Donation -> Icons.Default.ShoppingCart
        MainTab.Activity -> Icons.Default.Home
        MainTab.Profile -> Icons.Default.Person
    }

@Composable
private fun RescueScreen(state: AppUiState, viewModel: AppStateViewModel) {
    var showCreate by remember { mutableStateOf(false) }
    var selected by remember { mutableStateOf<RescuePost?>(null) }
    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            contentPadding = PaddingValues(16.dp, 16.dp, 16.dp, 96.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                OutlinedTextField(
                    value = state.rescueSearch,
                    onValueChange = viewModel::updateRescueSearch,
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    label = { Text("搜索标题或地点") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(Modifier.height(8.dp))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(listOf("全部", "待救援", "救援中", "已救助", "寄养中", "已领养")) { status ->
                        FilterChip(
                            selected = state.rescueStatusFilter == status,
                            onClick = { viewModel.updateRescueStatusFilter(status) },
                            label = { Text(status) },
                        )
                    }
                    item {
                        FilterChip(
                            selected = state.rescueMineOnly,
                            onClick = { viewModel.setMineOnly(!state.rescueMineOnly) },
                            label = { Text("我的发布") },
                        )
                    }
                }
            }
            items(state.visibleRescues, key = { it.id }) { post ->
                RescueCard(post = post, isAdmin = state.profile.isAdmin, onClick = { selected = post })
            }
            if (state.visibleRescues.isEmpty()) {
                item { EmptyHint("暂无符合条件的救援帖") }
            }
        }
        ExtendedFloatingActionButton(
            onClick = { showCreate = true },
            icon = { Icon(Icons.Default.Add, contentDescription = null) },
            text = { Text("发布救援") },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(20.dp),
        )
    }
    if (showCreate) {
        RescueCreateDialog(onDismiss = { showCreate = false }) { title, description, location, contact ->
            viewModel.createRescue(title, description, location, contact)
            showCreate = false
        }
    }
    selected?.let { post ->
        RescueDetailDialog(
            post = post,
            isAdmin = state.profile.isAdmin,
            onDismiss = { selected = null },
            onApprove = { viewModel.moderateRescue(post, true); selected = null },
            onReject = { viewModel.moderateRescue(post, false); selected = null },
            onStatus = { status -> viewModel.updateRescueStatus(post, status); selected = null },
        )
    }
}

@Composable
private fun RescueCard(post: RescuePost, isAdmin: Boolean, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(22.dp),
    ) {
        Row(Modifier.padding(12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            RabbitImage(post.images.firstOrNull(), Modifier.size(96.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(post.title, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                    StatusChip(post.moderationStatus)
                }
                Text("${post.city} ${post.district} · ${post.status}", color = MaterialTheme.colorScheme.primary)
                Text(post.description, maxLines = 2, overflow = TextOverflow.Ellipsis)
                if (isAdmin && post.moderationStatus == ModerationStatus.Pending.value) {
                    Text("管理员：待审核", color = RabbitRoseDark, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
private fun RescueDetailDialog(
    post: RescuePost,
    isAdmin: Boolean,
    onDismiss: () -> Unit,
    onApprove: () -> Unit,
    onReject: () -> Unit,
    onStatus: (String) -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(post.title) },
        text = {
            Column(
                Modifier
                    .verticalScroll(rememberScrollState())
                    .imePadding(),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                RabbitImage(post.images.firstOrNull(), Modifier.fillMaxWidth().height(180.dp))
                Text(post.description)
                Text("地点：${post.location}")
                Text("状态：${post.status} · ${post.date}")
                Text("联系人：${post.finderName ?: post.organizerName ?: "待补充"} / ${masked(post.finderContact ?: post.organizerContact)}")
                Text("健康：${post.healthStatus ?: "未知"}，绝育：${post.sterilizedStatus ?: "未知"}")
                if (post.moderationStatus == ModerationStatus.Rejected.value) {
                    Text("驳回原因：${post.auditRejectionReason ?: "未填写"}", color = MaterialTheme.colorScheme.error)
                }
                if (isAdmin) {
                    Text("管理员操作", fontWeight = FontWeight.Bold)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = onApprove, enabled = post.moderationStatus != ModerationStatus.Approved.value) { Text("通过") }
                        OutlinedButton(onClick = onReject) { Text("驳回") }
                    }
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(listOf("待救援", "救援中", "已救助", "寄养中", "已领养")) { status ->
                            AssistChip(onClick = { onStatus(status) }, label = { Text(status) })
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("关闭") } },
    )
}

@Composable
private fun RescueCreateDialog(onDismiss: () -> Unit, onSubmit: (String, String, String, String) -> Unit) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var contact by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("发布救援帖") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(title, { title = it }, label = { Text("标题") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(description, { description = it }, label = { Text("情况描述") }, minLines = 3, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(location, { location = it }, label = { Text("位置") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(contact, { contact = it }, label = { Text("联系方式") }, modifier = Modifier.fillMaxWidth())
                Text("Android 首版用系统弹窗承载表单，新帖默认进入待审核。", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        },
        confirmButton = { Button(onClick = { onSubmit(title, description, location, contact) }) { Text("提交") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("取消") } },
    )
}

@Composable
private fun DonationScreen(state: AppUiState, viewModel: AppStateViewModel) {
    var showCreate by remember { mutableStateOf(false) }
    var selected by remember { mutableStateOf<DonationPost?>(null) }
    Box(Modifier.fillMaxSize()) {
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            contentPadding = PaddingValues(16.dp, 16.dp, 16.dp, 96.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(state.donations, key = { it.id }) { post ->
                DonationCard(post) { selected = post }
            }
        }
        ExtendedFloatingActionButton(
            onClick = { showCreate = true },
            icon = { Icon(Icons.Default.Add, contentDescription = null) },
            text = { Text("发布") },
            modifier = Modifier.align(Alignment.BottomEnd).padding(20.dp),
        )
    }
    selected?.let { post ->
        AlertDialog(
            onDismissRequest = { selected = null },
            title = { Text(post.title) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    RabbitImage(post.image, Modifier.fillMaxWidth().height(160.dp))
                    Text(post.description)
                    Text("${post.type} · ${post.target} · ${post.status}")
                    Text("联系人：${post.contactName} / ${masked(post.contactPhone)}")
                }
            },
            confirmButton = { TextButton(onClick = { selected = null }) { Text("关闭") } },
        )
    }
    if (showCreate) {
        DonationCreateDialog(onDismiss = { showCreate = false }) { title, description, type, target, phone ->
            viewModel.createDonation(title, description, type, target, phone)
            showCreate = false
        }
    }
}

@Composable
private fun DonationCard(post: DonationPost, onClick: () -> Unit) {
    Card(Modifier.clickable(onClick = onClick), shape = RoundedCornerShape(20.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            RabbitImage(post.image, Modifier.fillMaxWidth().aspectRatio(1f))
            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(post.title, fontWeight = FontWeight.Bold, maxLines = 2)
                Text(post.type, color = RabbitRose)
                Text(post.description, maxLines = 2, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

@Composable
private fun DonationCreateDialog(onDismiss: () -> Unit, onSubmit: (String, String, String, String, String) -> Unit) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var type by remember { mutableStateOf("捐赠") }
    var target by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("发布物资捐换") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(title, { title = it }, label = { Text("标题") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(description, { description = it }, label = { Text("说明") }, modifier = Modifier.fillMaxWidth())
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(type == "捐赠", { type = "捐赠" }, label = { Text("捐赠") })
                    FilterChip(type == "求助", { type = "求助" }, label = { Text("求助") })
                }
                OutlinedTextField(target, { target = it }, label = { Text("城市/交换目标") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(phone, { phone = it }, label = { Text("联系方式") }, modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = { Button(onClick = { onSubmit(title, description, type, target, phone) }) { Text("发布") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("取消") } },
    )
}

@Composable
private fun AdoptionScreen(state: AppUiState, viewModel: AppStateViewModel) {
    var tab by remember { mutableIntStateOf(0) }
    val tabs = listOf("流程", "故事书", "领养社区", "爱兔社区")
    Column(Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = tab) {
            tabs.forEachIndexed { index, title -> Tab(selected = tab == index, onClick = { tab = index }, text = { Text(title) }) }
        }
        when (tab) {
            0 -> AdoptionProcess()
            1 -> Storybook(state)
            2 -> FosterCommunity(state, viewModel)
            3 -> RabbitCommunity(state, viewModel)
        }
    }
}

@Composable
private fun AdoptionProcess() {
    val steps = listOf("了解兔兔", "提交意向", "电话沟通", "家访评估", "签署协议", "试养回访", "正式领养")
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items(steps.withIndex().toList()) { item ->
            Card {
                Row(Modifier.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("${item.index + 1}", color = RabbitRose, fontWeight = FontWeight.Bold)
                    Text(item.value)
                }
            }
        }
    }
}

@Composable
private fun Storybook(state: AppUiState) {
    val stories = state.rescues.filter { it.moderationStatus == ModerationStatus.Approved.value }
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        items(stories) { post ->
            Card(shape = RoundedCornerShape(22.dp)) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    RabbitImage(post.images.firstOrNull(), Modifier.fillMaxWidth().height(170.dp))
                    Text(post.title, fontWeight = FontWeight.Bold)
                    Text("从 ${post.status} 到被看见，每一条线索都是故事的开始。")
                }
            }
        }
    }
}

@Composable
private fun FosterCommunity(state: AppUiState, viewModel: AppStateViewModel) {
    val foster = state.rescues.filter { it.status == "寄养中" || it.status == "已救助" }
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        items(foster.ifEmpty { state.rescues.take(2) }) { post ->
            Card {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(post.title, fontWeight = FontWeight.Bold)
                    Text(post.description, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    Button(onClick = { viewModel.submitAdoptionIntent(post.title) }) { Text("提交领养意向") }
                }
            }
        }
    }
}

@Composable
private fun RabbitCommunity(state: AppUiState, viewModel: AppStateViewModel) {
    var content by remember { mutableStateOf("") }
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Card {
                Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(content, { content = it }, label = { Text("分享你的养兔/救助动态") }, modifier = Modifier.fillMaxWidth())
                    Button(onClick = { viewModel.addCommunityPost(content); content = "" }) { Text("发布社区帖") }
                }
            }
        }
        items(state.community, key = { it.id }) { post ->
            CommunityCard(post, state.profile.isAdmin, viewModel)
        }
    }
}

@Composable
private fun CommunityCard(post: CommunityPost, isAdmin: Boolean, viewModel: AppStateViewModel) {
    Card {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(post.author, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                Text(post.date, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text(post.content)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick = { viewModel.toggleLike(post) }) {
                    Icon(Icons.Default.Favorite, contentDescription = null, tint = if (post.likedByMe) RabbitRose else MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(4.dp))
                    Text("${post.likes}")
                }
                if (isAdmin) {
                    TextButton(onClick = { viewModel.deleteCommunityPost(post) }) {
                        Icon(Icons.Default.Delete, contentDescription = null)
                        Text("删除")
                    }
                }
            }
        }
    }
}

@Composable
private fun ActivityScreen(state: AppUiState, viewModel: AppStateViewModel) {
    var tab by remember { mutableIntStateOf(0) }
    val tabs = listOf("活动", "线下活动", "爱心橱窗")
    Column(Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = tab) {
            tabs.forEachIndexed { index, title -> Tab(selected = tab == index, onClick = { tab = index }, text = { Text(title) }) }
        }
        when (tab) {
            0 -> CheckinAndCloud(viewModel)
            1 -> OfflineEvents(state.offlineEvents, state.profile.isAdmin, viewModel)
            2 -> CharityShop(state.products, viewModel)
        }
    }
}

@Composable
private fun CheckinAndCloud(viewModel: AppStateViewModel) {
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Card(colors = CardDefaults.cardColors(containerColor = RabbitPink)) {
                Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("只取心滴打卡", fontWeight = FontWeight.Bold)
                    Text("记录今天的公益行动，首版用按钮模拟打卡完成。")
                    Button(onClick = { viewModel.confirmCloudAdoption() }) { Text("完成今日打卡") }
                }
            }
        }
        item {
            Card {
                Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("云养计划", fontWeight = FontWeight.Bold)
                    Text("确认一次云养支持，获得云养币并生成站内信。")
                    Button(onClick = viewModel::confirmCloudAdoption) { Text("确认云养") }
                }
            }
        }
    }
}

@Composable
private fun OfflineEvents(events: List<OfflineEvent>, isAdmin: Boolean, viewModel: AppStateViewModel) {
    var showAdd by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxSize()) {
        LazyColumn(contentPadding = PaddingValues(16.dp, 16.dp, 16.dp, 96.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(events) { event ->
                Card {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(event.title, fontWeight = FontWeight.Bold)
                        Text("${event.date} · ${event.location}")
                        Text(if (event.upcoming) "即将开始" else "往期活动", color = RabbitRose)
                        Text(event.description)
                    }
                }
            }
        }
        if (isAdmin) {
            ExtendedFloatingActionButton(
                onClick = { showAdd = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("新增活动") },
                modifier = Modifier.align(Alignment.BottomEnd).padding(20.dp),
            )
        }
    }
    if (showAdd) {
        SimpleInputDialog(
            title = "新增线下活动",
            firstLabel = "活动标题",
            secondLabel = "地点",
            onDismiss = { showAdd = false },
            onSubmit = { title, location -> viewModel.addOfflineEvent(title, location); showAdd = false },
        )
    }
}

@Composable
private fun CharityShop(products: List<CharityProduct>, viewModel: AppStateViewModel) {
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        items(products) { product ->
            Card {
                Row(Modifier.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(64.dp).clip(RoundedCornerShape(16.dp)).background(RabbitPink), contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.ShoppingCart, contentDescription = null, tint = RabbitRose)
                    }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(product.title, fontWeight = FontWeight.Bold)
                        Text(product.description, maxLines = 2, overflow = TextOverflow.Ellipsis)
                        Text("¥${product.price} · +${product.coins} 云养币", color = RabbitRose)
                    }
                    Button(onClick = { viewModel.placeOrder(product) }) { Text("下单") }
                }
            }
        }
    }
}

@Composable
private fun ProfileScreen(state: AppUiState, viewModel: AppStateViewModel) {
    var dialog by remember { mutableStateOf<String?>(null) }
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = RabbitPink),
                shape = RoundedCornerShape(26.dp),
            ) {
                Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(state.profile.userName, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    Text(state.profile.userBio)
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        AssistChip(onClick = {}, label = { Text("奖章 ${state.profile.badges}") })
                        AssistChip(onClick = {}, label = { Text("云养币 ${state.profile.cloudCoins}") })
                        if (state.profile.isAdmin) AssistChip(onClick = {}, label = { Text("管理员") })
                    }
                }
            }
        }
        item { ProfileAction("消息中心", Icons.Default.Mail) { dialog = "inbox" } }
        if (state.profile.isAdmin) item { ProfileAction("管理通知", Icons.Default.CheckCircle) { dialog = "admin" } }
        item { ProfileAction("我的订单", Icons.Default.ShoppingCart) { dialog = "orders" } }
        item { ProfileAction("我的发布", Icons.Default.VolunteerActivism, viewModel::openMyRescuePosts) }
        item { ProfileAction("收货地址", Icons.Default.Home) { dialog = "address" } }
        item { ProfileAction("编辑资料", Icons.Default.Person) { dialog = "profile" } }
        item {
            OutlinedButton(onClick = viewModel::logout, modifier = Modifier.fillMaxWidth()) {
                Text("退出登录")
            }
        }
    }
    when (dialog) {
        "inbox" -> MessagesDialog("消息中心", state.inbox.filter { !it.adminOnly || state.profile.isAdmin }) { dialog = null }
        "admin" -> MessagesDialog("管理通知", state.inbox.filter { it.adminOnly }) { dialog = null }
        "orders" -> OrdersDialog(state.orders) { dialog = null }
        "address" -> SimpleInputDialog("收货地址", "地址", "备注", state.profile.shippingAddress, "", { dialog = null }) { address, _ ->
            viewModel.saveAddress(address)
            dialog = null
        }
        "profile" -> SimpleInputDialog("编辑资料", "昵称", "简介", state.profile.userName, state.profile.userBio, { dialog = null }) { name, bio ->
            viewModel.saveProfile(name, bio)
            dialog = null
        }
    }
}

@Composable
private fun ProfileAction(title: String, icon: ImageVector, onClick: () -> Unit) {
    Card(Modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(icon, contentDescription = null, tint = RabbitRose)
            Text(title, modifier = Modifier.weight(1f), fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun MessagesDialog(title: String, messages: List<InboxMessage>, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                messages.ifEmpty { listOf(InboxMessage("empty", "暂无消息", "还没有新的站内信。", "")) }.forEach {
                    Text(it.title, fontWeight = FontWeight.Bold)
                    Text(it.body)
                    Spacer(Modifier.height(4.dp))
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("关闭") } },
    )
}

@Composable
private fun OrdersDialog(orders: List<RabbitOrder>, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("我的订单") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                orders.ifEmpty { listOf(RabbitOrder("empty", "暂无订单", 0, "待下单", "")) }.forEach {
                    Text(it.title, fontWeight = FontWeight.Bold)
                    Text("¥${it.amount} · ${it.status} · ${it.date}")
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("关闭") } },
    )
}

@Composable
private fun SimpleInputDialog(
    title: String,
    firstLabel: String,
    secondLabel: String,
    initialFirst: String = "",
    initialSecond: String = "",
    onDismiss: () -> Unit,
    onSubmit: (String, String) -> Unit,
) {
    var first by remember { mutableStateOf(initialFirst) }
    var second by remember { mutableStateOf(initialSecond) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(first, { first = it }, label = { Text(firstLabel) }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(second, { second = it }, label = { Text(secondLabel) }, modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = { Button(onClick = { onSubmit(first, second) }) { Text("保存") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("取消") } },
    )
}

@Composable
private fun RabbitImage(url: String?, modifier: Modifier = Modifier) {
    if (url.isNullOrBlank()) {
        Box(modifier.clip(RoundedCornerShape(18.dp)).background(RabbitPink), contentAlignment = Alignment.Center) {
            Text("兔兔", color = RabbitRose, fontWeight = FontWeight.Bold)
        }
    } else {
        AsyncImage(
            model = url,
            contentDescription = null,
            modifier = modifier.clip(RoundedCornerShape(18.dp)).background(RabbitPink),
            contentScale = ContentScale.Crop,
        )
    }
}

@Composable
private fun StatusChip(value: String) {
    val label = ModerationStatus.entries.firstOrNull { it.value == value }?.label ?: value
    AssistChip(onClick = {}, label = { Text(label) })
}

@Composable
private fun EmptyHint(text: String) {
    Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
        Text(text, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

private fun masked(value: String?): String {
    if (value.isNullOrBlank()) return "不公开"
    return if (value.length <= 4 || value.contains("@")) value else value.take(3) + "****" + value.takeLast(4)
}
