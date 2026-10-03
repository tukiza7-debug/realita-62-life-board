package id.realita62.lifeboard.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

private val LightColors = lightColorScheme(
    primary = BatikRed,
    onPrimary = PutihCream,
    primaryContainer = BatikRed,
    onPrimaryContainer = PutihCream,
    secondary = TealDeep,
    onSecondary = PutihCream,
    background = PutihCream,
    onBackground = Charcoal,
    surface = PutihCream,
    onSurface = Charcoal,
    tertiary = GoldAccent,
    onTertiary = Charcoal,
    error = CorruptPurple,
    onError = PutihCream
)

private val DarkColors = darkColorScheme(
    primary = DarkPrimary,
    onPrimary = DarkOnSurface,
    primaryContainer = DarkPrimary,
    onPrimaryContainer = DarkOnSurface,
    secondary = TealDeep,
    onSecondary = PutihCream,
    background = DarkSurface,
    onBackground = DarkOnSurface,
    surface = DarkSurface,
    onSurface = DarkOnSurface,
    tertiary = DarkAccent,
    onTertiary = Charcoal,
    error = CorruptPurple,
    onError = PutihCream
)

private val AppTypography = Typography(
    headlineLarge = TextStyle(fontSize = 32.sp, fontWeight = FontWeight.Bold),
    headlineMedium = TextStyle(fontSize = 24.sp, fontWeight = FontWeight.Bold),
    titleLarge = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.SemiBold),
    titleMedium = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.SemiBold),
    bodyLarge = TextStyle(fontSize = 16.sp),
    bodyMedium = TextStyle(fontSize = 14.sp),
    labelSmall = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Medium)
)

@Composable
fun RealitaTheme(darkTheme: Boolean, content: @Composable () -> Unit) {
    val colors = if (darkTheme) DarkColors else LightColors
    MaterialTheme(
        colorScheme = colors,
        typography = AppTypography,
        content = content
    )
}
