---
name: ui-animation
description: "Advanced motion guidelines for high-end UI transitions."
---

## Implementation Rules
1. **Entrance Animations**: When a view loads, elements must "stagger" in (List items slide up one by one with a 50ms delay).
2. **State Transitions**: 
   - Button Click -> Progress Spinner: Use a `CrossFade` transition (300ms).
   - Validation Error: Shake animation (horizontal offset) using `AnimatedControl`.
3. **The "Hero" Transition**: When moving from Login to Dashboard, the logo should scale and move to the corner smoothly, not just disappear.
4. **Framerate**: Ensure all animations are defined with `duration` and `curve` to leverage high-refresh monitors (120Hz+).