# 🎥 E2E Visual Validation Guide

## Why Visual Validation Matters

**E2E test videos/screenshots are not just for debugging—they're a critical part of UI/UX validation.**

### What Videos/Screenshots Reveal:
- ✅ Actual rendered styles (not just code)
- ✅ User experience flow
- ✅ Timing and animations
- ✅ Responsive behavior
- ✅ Visual glitches or bugs
- ❌ Broken layouts
- ❌ Styling issues
- ❌ Alignment problems

---

## 📋 Visual Validation Checklist

### Before Every Commit, Review E2E Videos For:

#### **Layout & Spacing**
- [ ] Components are properly aligned
- [ ] Margins and padding are consistent
- [ ] No overlapping elements
- [ ] White space is balanced
- [ ] Grid/flex layouts work correctly

#### **Typography**
- [ ] Font sizes are correct
- [ ] Font weights match design
- [ ] Line heights are readable
- [ ] Text color has proper contrast
- [ ] No text truncation issues

#### **Colors & Theming**
- [ ] Brand colors applied correctly
- [ ] Hover states work
- [ ] Focus states visible
- [ ] Disabled states styled properly
- [ ] Error states show red
- [ ] Success states show green

#### **Components**
- [ ] Buttons render correctly
- [ ] Dropdowns open smoothly
- [ ] Tables format properly
- [ ] Modals center correctly
- [ ] Toasts appear in right position
- [ ] Icons display correctly
- [ ] Loading spinners work
- [ ] Pagination controls visible

#### **Responsive Design**
- [ ] Mobile viewport renders correctly
- [ ] Tablet viewport works
- [ ] Desktop viewport optimal
- [ ] No horizontal scroll
- [ ] Touch targets adequate size

#### **Interactions**
- [ ] Click animations smooth
- [ ] Hover effects work
- [ ] Focus indicators visible
- [ ] Transitions not janky
- [ ] Loading states clear

#### **Salesforce-Specific**
- [ ] SLDS components styled correctly
- [ ] Lightning Design System consistency
- [ ] Salesforce theme compatibility
- [ ] Card layouts proper
- [ ] Button variants correct

---

## 🎬 How to Review E2E Videos

### Step 1: Run E2E Tests
```bash
npm run test:e2e
```

**Result:** Videos saved to `test-results/` folder

### Step 2: Locate Videos
```bash
# List all generated videos
find test-results -name "*.webm" -type f

# Example output:
# test-results/queryViewer-should-execute-query/video.webm
# test-results/queryViewerPreview-should-show-preview/video.webm
```

### Step 3: Watch All Videos
```bash
# Open video folder
open test-results/

# Watch each video file
# Use QuickTime, VLC, or browser
```

### Step 4: Validate Against Checklist
For each video, check:
1. **Does the UI look correct?**
2. **Are styles applied properly?**
3. **Is spacing/alignment good?**
4. **Do animations work smoothly?**
5. **Are there any visual glitches?**

### Step 5: Compare with Design
- Compare video with design mockups
- Check against SLDS guidelines
- Verify brand consistency
- Validate responsive behavior

---

## 🚨 Common Visual Issues to Catch

### Layout Issues
```
❌ Elements overlapping
❌ Components cut off at edge
❌ Misaligned buttons/inputs
❌ Inconsistent spacing
❌ Broken grid layout
```

### Styling Issues
```
❌ Wrong font family
❌ Incorrect colors
❌ Missing hover states
❌ Broken CSS classes
❌ Z-index problems
```

### Component Issues
```
❌ Dropdown doesn't open
❌ Modal not centered
❌ Toast in wrong position
❌ Table columns misaligned
❌ Icons not showing
```

### Responsive Issues
```
❌ Horizontal scroll on mobile
❌ Text too small on mobile
❌ Buttons too close together
❌ Hidden content
❌ Layout breaks on tablet
```

---

## 📊 Example: Video Review Process

### Test: "should show data preview table"

#### Video Location:
```
test-results/queryViewerPreview-should-load-and-display/video.webm
```

#### What to Check:

**0:00-0:02** - Page Load
- [ ] Component loads smoothly
- [ ] No flash of unstyled content
- [ ] Layout stable on load

**0:02-0:04** - Config Selection
- [ ] Dropdown opens correctly
- [ ] Options styled properly
- [ ] Hover state works
- [ ] Selection feedback clear

**0:04-0:06** - Preview Loading
- [ ] Loading spinner appears
- [ ] Spinner centered correctly
- [ ] No layout shift

