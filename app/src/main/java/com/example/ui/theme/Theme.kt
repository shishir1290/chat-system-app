package com.example.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val NexoraDarkColorScheme = darkColorScheme(
    primary = NexoraEmeraldPrimary,
    onPrimary = NexoraDarkBg,
    primaryContainer = NexoraDarkSurfaceCard,
    onPrimaryContainer = NexoraEmeraldLight,
    secondary = NexoraCyanAccent,
    onSecondary = NexoraDarkBg,
    secondaryContainer = NexoraDarkSurfaceCard,
    onSecondaryContainer = NexoraCyanLight,
    tertiary = NexoraVioletGroup,
    onTertiary = NexoraDarkBg,
    background = NexoraDarkBg,
    onBackground = NexoraTextPrimary,
    surface = NexoraDarkSurface,
    onSurface = NexoraTextPrimary,
    surfaceVariant = NexoraDarkSurfaceCard,
    onSurfaceVariant = NexoraTextSecondary,
    outline = NexoraDarkBorder,
    error = NexoraCallRed,
    onError = NexoraTextPrimary
)

private val NexoraLightColorScheme = lightColorScheme(
    primary = NexoraEmeraldDark,
    onPrimary = NexoraTextPrimary,
    primaryContainer = NexoraEmeraldGlow,
    onPrimaryContainer = NexoraEmeraldDark,
    secondary = NexoraCyanAccent,
    onSecondary = NexoraTextPrimary,
    background = NexoraDarkBg, // Nexora is dark-first by design
    onBackground = NexoraTextPrimary,
    surface = NexoraDarkSurface,
    onSurface = NexoraTextPrimary,
    surfaceVariant = NexoraDarkSurfaceCard,
    onSurfaceVariant = NexoraTextSecondary,
    outline = NexoraDarkBorder,
    error = NexoraCallRed,
    onError = NexoraTextPrimary
)

@Composable
fun NexoraTheme(
    darkTheme: Boolean = true, // Nexora's signature dark aesthetic
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) NexoraDarkColorScheme else NexoraLightColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = NexoraDarkBg.toArgb()
                window.navigationBarColor = NexoraDarkBg.toArgb()
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
                WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = false
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
