# AfriCartel Web Deployment Guide

## Overview

This guide covers deploying your AfriCartel Flutter app to the web using Firebase Hosting.

---

## Prerequisites

- Flutter SDK installed
- Firebase CLI installed
- Firebase project created
- Git repository (this repo)

---

## Step 1: Enable Flutter Web

```bash
# Enable web support in Flutter
flutter config --enable-web

# Verify web is available
flutter devices
# Should show "Chrome" and "Web Server" in the list
```

---

## Step 2: Build for Web

```bash
# Build the web version
flutter build web --release

# Output will be in: build/web/
```

### Build Options

```bash
# With specific renderer (CanvasKit for better performance)
flutter build web --web-renderer canvaskit

# With HTML renderer (smaller size, faster load)
flutter build web --web-renderer html

# Auto-select renderer based on device
flutter build web --web-renderer auto
```

---

## Step 3: Test Locally

```bash
# Run in Chrome
flutter run -d chrome

# Or serve the built web files
cd build/web
python -m http.server 8000
# Open browser to: http://localhost:8000
```

---

## Step 4: Set Up Firebase Hosting

### Install Firebase CLI

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Initialize Firebase Hosting

```bash
# In your project root
firebase init hosting

# Choose options:
# - Select your Firebase project
# - Public directory: build/web
# - Single-page app: Yes
# - GitHub auto-deploy: No (optional)
```

---

## Step 5: Deploy to Firebase

```bash
# Build and deploy
flutter build web --release
firebase deploy --only hosting

# Your app will be live at:
# https://your-project-id.web.app
# https://your-project-id.firebaseapp.com
```

---

## Step 6: Custom Domain (Optional)

1. Go to Firebase Console
2. Navigate to Hosting
3. Click "Add custom domain"
4. Follow DNS configuration steps
5. Example: `www.africartel.com`

---

## Continuous Deployment

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: your-project-id
```

---

## Performance Optimization

### 1. Enable Caching

In `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*"],
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

### 2. Enable GZIP Compression

Automatically handled by Firebase Hosting.

### 3. Image Optimization

- Use WebP format
- Compress images before adding
- Use responsive images

---

## Troubleshooting

### Build Fails
```bash
flutter clean
flutter pub get
flutter build web --release
```

### White Screen on Load
- Check browser console for errors
- Verify base href in index.html
- Check Firebase hosting configuration

### Slow Loading
- Use CanvasKit renderer
- Enable caching
- Optimize images
- Use lazy loading

---

## Monitoring & Analytics

### Firebase Analytics

Add to `index.html` before `</body>`:

```html
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-analytics.js"></script>
<script>
  const firebaseConfig = {
    // Your config
  };
  firebase.initializeApp(firebaseConfig);
  firebase.analytics();
</script>
```

---

## URLs

**Development:** http://localhost:8000  
**Staging:** https://your-project-id.web.app  
**Production:** https://www.africartel.com (custom domain)

---

## Next Steps

1. Set up custom domain
2. Configure SSL certificate
3. Enable Firebase Analytics
4. Set up monitoring
5. Configure SEO metadata

---

**Developer:** Nashon Wayodi  
**Repository:** github.com/nashonwayodi74-spec/AfriCartel  
**Date:** November 29, 2025
