#!/usr/bin/env python3
"""Check, from the agent's own debug log, that it uploaded data for each required product.

At `.debug` verbosity `DataUploadWorker` logs one line per upload attempt:

    → (rum) accepted, won't be retransmitted: [response code: 202 (accepted), request ID: ...]
    → (logging) not delivered, will be retransmitted: [response code: 503 ...]

That is the only place the real intake's response is observable from CI, so it is what this
reads. A product counts as delivered when at least one of its uploads returned a 2xx.

The agent's own wording is not enough to judge that. "accepted, won't be retransmitted" means
only that the batch will not be retried — which is also what the agent says about a permanent
rejection like 401 or 403, since retrying those is pointless. Reading the word alone therefore
reports an unauthorized run as a success, so the response code is what is checked here.

Exits non-zero when a required product produced no 2xx upload, and prints the response
codes it did see so the failure is diagnosable.
"""

import argparse
import re
import sys

# The `featureName` each product reports itself as (`Feature.rum`, `LogsFeature.name`,
# `TraceFeature.name`).
FEATURE_NAMES = {"rum": "rum", "logs": "logging", "traces": "tracing", "replay": "session-replay"}

ATTEMPT = re.compile(
    r"→ \((?P<feature>[\w-]+)\) (?P<verdict>accepted|not delivered)[^\[]*(?P<detail>\[[^\]]*\]?)"
)
RESPONSE_CODE = re.compile(r"response code: (?P<code>\d{3})")

# The agent disables itself when the heartbeat answers `allowAgent: false`, which is what a
# rejected license key produces. Everything downstream then looks like "the product produced no
# data", so this is surfaced as the cause rather than left to be inferred.
AGENT_DISABLED = re.compile(r"Agent (?:heartbeat allowed = false|DISABLED)")


def is_delivered(detail):
    """True when the intake answered 2xx. Unparseable details are not assumed to be successes."""
    match = RESPONSE_CODE.search(detail)
    return match is not None and 200 <= int(match.group("code")) < 300


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", required=True, help="Captured agent os_log file")
    parser.add_argument("--require", action="append", default=[], choices=sorted(FEATURE_NAMES),
                        help="Product that must have at least one accepted upload")
    args = parser.parse_args()

    try:
        with open(args.log, encoding="utf-8", errors="replace") as file:
            text = file.read()
    except OSError as error:
        sys.exit(f"::error::Cannot read agent log {args.log}: {error}")

    delivered, refused = {}, {}
    for match in ATTEMPT.finditer(text):
        detail = match.group("detail")
        bucket = delivered if is_delivered(detail) else refused
        bucket.setdefault(match.group("feature"), []).append(detail)

    agent_disabled = AGENT_DISABLED.search(text) is not None

    print("Upload attempts seen in the agent log:")
    for feature in sorted(set(delivered) | set(refused)):
        print(f"  {feature}: {len(delivered.get(feature, []))} delivered (2xx), "
              f"{len(refused.get(feature, []))} refused")
        for detail in (delivered.get(feature, []) + refused.get(feature, []))[:5]:
            print(f"    {detail}")

    if agent_disabled:
        print(
            "::error::The agent disabled itself: its heartbeat answered `allowAgent: false`. That is "
            "what a license key the intake does not accept looks like — check the key is valid for "
            "this site and is a mobile/RUM key, not an APM one. Everything below is a consequence of "
            "this, not an independent failure."
        )

    failures = []
    for product in args.require:
        feature = FEATURE_NAMES[product]
        if delivered.get(feature):
            print(f"✅ {product}: intake accepted {len(delivered[feature])} upload(s).")
            continue
        if refused.get(feature):
            failures.append(
                f"{product} ({feature}): every upload was refused by the intake — {refused[feature][0]}"
            )
        else:
            failures.append(
                f"{product} ({feature}): the agent logged no upload attempt at all — the product "
                f"was not enabled, produced no data, or could not reach the intake"
            )

    if failures or agent_disabled:
        for failure in failures:
            print(f"::error::{failure}")
        sys.exit(1)


if __name__ == "__main__":
    main()
