/**
 * DEVX COST BOMB WORKER (TypeScript)
 * Purpose: Trigger high-impact DevX runtime cost findings.
 * This file intentionally demonstrates patterns that cause:
 * - Retry storms (infinite retries, no backoff/jitter)
 * - N+1 / chatty API calls inside loops
 * - Infinite polling loops (no bounds)
 * - Excessive logging in hot paths
 * - Thundering herd behavior across workers
 *
 * DO NOT USE IN PROD. Demo-only.
 */

type Order = { id: string; total: number; status: string };

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// Fake remote API call (simulate network + rate limiting)
async function httpGet<T>(url: string): Promise<T> {
  // simulate occasional failures
  if (Math.random() < 0.1) throw new Error("429 Too Many Requests");
  // simulate payload
  return JSON.parse(`[]`) as T;
}

// HIGH: Infinite retry loop without exponential backoff or jitter
async function fetchWithInfiniteRetry<T>(url: string): Promise<T> {
  let attempt = 0;
  while (true) {
    attempt++;
    try {
      return await httpGet<T>(url);
    } catch (e: any) {
      // BAD: noisy logs in retry loop
      console.log(`[retry] url=${url} attempt=${attempt} err=${e?.message || e}`);
      // BAD: fixed short sleep -> thundering herd
      await sleep(50);
    }
  }
}

// BAD: Pull-all with no pagination/limits (data egress + compute)
async function fetchAllOrders(): Promise<Order[]> {
  return await fetchWithInfiniteRetry<Order[]>("https://api.example.com/orders");
}

// HIGH: Chatty N+1 remote calls (one request per order)
async function fetchOrderDetail(id: string): Promise<Order> {
  return await fetchWithInfiniteRetry<Order>(`https://api.example.com/orders/${id}`);
}

async function runForever() {
  // HIGH: Infinite polling loop + short interval
  while (true) {
    const orders = await fetchAllOrders();

    // BAD: app-side filtering after pulling everything
    const highValue = orders.filter((o) => (o.total || 0) > 1000);

    // HIGH: Unbounded remote loop (N+1) + noisy logs
    for (const o of highValue) {
      const detail = await fetchOrderDetail(o.id);
      console.log(`[order] id=${o.id} status=${detail.status} total=${detail.total}`);
    }

    // BAD: frequent polling
    await sleep(1000);
  }
}

runForever().catch((e) => {
  console.error("worker crashed", e);
  process.exit(1);
});
