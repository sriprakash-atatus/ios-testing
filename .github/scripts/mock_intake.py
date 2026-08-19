#!/usr/bin/env python3
"""Drive the repo's `tools/http-server-mock` intake from CI.

The mock intake records every POST it receives, keyed by the path it was sent to. The sample app
is pointed at one path per product through the `AT_TEST_SERVER_MOCK_CONFIGURATION` environment
variable (see `IntegrationTests/Runner/Environment.swift`), so "did the agent upload RUM events?"
becomes "did a POST arrive under the RUM path?". That makes agent initialization observable from
the outside, without a network call to a real Atatus intake and without a license key.

Subcommands:
  config  Print the base64 `AT_TEST_SERVER_MOCK_CONFIGURATION` value for the given session ids.
  wait    Block until a session has recorded at least N requests. Exits 1 on timeout.
  dump    Write the recorded requests, with decoded headers and bodies, to a JSON file.
"""

import argparse
import base64
import json
import sys
import time
import urllib.error
import urllib.request


def fetch_recorded(server):
    with urllib.request.urlopen(f"{server}/inspect", timeout=10) as response:
        return json.loads(response.read().decode("utf-8"))


def requests_for(recorded, session):
    # The app appends query items to some intakes (RUM uses `?atatusSource=ios`), so match on
    # the session id as a path prefix rather than on equality.
    return [entry for entry in recorded if entry["path"].startswith(f"/{session}")]


def cmd_config(args):
    def endpoint(session):
        return f"{args.server}/{session}" if session else None

    configuration = {
        "logsEndpoint": endpoint(args.logs),
        "tracesEndpoint": endpoint(args.traces),
        "rumEndpoint": endpoint(args.rum),
        "srEndpoint": endpoint(args.session_replay),
        # Non-optional in `HTTPServerMockConfiguration`, so it must always be present.
        "instrumentedEndpoints": [endpoint(session) for session in args.instrumented],
    }
    configuration = {key: value for key, value in configuration.items() if value is not None}
    configuration.setdefault("instrumentedEndpoints", [])
    payload = json.dumps(configuration, separators=(",", ":")).encode("utf-8")
    print(base64.b64encode(payload).decode("utf-8"))


def cmd_wait(args):
    deadline = time.monotonic() + args.timeout
    last_count = -1
    while True:
        try:
            matched = requests_for(fetch_recorded(args.server), args.session)
        except (urllib.error.URLError, OSError, json.JSONDecodeError) as error:
            matched = []
            if time.monotonic() >= deadline:
                sys.exit(f"::error::Mock intake at {args.server} unreachable: {error}")

        if len(matched) != last_count:
            last_count = len(matched)
            print(f"  {args.label}: {last_count}/{args.min_requests} upload(s) received", flush=True)

        if len(matched) >= args.min_requests:
            print(f"✅ {args.label}: agent uploaded {len(matched)} request(s).")
            return

        if time.monotonic() >= deadline:
            sys.exit(
                f"::error::{args.label}: expected at least {args.min_requests} upload(s) within "
                f"{args.timeout}s, got {len(matched)}. The agent did not initialize, or it did not "
                f"flush data to the intake."
            )
        time.sleep(args.poll_interval)


def cmd_dump(args):
    recorded = fetch_recorded(args.server)
    decoded = []
    for entry in recorded:
        headers = base64.b64decode(entry["headers"]).decode("utf-8", errors="replace")
        body = base64.b64decode(entry["body"])
        try:
            body_text = body.decode("utf-8")
        except UnicodeDecodeError:
            body_text = f"<{len(body)} bytes of binary data>"
        decoded.append({
            "method": entry["method"],
            "path": entry["path"],
            "headers": headers.splitlines(),
            "body": body_text.splitlines(),
        })

    with open(args.output, "w", encoding="utf-8") as file:
        json.dump(decoded, file, indent=2)
    print(f"Wrote {len(decoded)} recorded request(s) to {args.output}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server", required=True, help="Mock intake base URL, e.g. http://10.0.0.2:8000")
    subparsers = parser.add_subparsers(dest="command", required=True)

    config = subparsers.add_parser("config")
    config.add_argument("--logs", default="")
    config.add_argument("--traces", default="")
    config.add_argument("--rum", default="")
    config.add_argument("--session-replay", default="")
    config.add_argument("--instrumented", action="append", default=[])
    config.set_defaults(func=cmd_config)

    wait = subparsers.add_parser("wait")
    wait.add_argument("--session", required=True)
    wait.add_argument("--label", default="intake")
    wait.add_argument("--min-requests", type=int, default=1)
    wait.add_argument("--timeout", type=float, default=120)
    wait.add_argument("--poll-interval", type=float, default=2)
    wait.set_defaults(func=cmd_wait)

    dump = subparsers.add_parser("dump")
    dump.add_argument("--output", required=True)
    dump.set_defaults(func=cmd_dump)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
