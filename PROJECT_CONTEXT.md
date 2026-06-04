# SmartTrip Project Context

Last updated: 2026-06-02

This document is meant for handoff into a new Codex chat. It summarizes what the app is, where the project lives, the current architecture, the important implementation details, and the recent TestFlight / Cloudflare / DeepSeek work. Do not paste API keys into this file.

## Project Identity

- App name: `SmartTrip`
- Product type: iOS SwiftUI app
- Bundle identifier: `com.zhuzichen.SmartTrip`
- Current marketing version: `1.0`
- Current build number in project file: `5`
- Local repo path:
  - `/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip`
- Xcode project:
  - `/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip.xcodeproj`
- Source folder:
  - `/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip`
- Backend proxy folder:
  - `/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/Backend`

## Product Goal

SmartTrip is a travel-planning iOS app. The core product idea is:

1. User enters trip basics: destination, trip length, lodging status, lodging area if known, travel type, and preferences.
2. User can provide inspiration in three ways:
   - Import multiple travel-guide screenshots.
   - Paste travel-guide text.
   - Skip guide input and ask the app to directly recommend a route.
3. App uses AI to produce a structured itinerary.
4. Result page shows lodging advice, food recommendations, place categories, and day-by-day itinerary.
5. Each day can be adjusted using buttons such as rainy day, too tired, shopping, photo, etc.

The app is currently an early TestFlight/demo build, not a fully production-hardened app.

## Current Screens / Flow

### 1. `ContentView.swift`

Path:

`/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/ContentView.swift`

Purpose:

- First screen: create a trip.
- Fields:
  - Destination, required.
  - Days, required and numeric only.
  - Lodging status segmented picker:
    - `decided`: user has decided lodging.
    - `recommend`: app should recommend lodging.
  - Lodging area, required only if lodging status is `decided`.
  - Travel type:
    - `单人游`
    - `情侣游`
    - `朋友结伴`
    - `毕业旅行`
    - `公司团建`
    - `家庭亲子`
    - `无障碍旅行`
  - Travel preferences:
    - `美食`
    - `购物`
    - `拍照`
    - `轻松`
- Validation:
  - Destination cannot be empty.
  - Days cannot be empty and only accepts digits.
  - If lodging status is `decided`, lodging area cannot be empty.
  - Next button is disabled when form is invalid.
- Navigates to `PasteGuideView`.

Important note:

- There is a small oddity in current code:
  - `selectedPreferences` initializes as `["", "", "", ""]`.
  - Result page filters empty strings, so it does not break the UI, but it is cleaner to initialize as `[]`.

### 2. `PasteGuideView.swift`

Path:

`/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/PasteGuideView.swift`

Purpose:

- Second screen: import guide content or directly generate.

Input modes:

- `导入截图`
  - Uses `PhotosPicker`.
  - Current max selection count is `6`.
  - UI copy says 2-3 screenshots, but code allows up to 6.
  - Uses Apple Vision `VNRecognizeTextRequest` for OCR.
  - Recognition languages:
    - `zh-Hans`
    - `zh-Hant`
    - `en-US`
  - Recognized text is not shown in the large input box. This was intentional to avoid visual clutter.
  - Users can:
    - Preview screenshots.
    - Delete a single screenshot.
    - Clear all screenshots.
    - Re-select / edit image selection.
- `粘贴文字`
  - Shows `TextEditor`.
  - Generate button disabled if text is empty.
- `直接推荐`
  - No guide text is required.
  - AI generates from destination, days, lodging status, travel type, and preferences.

Generation behavior:

- Calls `DeepSeekService().generateTripPlan(...)`.
- Shows a progress UI while generating.
- Progress is simulated because LLM request progress is not truly observable with normal non-streaming API calls.
- Progress advances through status steps and can reach 99% while waiting.
- On success, navigates to `ResultView`.
- On failure, shows red error text.

Current error behavior:

- If the app cannot find backend configuration, it shows:
  - `生成失败：AI 服务还没有配置完成，请稍后再试。`
- If backend / DeepSeek returns an error, it shows a generated failure message.

### 3. `ResultView.swift`

Path:

`/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/ResultView.swift`

Purpose:

