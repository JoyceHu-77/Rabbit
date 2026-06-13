package com.rabbit.android.base

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val RabbitRose = Color(0xFFE85D75)
val RabbitRoseDark = Color(0xFFB84058)
val RabbitPink = Color(0xFFFFEEF2)
val RabbitBackground = Color(0xFFFFF8F8)
val RabbitText = Color(0xFF32272A)
val RabbitMuted = Color(0xFF7D6B70)

private val LightColors: ColorScheme = lightColorScheme(
    primary = RabbitRose,
    onPrimary = Color.White,
    secondary = Color(0xFFFF9AAE),
    onSecondary = RabbitText,
    tertiary = Color(0xFF9B6A3B),
    background = RabbitBackground,
    onBackground = RabbitText,
    surface = Color.White,
    onSurface = RabbitText,
    surfaceVariant = RabbitPink,
    onSurfaceVariant = RabbitMuted,
    error = Color(0xFFD32F2F),
)

@Composable
fun RabbitTheme(content: @Composable () -> Unit) {
    val colors = if (isSystemInDarkTheme()) LightColors else LightColors
    MaterialTheme(
        colorScheme = colors,
        content = content,
    )
}
