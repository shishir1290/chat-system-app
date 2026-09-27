package com.example.ui.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.CloudQueue
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.domain.model.UserStatus
import com.example.ui.theme.NexoraAwayAmber
import com.example.ui.theme.NexoraCyanAccent
import com.example.ui.theme.NexoraDarkBg
import com.example.ui.theme.NexoraDarkBorder
import com.example.ui.theme.NexoraDarkSurfaceCard
import com.example.ui.theme.NexoraEmeraldLight
import com.example.ui.theme.NexoraEmeraldPrimary
import com.example.ui.theme.NexoraOnlineGreen
import com.example.ui.theme.NexoraTextMuted
import com.example.ui.theme.NexoraTextPrimary
import com.example.ui.theme.NexoraTextSecondary
import com.example.ui.theme.NexoraVioletGroup
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun NexoraAvatar(
    name: String,
    avatarUrl: String = "",
    size: Dp = 48.dp,
    isGroup: Boolean = false,
    status: UserStatus? = null,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.size(size)) {
        if (avatarUrl.isNotBlank()) {
            AsyncImage(
                model = avatarUrl,
                contentDescription = name,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape)
                    .border(1.dp, NexoraDarkBorder, CircleShape)
            )
        } else {
            // Fallback Initials / Icon
            val bgGradient = if (isGroup) {
                Brush.linearGradient(listOf(NexoraVioletGroup, Color(0xFF6D28D9)))
            } else {
                Brush.linearGradient(listOf(NexoraEmeraldPrimary, Color(0xFF047857)))
            }
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape)
                    .background(bgGradient),
                contentAlignment = Alignment.Center
            ) {
                if (isGroup) {
                    Icon(
                        imageVector = Icons.Default.Group,
                        contentDescription = "Group",
                        tint = Color.White,
                        modifier = Modifier.size(size * 0.5f)
                    )
                } else {
                    val initials = name.split(" ")
                        .mapNotNull { it.firstOrNull()?.toString() }
                        .take(2)
                        .joinToString("")
                        .uppercase()

                    Text(
                        text = if (initials.isNotBlank()) initials else "?",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = (size.value * 0.38f).sp
                    )
                }
            }
        }

        // Presence Status Indicator dot
        if (status != null && !isGroup) {
            val statusColor = when (status) {
                UserStatus.ONLINE -> NexoraOnlineGreen
                UserStatus.AWAY -> NexoraAwayAmber
                UserStatus.BUSY -> Color(0xFFEF4444)
                UserStatus.OFFLINE -> Color(0xFF64748B)
            }
            val indicatorSize = size * 0.28f
            Box(
                modifier = Modifier
                    .size(indicatorSize)
                    .align(Alignment.BottomEnd)
                    .offset(x = 1.dp, y = 1.dp)
                    .background(statusColor, CircleShape)
                    .border(2.dp, NexoraDarkBg, CircleShape)
            )
        }
    }
}

@Composable
fun AudioWaveformVisualizer(
    levels: List<Float>,
    modifier: Modifier = Modifier,
    barColor: Color = NexoraEmeraldLight
) {
    Row(
        modifier = modifier.height(32.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        levels.forEach { level ->
            val heightFraction = level.coerceIn(0.1f, 1.0f)
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight(heightFraction)
                    .padding(horizontal = 1.5.dp)
                    .background(barColor, RoundedCornerShape(2.dp))
            )
        }
    }
}

@Composable
fun PulsingCallEmblem(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.25f,
        animationSpec = infiniteRepeatable(
            animation = tween(1400, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(140.dp * scale)
                .clip(CircleShape)
                .background(NexoraEmeraldPrimary.copy(alpha = 0.12f))
        )
        Box(
            modifier = Modifier
                .size(110.dp)
                .clip(CircleShape)
                .background(NexoraEmeraldPrimary.copy(alpha = 0.25f))
        )
        content()
    }
}

@Composable
fun FirebaseSyncChip(
    isReady: Boolean,
    statusText: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(if (isReady) Color(0x1A10B981) else Color(0x26F59E0B))
            .border(
                1.dp,
                if (isReady) NexoraEmeraldPrimary.copy(alpha = 0.5f) else NexoraAwayAmber.copy(alpha = 0.5f),
                RoundedCornerShape(20.dp)
            )
            .padding(horizontal = 10.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = if (isReady) Icons.Default.CloudDone else Icons.Default.CloudQueue,
            contentDescription = "Sync State",
            tint = if (isReady) NexoraEmeraldLight else NexoraAwayAmber,
            modifier = Modifier.size(14.dp)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = if (isReady) "Firebase Live" else "Local-First Mode",
            color = if (isReady) NexoraEmeraldLight else NexoraAwayAmber,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
fun NexoraSearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    placeholder: String = "Search chats, channels, or messages...",
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = {
            Text(
                text = placeholder,
                color = NexoraTextMuted,
                fontSize = 13.sp
            )
        },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = "Search",
                tint = NexoraTextMuted,
                modifier = Modifier.size(18.dp)
            )
        },
        singleLine = true,
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = NexoraDarkSurfaceCard,
            unfocusedContainerColor = NexoraDarkSurfaceCard,
            focusedBorderColor = NexoraEmeraldPrimary,
            unfocusedBorderColor = NexoraDarkBorder,
            focusedTextColor = NexoraTextPrimary,
            unfocusedTextColor = NexoraTextPrimary
        ),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier
            .fillMaxWidth()
            .testTag("nexora_search_bar")
    )
}

fun formatChatTime(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp
    val formatTime = SimpleDateFormat("h:mm a", Locale.getDefault())
    val formatDate = SimpleDateFormat("MMM d", Locale.getDefault())

    return when {
        diff < 60000 -> "Just now"
        diff < 86400000 -> formatTime.format(Date(timestamp))
        else -> formatDate.format(Date(timestamp))
    }
}

fun formatSecondsToTimer(totalSeconds: Int): String {
    val mins = totalSeconds / 60
    val secs = totalSeconds % 60
    return String.format(Locale.US, "%02d:%02d", mins, secs)
}