- Result page for the itinerary.
- Displays:
  - Header: destination + days.
  - Pills:
    - `每日可调整`
    - selected travel type
    - selected preferences
  - Lodging advice.
  - Food recommendations.
  - Place categories:
    - Must-go
    - Optional
    - Skipped
  - Daily itinerary cards.

Important behavior:

- Food has been separated from scenic places.
- `foodPlaces` from AI is preferred.
- If AI puts food inside `mustGoPlaces` or `optionalPlaces`, the result page tries to infer food by keywords and move it into the food section.
- Each day has:
  - Route.
  - Intensity.
  - Transport time.
  - Steps.
  - Expandable transport details.
  - Advice.
  - Adjustment note.
  - Adjustment buttons.

Adjustment buttons:

- Standard:
  - `标准版`
- Conditional:
  - `下雨了`
  - `起晚了`
  - `太累了`
  - `想购物`
  - `想拍照`

Rules added from product feedback:

- If the first day is only airport to hotel, only show `标准版`.
- If the last day is only hotel to airport, only show `标准版`.
- If a first day looks like arrival / airport / hotel / check-in day, hide `起晚了`.
- If an AI adjustment is unusable or identical to standard, the app falls back to locally generated adjustment text.
- Transport details should never say `同标准版`; the prompt now asks AI to always return concrete transport details.

Potential issue to watch:

- Local fallback transport is simple and uses approximate 15-minute segments. It is acceptable as a safety fallback, but not precise enough for production.

### 4. `TripModels.swift`

Path:

`/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/TripModels.swift`

Purpose:

- Codable data models used by AI response and result page.

Models:

- `PlaceItem`
- `BackupArea`
- `LodgingAdvice`
- `DayPlan`
- `TripPlan`
- `DayAdjustment`
- `DayAdjustments`
- `SampleTripData`

Important fields:

- `TripPlan`
  - `lodgingAdvice`
  - `foodPlaces`
  - `mustGoPlaces`
  - `optionalPlaces`
  - `skippedPlaces`
  - `days`
- `DayPlan`
  - `day`
  - `route`
  - `intensity`
  - `transportTime`
  - `transportDetails`
  - `steps`
  - `advice`
  - `easyAlternative`
  - `adjustments`
- `DayAdjustments`
  - `rain`
  - `late`
  - `tired`
  - `shopping`
  - `photo`

## AI / DeepSeek Integration

### `DeepSeekService.swift`

Path:

`/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/DeepSeekService.swift`

Purpose:

- Builds prompt.
- Calls AI.
- Decodes JSON.
- Validates destination / guide match.
- Validates and normalizes returned plan.

Important current configuration:

The iOS app should NOT contain the DeepSeek API key.

The app calls a Cloudflare Worker proxy instead:

`https://smarttrip.zichenz7.workers.dev`

The code currently looks for backend URL in this order:

1. Environment variable: `SMARTTRIP_API_BASE_URL`
2. Info.plist key: `SMARTTRIP_API_BASE_URL`
3. Hardcoded safe fallback Worker URL:
   - `https://smarttrip.zichenz7.workers.dev`

This fallback is safe because it is only the Worker URL, not the DeepSeek API key.

Local debug direct DeepSeek call:

- The code still supports local `DEEPSEEK_API_KEY` environment variable for debugging if no proxy URL is found.
- Do not commit Xcode scheme files containing `DEEPSEEK_API_KEY`.

Current prompt strategy:

- If guide text exists:
  - First validate that guide content matches destination.
  - Ask AI to synthesize 2-3 guide sources instead of copying one.
- If guide text is empty:
  - Generate a direct recommendation from trip basics.
- AI must return pure JSON.
- No Markdown.
- No code block.
- JSON schema is fixed.

Important prompt requirements:

- Separate `foodPlaces` from scenic places.
- Reflect travel preferences clearly.
- Evaluate known lodging area objectively.
- Always provide concrete transport details.
- Do not write `同标准版`.
- For adjustments, ensure route, advice, adjustment note, transport time, transport details, and steps are internally consistent.
- Handle arrival/departure days carefully.

Known limitation:

- LLM output can still be inconsistent. The app has some fallback logic, but production-level correctness would need stronger post-processing or separate itinerary validation.

