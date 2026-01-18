Prevent Cloud Cost Regressions Before They Merge

What this repo demonstrates

This repository shows how DevX detects cloud cost risks directly in pull requests — across infrastructure, application code, and CI pipelines.

Example 1 — Infrastructure cost regression

Change

resource "aws_nat_gateway" "this" {
- count = 0
+ count = 1
}


DevX detects

Always-on NAT Gateway

Recurring monthly cost in non-production

Example 2 — Application code amplification
- for (const user of users) {
-   await fetchProfile(user.id)
- }
+ await Promise.all(users.map(u => fetchProfile(u.id)))


DevX detects

N+1 remote calls

Runtime and API cost amplification

Example 3 — CI inefficiency
- runs-on: ubuntu-latest
+ runs-on: self-hosted-large


DevX detects

Over-provisioned CI runners

Increased per-run cost

Result

DevX posts a cost review directly in the pull request with:

Estimated monthly impact

Severity level

Clear fix recommendations

📸 Screenshot:
<img width="936" height="1558" alt="Screenshot 2026-01-18 at 22 35 26" src="https://github.com/user-attachments/assets/f2475779-3712-4a24-b76b-fed41292851d" />

