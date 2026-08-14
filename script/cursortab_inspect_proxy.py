#!/usr/bin/env python3
"""Loopback-only DeepSeek proxy that records CursorTab FIM exchanges as JSONL."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import select
import signal
import socket
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
import urllib.error
import urllib.request

SERVICE = "cursortab-inspect-proxy"
VERSION = 2


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def parse_json(data: bytes) -> Any:
    try:
        return json.loads(data)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return {"_raw": data.decode("utf-8", errors="replace")}


def write_private(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(content)


def read_health(host: str, port: int, timeout: float = 0.4) -> dict[str, Any] | None:
    try:
        with urllib.request.urlopen(
            f"http://{host}:{port}/__cursortab_inspect/health",
            timeout=timeout,
        ) as response:
            data = json.load(response)
    except Exception:
        return None
    if data.get("service") != SERVICE:
        return None
    return data


class InspectServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

    def __init__(
        self,
        address: tuple[str, int],
        *,
        upstream_base: str,
        allowed_path: str,
        trace_file: Path,
        pid_file: Path,
    ) -> None:
        super().__init__(address, InspectHandler)
        self.upstream_base = upstream_base.rstrip("/")
        self.allowed_path = allowed_path
        self.trace_file = trace_file
        self.pid_file = pid_file
        self.trace_lock = threading.Lock()

    def append_trace(self, trace: dict[str, Any]) -> None:
        encoded = json.dumps(trace, ensure_ascii=False, separators=(",", ":")) + "\n"
        self.trace_file.parent.mkdir(parents=True, exist_ok=True)
        with self.trace_lock:
            fd = os.open(self.trace_file, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
            with os.fdopen(fd, "a", encoding="utf-8") as handle:
                handle.write(encoded)


class InspectHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server: InspectServer

    def log_message(self, _format: str, *_args: Any) -> None:
        return

    def send_bytes(self, status: int, body: bytes, content_type: str, trace_id: str | None = None) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        if trace_id:
            self.send_header("X-CursorTab-Inspect-Id", trace_id)
        self.end_headers()
        self.wfile.write(body)

    def send_json(self, status: int, value: Any) -> None:
        body = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_bytes(status, body, "application/json")

    def do_GET(self) -> None:  # noqa: N802
        if self.path != "/__cursortab_inspect/health":
            self.send_json(404, {"error": "not found"})
            return
        self.send_json(
            200,
            {
                "service": SERVICE,
                "version": VERSION,
                "pid": os.getpid(),
                "upstream_base": self.server.upstream_base,
                "allowed_path": self.server.allowed_path,
                "trace_file": str(self.server.trace_file),
            },
        )

    def client_disconnected(self) -> bool:
        try:
            readable, _, _ = select.select([self.connection], [], [], 0)
            if not readable:
                return False
            return self.connection.recv(1, socket.MSG_PEEK) == b""
        except OSError:
            return True

    def do_POST(self) -> None:  # noqa: N802
        if self.path != self.server.allowed_path:
            self.send_json(404, {"error": "this proxy only forwards the configured CursorTab endpoint"})
            return

        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_json(400, {"error": "invalid Content-Length"})
            return
        if content_length <= 0 or content_length > 16 * 1024 * 1024:
            self.send_json(400, {"error": "request body must be between 1 byte and 16 MiB"})
            return

        request_bytes = self.rfile.read(content_length)
        request_body = parse_json(request_bytes)
        trace_id = f"{time.time_ns()}-{threading.get_ident()}"
        started_at = utc_now()
        started = time.perf_counter()
        upstream_url = self.server.upstream_base + self.path

        headers = {
            "Content-Type": self.headers.get("Content-Type", "application/json"),
            "Accept": self.headers.get("Accept", "application/json"),
        }
        authorization = self.headers.get("Authorization")
        if authorization:
            headers["Authorization"] = authorization

        upstream_request = urllib.request.Request(
            upstream_url,
            data=request_bytes,
            headers=headers,
            method="POST",
        )

        try:
            with urllib.request.urlopen(upstream_request, timeout=30) as response:
                status = response.status
                response_bytes = response.read()
                content_type = response.headers.get("Content-Type", "application/json")
                response_headers = {
                    key.lower(): value
                    for key, value in response.headers.items()
                    if key.lower()
                    in {
                        "content-type",
                        "x-request-id",
                        "x-ds-request-id",
                    }
                }
        except urllib.error.HTTPError as error:
            status = error.code
            response_bytes = error.read()
            content_type = error.headers.get("Content-Type", "application/json")
            response_headers = {
                key.lower(): value
                for key, value in error.headers.items()
                if key.lower()
                in {
                    "content-type",
                    "x-request-id",
                    "x-ds-request-id",
                }
            }
        except Exception as error:
            status = 502
            content_type = "application/json"
            response_headers = {}
            response_bytes = json.dumps(
                {"error": {"message": f"CursorTab inspect proxy: {type(error).__name__}: {error}"}},
                ensure_ascii=False,
            ).encode("utf-8")

        duration_ms = round((time.perf_counter() - started) * 1000, 2)
        response_body = parse_json(response_bytes)
        trace = {
            "schema_version": 2,
            "id": trace_id,
            "started_at": started_at,
            "duration_ms": duration_ms,
            "request": {
                "method": "POST",
                "path": self.path,
                "upstream_url": upstream_url,
                "headers": {
                    "content-type": headers["Content-Type"],
                    "accept": headers["Accept"],
                    "authorization": "Bearer <redacted>" if authorization else None,
                },
                "body": request_body,
            },
            "response": {
                "status": status,
                "headers": response_headers,
                "body": response_body,
            },
        }

        delivered = not self.client_disconnected()
        delivery_error = None if delivered else "client disconnected before the upstream response completed"
        if delivered:
            try:
                self.send_bytes(status, response_bytes, content_type, trace_id)
            except (BrokenPipeError, ConnectionResetError, OSError) as error:
                delivered = False
                delivery_error = f"{type(error).__name__}: {error}"
        trace["downstream"] = {
            "delivered": delivered,
            "error": delivery_error,
        }
        self.server.append_trace(trace)


def serve(args: argparse.Namespace) -> int:
    os.umask(0o077)
    trace_file = Path(args.trace_file).expanduser().resolve()
    pid_file = Path(args.pid_file).expanduser().resolve()
    server = InspectServer(
        (args.host, args.port),
        upstream_base=args.upstream_base,
        allowed_path=args.allowed_path,
        trace_file=trace_file,
        pid_file=pid_file,
    )
    write_private(pid_file, f"{os.getpid()}\n")

    def stop_server(_signum: int, _frame: Any) -> None:
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, stop_server)
    signal.signal(signal.SIGINT, stop_server)
    try:
        server.serve_forever(poll_interval=0.25)
    finally:
        server.server_close()
        try:
            if pid_file.read_text(encoding="utf-8").strip() == str(os.getpid()):
                pid_file.unlink(missing_ok=True)
        except OSError:
            pass
    return 0


def stop(pid_file: Path) -> None:
    try:
        pid = int(pid_file.read_text(encoding="utf-8").strip())
        os.kill(pid, signal.SIGTERM)
    except (OSError, ValueError):
        pass


def ensure(args: argparse.Namespace) -> int:
    expected = {
        "version": VERSION,
        "upstream_base": args.upstream_base.rstrip("/"),
        "allowed_path": args.allowed_path,
        "trace_file": str(Path(args.trace_file).expanduser().resolve()),
    }
    health = read_health(args.host, args.port)
    if health and all(health.get(key) == value for key, value in expected.items()):
        return 0
    if health:
        stop(Path(args.pid_file).expanduser())
        time.sleep(0.2)

    command = [
        sys.executable,
        str(Path(__file__).resolve()),
        "--serve",
        "--host",
        args.host,
        "--port",
        str(args.port),
        "--upstream-base",
        args.upstream_base,
        "--allowed-path",
        args.allowed_path,
        "--trace-file",
        args.trace_file,
        "--pid-file",
        args.pid_file,
        "--log-file",
        args.log_file,
    ]
    log_path = Path(args.log_file).expanduser().resolve()
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_handle = open(log_path, "ab", buffering=0)
    env = os.environ.copy()
    env.pop("DEEPSEEK_API_KEY", None)
    subprocess.Popen(
        command,
        stdin=subprocess.DEVNULL,
        stdout=log_handle,
        stderr=log_handle,
        start_new_session=True,
        close_fds=True,
        env=env,
    )
    log_handle.close()

    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        health = read_health(args.host, args.port)
        if health and all(health.get(key) == value for key, value in expected.items()):
            return 0
        time.sleep(0.05)
    print(f"failed to start {SERVICE} on {args.host}:{args.port}; see {log_path}", file=sys.stderr)
    return 1


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description=__doc__)
    mode = value.add_mutually_exclusive_group(required=True)
    mode.add_argument("--serve", action="store_true")
    mode.add_argument("--ensure", action="store_true")
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--stop", action="store_true")
    value.add_argument("--host", default="127.0.0.1")
    value.add_argument("--port", type=int, default=19198)
    value.add_argument("--upstream-base", default="https://api.deepseek.com")
    value.add_argument("--allowed-path", default="/beta/completions")
    value.add_argument("--trace-file", required=True)
    value.add_argument("--pid-file", required=True)
    value.add_argument("--log-file", required=True)
    return value


def main() -> int:
    os.umask(0o077)
    args = parser().parse_args()
    if args.serve:
        return serve(args)
    if args.ensure:
        return ensure(args)
    if args.check:
        health = read_health(args.host, args.port)
        if not health:
            return 1
        print(json.dumps(health, ensure_ascii=False))
        return 0
    if args.stop:
        stop(Path(args.pid_file).expanduser())
        return 0
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