## Backend Proxy

Folder:

`/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/Backend`

Files:

- `cloudflare-worker.js`
- `README.md`

Cloudflare Worker URL:

`https://smarttrip.zichenz7.workers.dev`

Worker endpoint used by app:

`POST https://smarttrip.zichenz7.workers.dev/chat/completions`

Worker behavior:

- Accepts `POST /chat/completions`.
- Requires Cloudflare secret:
  - `DEEPSEEK_API_KEY`
- Forwards request body to:
  - `https://api.deepseek.com/chat/completions`
- Adds Authorization header on server side:
  - `Bearer ${env.DEEPSEEK_API_KEY}`
- Returns DeepSeek response to app.

Security:

- The DeepSeek API key must only exist as a Cloudflare Worker Secret.
- Do not put the key in:
  - Swift source code.
  - Xcode Build Settings.
  - Xcode Scheme environment variables if the scheme is committed.
  - GitHub.
  - App Store Connect.
  - This context file.

Important: GitGuardian previously detected that a DeepSeek API key had been exposed on GitHub. The key should be rotated/revoked. Future work must avoid committing secrets.

## TestFlight / App Store Connect Status

The app has been uploaded to App Store Connect / TestFlight before.

Important TestFlight notes:

- Real phone installed through TestFlight uses Release build.
- Simulator run from Xcode often uses Debug build.
- Local environment variables may work in simulator but not in TestFlight.
- If TestFlight says `AI 服务还没有配置完成`, the installed build likely did not contain or read the backend URL.
- Current fix adds Worker URL as a safe fallback in `DeepSeekService.swift`.
- After this fix, the user must Archive and upload build `1.0 (5)` or later, then install that new build from TestFlight.

Build/version reminders:

- If uploading another TestFlight build, increase build number each time.
- Current project build number has been changed to `5`.
- After Archive upload, App Store Connect may show a different internal upload number, but the app build should be visible in TestFlight.

Encryption compliance:

- In App Store Connect TestFlight, if `Missing Compliance` appears:
  - Choose the option equivalent to `None of the algorithms mentioned above`.
  - The app only uses standard HTTPS/system networking and does not implement custom encryption.

Internal testing:

- Internal Testing only shows App Store Connect team members.
- External users require External Testing group and review flow.

## Recent TestFlight Bug Investigation

Problem:

- TestFlight app on real phone could not generate trips.
- Error:
  - `生成失败：AI 服务还没有配置完成，请稍后再试。`

Root cause:

- The app was not reading the Worker URL in the archived TestFlight package.
- Xcode Build Settings visually showed a value for `INFOPLIST_KEY_SMARTTRIP_API_BASE_URL`, but the actual archived `Info.plist` did not contain `SMARTTRIP_API_BASE_URL`.

Verification done:

- Checked latest Archive `Info.plist`.
- It contained:
  - `CFBundleShortVersionString = 1.0`
  - `CFBundleVersion = 3`
- It did not contain:
  - `SMARTTRIP_API_BASE_URL`

Fix applied:

- Added safe Worker URL fallback directly in `DeepSeekService.swift`.
- Cleaned project build setting so `INFOPLIST_KEY_SMARTTRIP_API_BASE_URL` is no longer empty.
- Increased build number to `5`.
- Ran a simulator build successfully:
  - `BUILD SUCCEEDED`

Next required user action:

1. Xcode: `Product -> Clean Build Folder`
2. Select `Any iOS Device (arm64)`
3. `Product -> Archive`
4. Upload new build
5. Install build `1.0 (5)` or later from TestFlight
6. Test direct recommendation first

If build `1.0 (5)` still fails:

- The app is probably reaching Worker but Worker / Secret / DeepSeek is failing.
- Check Cloudflare Worker secret name:
  - Must be exactly `DEEPSEEK_API_KEY`.
- Check Worker code is deployed after editing.
- Check Worker endpoint path:
  - `/chat/completions`
- Check Cloudflare Worker logs.

## Xcode / Build Commands

Useful local build command:

```bash
xcodebuild -project /Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip.xcodeproj -scheme SmartTrip -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/SmartTripDerivedData build
```

