#!/usr/bin/env python3
"""Check, from the agent's own debug log, that it uploaded data for each required product.

At `.debug` verbosity `DataUploadWorker` logs one line per upload attempt:

    → (rum) accepted, won't be retransmitted: [response code: 202 (accepted), request ID: ...]
    → (logging) not delivered, will be retransmitted: [response code: 503 ...]

That is the only place the real intake's response is observable from CI, so it is what this
reads. A product counts as delivered when at least one of its uploads was accepted.

Exits non-zero when a required product produced no accepted upload, and prints the response
codes it did see so the failure is diagnosable.
"""

import argparse
import re
import sys

# The `featureName` each product reports itself as (`Feature.rum`, `LogsFeature.name`,
# `TraceFeature.name`).
FEATURE_NAMES = {"rum": "rum", "logs": "logging", "traces": "tracing"}

ACCEPTED = re.compile(r"→ \((?P<feature>[\w-]+)\) accepted[^\[]*(?P<detail>\[[^\]]*\]?)")
REJECTED = re.compile(r"→ \((?P<feature>[\w-]+)\) not delivered[^\[]*(?P<detail>\[[^\]]*\]?)")


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

    accepted, rejected = {}, {}
    for match in ACCEPTED.finditer(text):
        accepted.setdefault(match.group("feature"), []).append(match.group("detail"))
    for match in REJECTED.finditer(text):
        rejected.setdefault(match.group("feature"), []).append(match.group("detail"))

    print("Upload attempts seen in the agent log:")
    for feature in sorted(set(accepted) | set(rejected)):
        print(f"  {feature}: {len(accepted.get(feature, []))} accepted, "
              f"{len(rejected.get(feature, []))} not delivered")
        for detail in (accepted.get(feature, []) + rejected.get(feature, []))[:5]:
            print(f"    {detail}")

    failures = []
    for product in args.require:
        feature = FEATURE_NAMES[product]
        if accepted.get(feature):
            print(f"✅ {product}: intake accepted {len(accepted[feature])} upload(s).")
            continue
        if rejected.get(feature):
            failures.append(
                f"{product} ({feature}): the intake rejected every upload — {rejected[feature][0]}"
            )
        else:
            failures.append(
                f"{product} ({feature}): the agent logged no upload attempt at all — the product "
                f"was not enabled, produced no data, or could not reach the intake"
            )

    if failures:
        for failure in failures:
            print(f"::error::{failure}")
        sys.exit(1)


if __name__ == "__main__":
    main()
