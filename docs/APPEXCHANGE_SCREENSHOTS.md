# AppExchange Media Guide (Screenshots & Videos)

## 📸 Overview

This guide explains how to generate professional screenshots and demo videos for the AppExchange listing.

## 🎯 Requirements

### **Screenshots**

**Salesforce AppExchange Screenshot Requirements:**
- **Dimensions**: Minimum 1280x800px (recommended: 1920x1080px)
- **Format**: PNG or JPG
- **Quantity**: 5-8 images
- **Quality**: High resolution, clear UI
- **Content**: Show real functionality, no lorem ipsum
- **Branding**: Clean, professional, no watermarks

### **Videos**

**Salesforce AppExchange Video Requirements:**
- **Duration**: 30-120 seconds per video
- **Format**: MP4, WebM, or MOV
- **Resolution**: 1280x800px minimum (HD preferred)
- **Size**: <50MB per video
- **Content**: Show real user flows, no mock data
- **Audio**: Optional (music/voiceover)

**Benefits of Videos:**
- ✅ Show complete user workflows
- ✅ Demonstrate responsive design
- ✅ Highlight key features in action
- ✅ Increase engagement (+40% vs screenshots only)
- ✅ Better for complex features

---

## 🚀 Automated Media Generation

### **Screenshots**

### **Method 1: Using Playwright Script (Recommended)**

```bash
# Generate all AppExchange screenshots automatically
node tests/screenshots/captureAppExchangeScreenshots.js
```

**Output:**
- `screenshots/appexchange/01_main_interface.png`
- `screenshots/appexchange/02_configuration_dropdown.png`
- `screenshots/appexchange/03_config_selected_preview.png`
- `screenshots/appexchange/04_query_results_table.png`
- `screenshots/appexchange/05_json_view.png`
- `screenshots/appexchange/06_mobile_view.png`
- `screenshots/appexchange/07_create_config_modal.png`
- `screenshots/appexchange/08_support_page.png`

### **Method 2: Manual Capture**

If you prefer to take screenshots manually for better control:

1. **Open Salesforce in Chrome**
2. **Set Window Size**: 1280x800px or larger
3. **Navigate to Query Viewer**
4. **Use Developer Tools**: F12 → Device Toolbar (Cmd+Shift+M on Mac)
5. **Capture**: Use Chrome's built-in screenshot tool or extensions

---

## 📋 Screenshot Checklist

### **1. Main Interface - Configuration Selection**
- ✅ Show searchable combobox
- ✅ Display environment badge (Production/Sandbox)
- ✅ Show "New Configuration" button
- ✅ Clean, empty state or with sample config

**Key Features to Highlight:**
- Searchable dropdown
- Modern UI design
- Clear call-to-action buttons

---

### **2. Configuration Dropdown Open**
- ✅ Show filtered options
- ✅ Display search functionality
- ✅ Show multiple configurations
- ✅ Highlight hover state

**Key Features to Highlight:**
- Real-time filtering
- Easy-to-read list
- Lightning Design System styling

---

### **3. Configuration Selected + Query Preview**
- ✅ Show selected configuration
- ✅ Display SQL query preview
- ✅ Show parameter inputs (if applicable)
- ✅ Display object/binding information

**Key Features to Highlight:**
- Query preview with syntax highlighting
- Dynamic parameter inputs
- Object name display
- Binding information

---

### **4. Query Results - Table View**
- ✅ Show populated results (10+ rows)
- ✅ Display pagination controls
- ✅ Show column headers
- ✅ Display record count

**Key Features to Highlight:**
- Responsive data table
- Pagination
- Clear column structure
- Professional results display

---

### **5. JSON View** (Optional but Recommended)
- ✅ Show formatted JSON
- ✅ Display syntax highlighting
- ✅ Show view toggle buttons
- ✅ Demonstrate alternative viewing options

**Key Features to Highlight:**
- Multiple view modes
- Syntax highlighted JSON
- Developer-friendly

---

### **6. Mobile Responsive View**
- ✅ Show mobile viewport (375x667)
- ✅ Display expandable cards
- ✅ Show mobile navigation
- ✅ Demonstrate responsive design

**Key Features to Highlight:**
- Fully responsive
- Mobile-optimized cards
- Touch-friendly UI

---

### **7. Create Configuration Modal**
- ✅ Show modal dialog
- ✅ Display form fields
- ✅ Show validation hints
- ✅ Display save/cancel buttons

**Key Features to Highlight:**
- In-app configuration creation
- User-friendly forms
- Field validation
- Professional modal UI

---

### **8. Support Page** (Optional)
- ✅ Show support card layout
- ✅ Display GitHub integration
- ✅ Show bug reporting options
- ✅ Display contact information

**Key Features to Highlight:**
- Integrated support
- GitHub connection
- Community engagement

---

### **Videos**

#### **Method 1: Using Playwright Script (Recommended)**

```bash
# Generate demo videos automatically
node tests/screenshots/captureAppExchangeVideos.js
```

**Output:**
- `videos/appexchange/01_complete_user_flow.webm` (~90 seconds)
- `videos/appexchange/02_mobile_responsive.webm` (~30 seconds)
- `videos/appexchange/03_config_creation.webm` (~40 seconds)

**Videos Include:**
1. **Complete User Flow**: Search → Select → Execute → View Results
2. **Mobile Responsive**: Touch interaction and card expansion
3. **Config Creation**: Modal workflow demonstration

#### **Method 2: Convert WebM to MP4 (if needed)**

