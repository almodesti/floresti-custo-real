const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,PUT,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...corsHeaders
    }
  });
}

function requiredEnv(env) {
  const missing = ["SUPABASE_URL", "SUPABASE_ANON", "SUPABASE_TOKEN"].filter((key) => !env[key]);
  if (missing.length) {
    throw new Error(`Missing environment variables: ${missing.join(", ")}`);
  }
}

async function supabaseRpc(env, fn, payload) {
  requiredEnv(env);
  const base = env.SUPABASE_URL.replace(/\/+$/, "");
  const res = await fetch(`${base}/rest/v1/rpc/${fn}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": env.SUPABASE_ANON,
      "Authorization": `Bearer ${env.SUPABASE_ANON}`
    },
    body: JSON.stringify(payload)
  });

  const data = await res.json().catch(() => null);
  if (!res.ok) {
    const message = data?.message || data?.hint || res.statusText || `HTTP ${res.status}`;
    return json({ error: message }, res.status);
  }
  return json(data);
}

async function handleApi(request, env) {
  const url = new URL(request.url);
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });

  if (url.pathname === "/api/health" && request.method === "GET") {
    return json({ ok: true });
  }

  if (url.pathname === "/api/state" && request.method === "GET") {
    return supabaseRpc(env, "get_custo_real_state", { p_token: env.SUPABASE_TOKEN });
  }

  if (url.pathname === "/api/state" && (request.method === "POST" || request.method === "PUT")) {
    const body = await request.json().catch(() => null);
    if (!body || typeof body !== "object") return json({ error: "Invalid JSON body" }, 400);
    return supabaseRpc(env, "save_custo_real_state", {
      p_token: env.SUPABASE_TOKEN,
      p_data: body
    });
  }

  return json({ error: "Not found" }, 404);
}

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      if (url.pathname.startsWith("/api/")) return handleApi(request, env);
      return env.ASSETS.fetch(request);
    } catch (err) {
      return json({ error: err.message || "Internal error" }, 500);
    }
  }
};
