# Art Skill Integration

**MANDATORY:** This skill inherits visual theming from the Art skill.

## Before Creating Any Video Content

1. **Load Art preferences** if available.

2. **Apply the theme** derived from Art preferences:

| Art Preference | Remotion Application |
|----------------|---------------------|
| Core aesthetic (charcoal architectural) | Dark backgrounds, sketch-like feel |
| Primary accent (purple/violet) | Accent colors, highlights, CTAs |
| Cool atmospheric washes | Background gradients, overlays |
| Paper ground (#F5F5F0) | Light text, subtle backgrounds |
| Human-scale in vast spaces | Typography hierarchy, spacing |

3. **Use Theme Constants:**
   ```
   ~/.claude/skills/Remotion/Tools/Theme.ts
   ```

4. **Reference images** (when visual style reference needed):
   ```
   ~/.claude/skills/Art/Examples/
   ```

## Theme Quick Reference

```typescript
import { THEME } from '~/.claude/skills/Remotion/Tools/Theme'

// Colors
THEME.colors.background    // #0f172a - Deep slate
THEME.colors.accent        // #8b5cf6 - Purple/violet
THEME.colors.text          // #f1f5f9 - Light text
THEME.colors.textMuted     // #94a3b8 - Muted text

// Typography
THEME.typography.title     // { fontSize: 72, fontWeight: 'bold' }
THEME.typography.subtitle  // { fontSize: 36 }
THEME.typography.body      // { fontSize: 24 }

// Animation
THEME.animation.springDefault  // { damping: 12, stiffness: 100 }
THEME.animation.fadeFrames     // 30 frames (~1 second)
THEME.animation.staggerDelay   // 10 frames

// Spacing
THEME.spacing.page         // 100px edge padding
THEME.spacing.section      // 60px between sections
THEME.spacing.element      // 30px between elements
```

## Using the Theme in Components

```typescript
import { THEME, titleScreenStyle, fadeInterpolation } from '~/.claude/skills/Remotion/Tools/Theme'

export const MyScene: React.FC = () => {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()

  const opacity = interpolate(
    frame,
    fadeInterpolation().inputRange,
    fadeInterpolation().outputRange,
    { extrapolateRight: 'clamp' }
  )

  const scale = spring({
    frame, fps,
    config: THEME.animation.springDefault
  })

  return (
    <AbsoluteFill style={titleScreenStyle}>
      <h1 style={{
        ...THEME.typography.title,
        color: THEME.colors.text,
        opacity,
        transform: `scale(${scale})`
      }}>
        Title Here
      </h1>
    </AbsoluteFill>
  )
}
```

**All videos MUST use this theme unless explicitly overridden.**