```bash
# Using FFmpeg
ffmpeg -i videos/appexchange/01_complete_user_flow.webm \
       -c:v libx264 -preset slow -crf 22 \
       videos/appexchange/01_complete_user_flow.mp4

# Batch convert all
for file in videos/appexchange/*.webm; do
  ffmpeg -i "$file" -c:v libx264 -preset slow -crf 22 "${file%.webm}.mp4"
done
```

**FFmpeg Installation:**
- **Mac**: `brew install ffmpeg`
- **Linux**: `sudo apt install ffmpeg`
- **Windows**: Download from https://ffmpeg.org/

---

## 🎨 Post-Processing Tips

### **Screenshots**

### **Optimization Tools:**
- **ImageOptim** (Mac): https://imageoptim.com/
- **TinyPNG**: https://tinypng.com/
- **Squoosh**: https://squoosh.app/

### **Editing Tips:**
1. **Crop**: Remove unnecessary whitespace
2. **Annotate**: Add arrows/callouts to highlight features (optional)
3. **Optimize**: Reduce file size without losing quality
4. **Verify**: Check dimensions meet requirements (1280x800 min)

### **What to Avoid:**
- ❌ Blurry images
- ❌ Lorem ipsum or fake data
- ❌ Exposed sensitive information (usernames, emails)
- ❌ Broken UI elements
- ❌ Error messages (unless intentional demo)

---

## 📝 Screenshot Descriptions (for AppExchange)

Use these as templates for your listing:

### **Screenshot 1: Main Interface**
> "Dynamic Queries main interface featuring searchable configuration selector and modern Lightning UI"

### **Screenshot 2: Configuration Dropdown**
> "Real-time filtering of query configurations with intuitive search"

### **Screenshot 3: Query Preview**
> "Selected configuration with SQL query preview and dynamic parameter inputs"

### **Screenshot 4: Query Results**
> "Professional data table view with pagination and responsive design"

### **Screenshot 5: JSON View**
> "Alternative JSON view for developers with syntax highlighting"

### **Screenshot 6: Mobile View**
> "Fully responsive mobile interface with expandable result cards"

### **Screenshot 7: Create Configuration**
> "In-app configuration creation with field validation and user-friendly forms"

### **Screenshot 8: Support**
> "Integrated support page with GitHub issue tracking and community resources"

---

## ✅ Final Checklist

Before uploading to AppExchange:

- [ ] All screenshots are 1280x800px or larger
- [ ] No sensitive data visible (PII, credentials)
- [ ] UI is clean and professional
- [ ] Features are clearly visible
- [ ] File sizes are optimized (<500KB each)
- [ ] Filenames are descriptive
- [ ] Each screenshot has a description
- [ ] Screenshots show real functionality
- [ ] Mobile screenshots included
- [ ] Branding is consistent

---

### **Videos**

#### **Editing Tools:**
- **OpenShot** (Free, Cross-platform): https://www.openshot.org/
- **DaVinci Resolve** (Free, Professional): https://www.blackmagicdesign.com/products/davinciresolve
- **iMovie** (Mac): Built-in
- **Kdenlive** (Linux): https://kdenlive.org/

#### **Optimization:**
1. **Trim**: Remove unnecessary pauses
2. **Speed Up**: 1.25x-1.5x for longer flows
3. **Add Captions**: Highlight key actions
4. **Compress**: Keep under 50MB
5. **Add Branding**: Optional watermark/logo

#### **Video Tips:**
- ✅ Show real data (anonymized if needed)
- ✅ Smooth mouse movements
- ✅ Clear, purposeful interactions
- ✅ Consistent pacing
- ✅ Professional quality

#### **What to Avoid:**
- ❌ Shaky cursor movements
- ❌ Long waits/loading screens
- ❌ Errors or bugs
- ❌ Exposed sensitive data
- ❌ Audio glitches

---

## 🚀 Quick Commands

```bash
# Generate all screenshots
npm run screenshots:appexchange

# Generate demo videos
npm run videos:appexchange

# Or run manually
node tests/screenshots/captureAppExchangeScreenshots.js
node tests/screenshots/captureAppExchangeVideos.js
```

---

## 📁 Directory Structure

```
screenshots/
└── appexchange/
    ├── 01_main_interface.png
    ├── 02_configuration_dropdown.png
    ├── 03_config_selected_preview.png
    ├── 04_query_results_table.png
    ├── 05_json_view.png
    ├── 06_mobile_view.png
    ├── 07_create_config_modal.png
    └── 08_support_page.png

videos/
└── appexchange/
    ├── 01_complete_user_flow.webm (or .mp4)
    ├── 02_mobile_responsive.webm (or .mp4)
    └── 03_config_creation.webm (or .mp4)
```

---

## 🎯 Next Steps

### **For Screenshots:**
1. **Run script**: `npm run screenshots:appexchange`
2. **Review**: Check each screenshot for quality
3. **Optimize**: Compress images if needed
4. **Upload**: Add to AppExchange listing
5. **Describe**: Add descriptions for each image

### **For Videos:**
1. **Run script**: `npm run videos:appexchange`
2. **Review**: Watch each video for quality
3. **Convert**: WebM to MP4 if needed (see FFmpeg commands)
4. **Edit**: Trim/optimize if needed
5. **Upload**: Add to AppExchange or embed in README

---

## 📞 Questions?

If screenshots don't capture correctly, check:
- ✅ SF CLI session is active
- ✅ Org has test data
- ✅ Configurations exist
- ✅ Permission set is assigned
- ✅ Browser window is large enough

**Troubleshooting:** See `tests/e2e/AUTH_TROUBLESHOOTING.md`

