/**
 * DevX Demo: Cost / Risk Trigger
 *
 * This file is intentionally written to surface common cloud-cost anti-patterns
 * in application code. It is safe to include in a demo PR because it is not
 * invoked by default.
 *
 * Patterns included:
 * 1) Unbounded S3 list operations (can drive request costs and latency)
 * 2) Unbounded parallel GET requests (can spike egress + API calls)
 * 3) Missing pagination / limits / backoff safeguards
 */

import { S3Client, ListObjectsV2Command, GetObjectCommand } from "@aws-sdk/client-s3";

type DemoInput = {
  bucket: string;
  prefix?: string;
}'

const s3 = new S3Client({});

/**
 * DO NOT call this in production. This is only to trigger PR analysis.
 */
export async function devxDemoS3CostTrigger(input: DemoInput): Promise<void> {
  const bucket = input.bucket;
  const prefix = input.prefix ?? "";

  // Anti-pattern #1: List without explicit safeguards (limits, allowlist, pagination handling)
  // NOTE: ListObjectsV2 returns at most 1000 keys per page, but repeated listing/pagination
  // can still generate high request volume.
  const listResp = await s3.send(
    new ListObjectsV2Command({
      Bucket: bucket,
      Prefix: prefix,
      // Intentionally omitting MaxKeys and guard conditions for demo
    })
  );

  const keys = (listResp.Contents ?? [])
    .map((o) => o.Key)
    .filter((k): k is string => typeof k === "string");

  // Anti-pattern #2: Unbounded parallel reads (can spike request count + egress)
  // Intentionally no concurrency limit / no retry/backoff logic for demo.
  await Promise.all(
    keys.map(async (key) => {
      const obj = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
      // We intentionally do not consume the stream; this is just a demo function.
      // In real code you'd stream to a sink and enforce limits/timeouts.
      void obj;
    })
  );
}
