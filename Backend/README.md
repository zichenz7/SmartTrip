# SmartTrip Backend Proxy

This Cloudflare Worker keeps the DeepSeek API key off the iOS app.

## Deploy Steps

1. Create a Cloudflare Worker.
2. Paste `cloudflare-worker.js` into the Worker editor.
3. Add a Worker secret named `DEEPSEEK_API_KEY`.
4. Deploy the Worker.
5. Copy the Worker URL, for example:

```text
https://smarttrip-api.your-name.workers.dev
```

6. In Xcode, open `SmartTrip` target -> `Build Settings`, search for:

```text
SMARTTRIP_API_BASE_URL
```

Set it to the Worker URL above, without a trailing slash.

Do not put the DeepSeek API key in Xcode, source code, GitHub, or App Store Connect.