**0:06-0:08** - Preview Display
- [ ] Table renders properly
- [ ] Columns aligned
- [ ] Headers styled correctly
- [ ] Data rows readable
- [ ] Pagination controls visible

**0:08-0:10** - User Interaction
- [ ] Hover effects work
- [ ] Click feedback clear
- [ ] Focus states visible

#### Pass/Fail Decision:
- ✅ **PASS**: All visual elements correct
- ❌ **FAIL**: Any visual issue found → Fix before commit

---

## 🛠️ Tools for Video Review

### Recommended Players:
- **VLC Media Player** - Frame-by-frame review
- **QuickTime** - macOS native, smooth playback
- **Chrome Browser** - Drag .webm file into browser
- **VS Code** - Some extensions play .webm

### Frame-by-Frame Review:
```bash
# In VLC:
# - Press 'E' for frame-by-frame forward
# - Press 'Space' to pause
# - Use arrow keys for navigation

# In Chrome DevTools:
# - Right-click video → "Inspect"
# - Use playback controls
# - Slow down playback speed
```

### Screenshot Extraction:
```bash
# Extract frame from video at 3 seconds
ffmpeg -i test-results/video.webm -ss 00:00:03 -vframes 1 frame.png

# Compare frames
# Use image diff tools to compare before/after
```

---

## 📝 Documenting Visual Issues

When you find a visual issue in E2E video:

### Issue Template:
```markdown
## Visual Issue: [Title]

**Test:** queryViewerPreview.spec.js - "should show pagination"
**Video:** test-results/queryViewerPreview-pagination/video.webm
**Timestamp:** 0:05

### Issue Description:
Pagination buttons are misaligned on mobile viewport.

### Expected:
Buttons should be centered horizontally.

### Actual:
Buttons are left-aligned and partially cut off.

### Screenshot:
[Attach frame from video]

### Fix:
Update CSS in jtQueryResults.css:
- Add `text-align: center` to pagination container
- Add `justify-content: center` for flex container
```

---

## 🎯 Visual Validation Best Practices

### 1. **Watch at Normal Speed First**
- Get overall impression
- Spot obvious issues
- Check user flow

### 2. **Watch Again at 0.5x Speed**
- Catch subtle issues
- Check animations
- Verify transitions

### 3. **Pause and Inspect**
- Freeze on key screens
- Check alignment
- Validate spacing

### 4. **Compare Multiple Videos**
- Look for consistency
- Check patterns
- Spot anomalies

### 5. **Document Everything**
- Take screenshots
- Note timestamps
- Write descriptions

---

## 📈 Integration with Workflow

### In Development Cycle:
```
1. Write feature code
2. Write E2E test
3. Run E2E test → generates video ✓
4. Review video → validate styles ✓
5. Fix visual issues if found
6. Re-run E2E test → new video
7. Review again → looks good ✓
8. Deploy to org
9. Manual validation (compare with video)
10. Commit (only after video validation)
```

### Before Every Commit:
```bash
# 1. Run E2E tests
npm run test:e2e

# 2. Open test-results folder
open test-results/

# 3. Watch ALL .webm files
# 4. Validate against checklist
# 5. If any visual issue found → STOP
# 6. Fix issue → Re-run tests → Review again
# 7. All videos pass? → Proceed with commit
```

---

## 🎨 Visual Standards

### Salesforce Lightning Design System (SLDS)
- Follow SLDS spacing scale (0.25rem, 0.5rem, 1rem, etc)
- Use SLDS color tokens
- Apply SLDS typography scale
- Use SLDS component variants

### Brand Colors:
- Primary: `#667eea` (purple)
- Secondary: `#48bb78` (green)
- Error: `#ef4444` (red)
- Warning: `#f59e0b` (orange)
- Success: `#10b981` (green)

### Spacing Scale:
- xs: `0.25rem` (4px)
- small: `0.5rem` (8px)
- medium: `1rem` (16px)
- large: `1.5rem` (24px)
- xl: `2rem` (32px)

---

## ✅ Final Checklist Before Commit

After reviewing ALL E2E videos:

- [ ] All videos watched completely
- [ ] All visual elements correct
- [ ] No styling issues found
- [ ] Layout works on all viewports
- [ ] Colors match brand guidelines
- [ ] Typography consistent
- [ ] Animations smooth
- [ ] Components render correctly
- [ ] No visual glitches
- [ ] Comparison with design approved

**Only commit when ALL boxes checked!**

---

## 🚀 Remember

> **E2E videos are your eyes into the user experience.**  
> **If it looks wrong in the video, it will look wrong to users.**  
> **Never skip video review before commit!**

