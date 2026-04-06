# Codemagic CI/CD Setup Guide — Glow Dash

Complete step-by-step guide to build, sign, and deploy Glow Dash from
your Windows PC using Codemagic's cloud Mac build machines.

---

## Prerequisites

- [x] Apple Developer Account ($99/year) — https://developer.apple.com
- [x] Codemagic account (free tier: 500 min) — https://codemagic.io
- [x] GitHub account — https://github.com
- [x] Git installed on your Windows PC
- [x] The GlowDash project code (this repo)

---

## Step 1: Create the GitHub Repository

```bash
# From the GlowDash project directory:
cd C:\Users\nicho\Downloads\Game\GlowDash

# Create initial commit
git add -A
git commit -m "Initial commit: Glow Dash - complete game with all 6 phases"

# Create the repo on GitHub (using GitHub CLI, or do it on github.com)
gh repo create GlowDash --private --source=. --push

# Or manually:
# 1. Go to github.com → New Repository → Name: "GlowDash" → Private → Create
# 2. Then:
git remote add origin https://github.com/YOUR_USERNAME/GlowDash.git
git branch -M main
git push -u origin main
```

---

## Step 2: Create App Store Connect API Key

This key lets Codemagic authenticate with Apple for code signing and
TestFlight uploads — no need to share your Apple ID password.

1. Go to https://appstoreconnect.apple.com
2. Click **Users and Access** → **Integrations** tab → **App Store Connect API**
3. Click **Generate API Key**
4. Name: `Codemagic`
5. Access: **App Manager** (minimum needed for builds + TestFlight)
6. Click **Generate**
7. **IMPORTANT**: Download the `.p8` file immediately — you can only download it once!
8. Note down:
   - **Key ID** (e.g., `ABC1234DEF`)
   - **Issuer ID** (shown at top, e.g., `12345678-abcd-efgh-ijkl-123456789012`)

---

## Step 3: Create Your App ID in Apple Developer Portal

1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Click **+** → **App IDs** → **App**
3. Description: `Glow Dash`
4. Bundle ID: **Explicit** → `com.YOURNAME.glowdash`
   - Replace `YOURNAME` with your actual developer name
5. Capabilities: Check **Game Center** and **In-App Purchase** (even though we
   don't use IAP, some ad SDKs expect it)
6. Click **Continue** → **Register**

---

## Step 4: Register the App in App Store Connect

1. Go to https://appstoreconnect.apple.com → **My Apps** → **+** → **New App**
2. Fill in:
   - Platform: **iOS**
   - Name: `Glow Dash`
   - Primary Language: English (U.S.)
   - Bundle ID: Select `com.YOURNAME.glowdash`
   - SKU: `glowdash`
3. Click **Create**

---

## Step 5: Connect GitHub to Codemagic

1. Go to https://codemagic.io → Sign in with GitHub
2. Click **Add application**
3. Select your `GlowDash` repository
4. Select **codemagic.yaml** as the configuration type
5. Click **Finish: Add application**

---

## Step 6: Configure Code Signing in Codemagic

### Add the App Store Connect API Key

1. In Codemagic, go to **Teams** → **Integrations**
2. Under **App Store Connect**, click **Add key**
3. Name: `App Store Connect API Key`
4. Paste:
   - **Issuer ID** from Step 2
   - **Key ID** from Step 2
   - Upload the `.p8` file from Step 2
5. Click **Save**

### Update Bundle ID

1. Open `project.yml` in the repo
2. Change `com.developer.glowdash` to your actual bundle ID
3. Open `codemagic.yaml`
4. Change `com.developer.glowdash` to your actual bundle ID
5. Commit and push:
   ```bash
   git add project.yml codemagic.yaml
   git commit -m "Update bundle ID"
   git push
   ```

---

## Step 7: Update AdMob App ID

Before your first real build:

1. Create an AdMob account at https://admob.google.com
2. Create a new app → iOS → "Glow Dash"
3. Copy your **App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)
4. Update `GlowDash/Info.plist`:
   - Replace the `GADApplicationIdentifier` value with your real App ID
5. Create ad units (Banner, Interstitial, Rewarded) in AdMob dashboard
6. Update `GlowDash/Utilities/Constants.swift`:
   - Replace the three test ad unit IDs with your real ones
7. Commit and push

