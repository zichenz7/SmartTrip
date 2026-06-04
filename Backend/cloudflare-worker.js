const DEEPSEEK_URL = "https://api.deepseek.com/chat/completions";

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    }
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return jsonResponse({});
    }

    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/chat/completions") {
      return jsonResponse({ error: "Not found" }, 404);
    }

    if (!env.DEEPSEEK_API_KEY) {
      return jsonResponse({ error: "AI service is not configured" }, 500);
    }

    let bodyText = "";
    try {
      bodyText = await request.text();
      JSON.parse(bodyText);
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const deepSeekResponse = await fetch(DEEPSEEK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${env.DEEPSEEK_API_KEY}`
      },
      body: bodyText
    });

    const responseText = await deepSeekResponse.text();
    return new Response(responseText, {
      status: deepSeekResponse.status,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }
    });
  }
};
