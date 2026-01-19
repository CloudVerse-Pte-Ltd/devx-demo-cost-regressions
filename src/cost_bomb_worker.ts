/**
 * Demo file: intentionally expensive patterns.
 * Expected findings: 
 * - Chatty API calls in loop
 * - Client recreated in hot path
 * - Retry explosion (no backoff/jitter)
 * - Frequent polling instead of events
 * - Excessive logging volume
 */

import https from "https";

type User = { id: string };

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

async function fetchJson(url: string): Promise<any> {
  // BAD: new agent every call, keepAlive disabled
  const agent = new https.Agent({ keepAlive: false });

  // BAD: naive retry with no backoff/jitter and no cap
  for (let attempt = 1; attempt <= 8; attempt++) {
    try {
      const res = await fetch(url, { agent } as any);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      // BAD: noisy logs in retry loop
      console.log("[retry]", { url, attempt, err: String(e) });
      // BAD: fixed sleep (thundering herd)
      await sleep(50);
    }
  }

  throw new Error("Failed after retries");
}

async function processUsers(users: User[]) {
  const results: any[] = [];

  // BAD: N+1 remote calls (2 calls per user)
  for (const u of users) {
    const profile = await fetchJson(`https://api.example.com/profile/${u.id}`);
    const usage = await fetchJson(`https://api.example.com/usage/${u.id}`);

    // BAD: logging inside hot path
    console.log("[user]", { id: u.id, plan: profile.plan, bytes: usage.bytes });

    results.push({ id: u.id, profile, usage });
  }

  return results;
}

// BAD: frequent polling loop (every second forever)
export async function pollForever() {
  while (true) {
    const users: User[] = await fetchJson("https://api.example.com/users");
    await processUsers(users);

    // too frequent for most workloads
    await sleep(1000);
  }
}

// Run if executed directly
if (require.main === module) {
  pollForever().catch((e) => {
    console.error("fatal", e);
    process.exit(1);
  });
}