Check final Release build settings:

```bash
xcodebuild -project /Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip.xcodeproj -scheme SmartTrip -configuration Release -showBuildSettings | rg 'SMARTTRIP_API_BASE_URL|INFOPLIST_KEY_SMARTTRIP_API_BASE_URL|CURRENT_PROJECT_VERSION'
```

Check archived app Info.plist:

```bash
plutil -p "/Users/zhuzichen/Library/Developer/Xcode/Archives/2026-06-02/SmartTrip 2026-6-2, 14.31.xcarchive/Products/Applications/SmartTrip.app/Info.plist" | rg 'SMARTTRIP_API_BASE_URL|CFBundleVersion|CFBundleShortVersionString'
```

Note:

- Archive folder names depend on date/time.
- If testing a newer Archive, update the archive path.

## Git / GitHub Notes

GitHub repo:

`https://github.com/zichenz7/SmartTrip.git`

Past issues:

- GitHub push previously had network errors.
- Later repo did upload code.
- GitGuardian detected a DeepSeek API key leak.

Security rules for future Git:

- Do not commit API keys.
- Do not commit Xcode scheme env vars with `DEEPSEEK_API_KEY`.
- Cloudflare Worker source is safe to commit if it references `env.DEEPSEEK_API_KEY` and does not contain the real key.
- Worker URL is not secret and can be committed.

Recommended before commit:

```bash
git status
git diff
rg 'sk-[A-Za-z0-9]|DEEPSEEK_API_KEY|Authorization: Bearer' /Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip
```

The last command is only a rough scan. Do not paste any discovered secret into chat.

## Current Product Strengths

- Clear beginner-friendly flow.
- Supports screenshots, pasted text, and direct recommendation.
- Multi-source guide synthesis is supported.
- Food is separated from scenic place categories.
- Per-day adjustment buttons make result page feel interactive.
- App has basic safeguards for arrival/departure days.
- Cloudflare proxy keeps DeepSeek API key out of the iOS app.
- TestFlight upload pipeline mostly works.

## Current Product Weaknesses / Next Improvements

High priority:

1. Verify TestFlight build `1.0 (5)` or later can generate trips on real phone.
2. Add better backend error messages:
   - Worker missing secret.
   - DeepSeek quota exceeded.
   - DeepSeek timeout.
   - Invalid JSON response.
3. Add Cloudflare abuse protection:
   - Rate limiting.
   - Simple app token.
   - Origin checks are not enough for iOS.
4. Improve LLM output consistency:
   - Separate validation pass.
   - Deterministic route/transport cleanup.
   - Stronger JSON repair.
5. Improve direct recommendation quality.

Medium priority:

1. Change `selectedPreferences` initial value from `["", "", "", ""]` to `[]`.
2. Align screenshot selection copy with actual limit:
   - Either allow exactly 2-3 screenshots or update copy to 1-6 screenshots.
3. Improve progress UI copy and timeout handling.
4. Add a loading state after tapping generate so the button cannot be double tapped.
5. Add photo permission / failure UX polish.
6. Add Settings or diagnostics page showing app build number and backend status.
7. Add in-app privacy copy before screenshot OCR / AI upload.

Longer-term:

1. True streaming generation.
2. Save generated trips.
3. Regenerate only one day.
4. User editing of itinerary.
5. Maps / route time integration.
6. App Store production privacy policy and terms.

## Important UX Decisions Made

- User should not have to paste text if screenshots are easier.
- Recognized OCR text should not be dumped into the text box in screenshot mode because it looks ugly.
- If users give multiple guide screenshots, AI should synthesize them, not compare in an academic way.
- Food and scenic places should be separate.
- Transport details must be concrete; no `同标准版`.
- If AI produces a system-like inconsistency, do not make the user regenerate. App should either fix/fallback or present a usable plan.
- Arrival/departure-only days should not show unnecessary adjustment buttons.

## How To Brief Future Codex

If opening a new Codex chat, paste this file first and say:

> 这是 SmartTrip 当前项目上下文。请先阅读它，然后继续帮我处理当前问题。不要让我泄露 DeepSeek API Key。

Then attach the relevant screenshot or ask the next task.

