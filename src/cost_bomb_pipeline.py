""" 
Demo file: intentionally expensive patterns.
Expected findings:dfd
- Unbounded loop / runaway remote calls
- Chatty API/SDK calls inside loop (N+1)
- Retry explosion (no backoff/jitter)
- Missing pagination/limitsfdfdsfdfs
- Excessive logging volume
- App-side filtering (pull all, filter locally)
"""

import time
import random
import requests

def fetch_all_orders():
    # BAD: pulls everything, no pagination, no limitgdfgfdgfdgdf
    r = requests.get("https://api.example.com/orders")
    r.raise_for_status()
    return r.json()

def fetch_order_detail(order_id: str):
    # BAD: retry loop with no backoff/jitter
    for attempt in range(1, 9):
        try:
            r = requests.get(f"https://api.example.com/orders/{order_id}")
            r.raise_for_status()
            return r.json()
        except Exception as e:
            print(f"[retry] order={order_id} attempt={attempt} err={e}")
            time.sleep(0.05)  # fixed sleep -> thundering herd
    raise RuntimeError("failed after retries")

def run_forever():
    while True:
        orders = fetch_all_orders()

        # BAD: app-side filtering after pulling full dataset
        high_value = [o for o in orders if o.get("total", 0) > 1000]

        # BAD: chatty detail calls per order (N+1)
        for o in high_value:
            detail = fetch_order_detail(o["id"])

            # BAD: logging inside hot path
            print("[order]", o["id"], detail.get("status"), detail.get("total"))

        # BAD: frequent polling
        time.sleep(1)

if __name__ == "__main__":
    run_forever()