**IMPORTANT**: Keep the test ad unit IDs during development/testing.
Only switch to real IDs for the App Store release build.

---

## Step 8: Run Your First Build

1. Push your code to the `main` branch
2. Codemagic will auto-trigger a build (or click **Start new build** manually)
3. The build will:
   - Install XcodeGen
   - Generate the Xcode project from `project.yml`
   - Install CocoaPods (Google Mobile Ads SDK)
   - Sign the app using your App Store Connect API key
   - Build the `.ipa`
   - Upload to TestFlight

### First Build Troubleshooting

- **"No provisioning profile"**: Codemagic creates profiles automatically
  via the API key. Make sure the bundle ID matches exactly.
- **"Pod install failed"**: Check that the `Podfile` platform version
  matches your deployment target.
- **"XcodeGen not found"**: The `brew install xcodegen` step should handle
  this. Check the build logs.
- **Build takes too long**: First builds are slower (~15 min) due to
  CocoaPods cache. Subsequent builds are faster (~8 min).

---

## Step 9: Test on TestFlight

1. After a successful build, open the **TestFlight** app on your iPhone
2. You should see "Glow Dash" available for testing
3. Install and test everything:
   - [ ] Gameplay feels right (gravity, tap impulse, gap sizes)
   - [ ] Sound effects play correctly
   - [ ] Haptic feedback works
   - [ ] Neon Pulse color shifts trigger at 15-point intervals
   - [ ] Score saves and displays on game over
   - [ ] High score persists between sessions
   - [ ] Settings toggles work and persist
   - [ ] Skins unlock at correct thresholds
   - [ ] Daily challenge updates and tracks progress
   - [ ] Pause overlay appears when app goes to background
   - [ ] Ads load (test ads during development)
   - [ ] Share button works
   - [ ] Game Center connects (if signed in)
   - [ ] No crashes on different screen sizes

---

## Step 10: Generate App Icon

On your Windows PC:

```bash
pip install Pillow
python scripts/generate_icon.py
```

This creates `GlowDash/Assets.xcassets/AppIcon.appiconset/icon_1024.png`.

Then update `GlowDash/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [
    {
      "filename": "icon_1024.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Commit and push for the next build.

---

## Step 11: Take Screenshots

1. Install the TestFlight build on the largest iPhone you have access to
   (or use the simulator screenshots from Codemagic)
2. Take screenshots during gameplay at key moments:
   - Mid-gameplay with cyan theme
   - During a Neon Pulse color shift
   - Menu screen
   - Game over screen
   - Skins screen
   - Gameplay with a different skin
3. Upload to App Store Connect under **App Information** → **Screenshots**

---

## Step 12: Submit to App Store Review

1. In App Store Connect, go to your app
2. Fill in all required fields:
   - Description (from APP_STORE_LISTING.md)
   - Keywords
   - Support URL (can be your GitHub repo)
   - Privacy Policy URL (host the HTML file — see below)
   - Screenshots
   - App icon (auto-populated from build)
3. Select your TestFlight build under **Build**
4. Set pricing: **Free**
5. Set age rating: Answer the questionnaire (all "None" for this game)
6. Click **Submit for Review**

### Hosting the Privacy Policy

Easiest free option — GitHub Pages:
1. In your repo, go to Settings → Pages
2. Source: Deploy from branch → `main` → `/docs`
3. Your privacy policy URL becomes:
   `https://YOUR_USERNAME.github.io/GlowDash/privacy-policy.html`

---

## Step 13: Post-Launch

After approval (typically 24-48 hours):

1. **Switch to real AdMob ad unit IDs** (if you haven't already)
2. **Monitor AdMob dashboard** for revenue and fill rates
3. **Monitor App Store Connect** for downloads and ratings
4. **Respond to reviews** promptly
5. **Plan updates**: new skins, seasonal themes, new obstacle patterns

---

## Quick Reference: Key Files to Update Before Release

| File | What to Change |
|------|---------------|
| `project.yml` | Bundle ID |
| `codemagic.yaml` | Bundle ID |
| `Info.plist` | GADApplicationIdentifier (real AdMob App ID) |
| `Constants.swift` | Ad unit IDs (banner, interstitial, rewarded) |
| `Constants.swift` | leaderboardID, achievement IDs (match App Store Connect) |
| `Constants.swift` | appStoreURL (real App Store link after approval) |
| `privacy-policy.html` | Contact email |
