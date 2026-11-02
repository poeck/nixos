#!/usr/bin/env python3
"""Fixed-target wake button through Tailscale Serve or a private IP listener."""

import hmac
import html
import ipaddress
import json
import os
import secrets
import socket
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlsplit


TARGET = str(ipaddress.IPv4Address(os.environ.get("ATLAS_IP", "192.168.178.116")))
MAC = bytes.fromhex(os.environ.get("ATLAS_MAC", "00:91:9e:c0:c5:51").replace(":", ""))
if len(MAC) != 6:
    raise ValueError("ATLAS_MAC must contain six bytes")
INTERFACE = os.environ.get("ATLAS_INTERFACE", "wg-atlas")
LOGIN = os.environ["TAILSCALE_LOGIN"]
ORIGINS = {
    value.strip().rstrip("/")
    for value in os.environ.get("WAKE_ORIGINS", os.environ.get("WAKE_ORIGIN", "")).split(",")
}
for origin in ORIGINS:
    parsed = urlsplit(origin)
    valid = parsed.scheme == "https"
    if parsed.scheme == "http":
        try:
            valid = ipaddress.ip_address(parsed.hostname) in ipaddress.ip_network("100.64.0.0/10")
        except ValueError:
            valid = False
    if not valid or not parsed.netloc or parsed.username or parsed.password or parsed.path or parsed.query or parsed.fragment:
        raise ValueError("Wake origins must use HTTPS or a direct Tailscale IPv4 address")
HOSTS = {urlsplit(origin).netloc for origin in ORIGINS}
TOKEN = secrets.token_urlsafe(32)
PACKET = b"\xff" * 6 + MAC * 16
LAST_WAKE = 0.0


def tunnel_ready():
    """Fail closed when Atlas's route does not use the dedicated tunnel."""
    try:
        result = subprocess.run(
            ["/usr/sbin/ip", "-j", "route", "get", TARGET],
            check=True, capture_output=True, text=True, timeout=3,
        )
        routes = json.loads(result.stdout)
        return bool(routes) and routes[0].get("dev") == INTERFACE
    except (OSError, subprocess.SubprocessError, ValueError):
        return False


def wake():
    if not tunnel_ready():
        raise RuntimeError("Atlas's VPN connection is not ready. Please try again later.")
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sender:
        for _ in range(3):
            # UDP 7 reaches Atlas over this VPN; UDP 9 does not.
            sender.sendto(PACKET, (TARGET, 7))


def peer_login(address):
    """Resolve the authenticated peer through tailscaled, ignoring HTTP headers."""
    try:
        ip, port = address
        if ipaddress.ip_address(ip) not in ipaddress.ip_network("100.64.0.0/10"):
            return None
        result = subprocess.run(
            ["/usr/bin/tailscale", "whois", "--json", "--proto=tcp", f"{ip}:{port}"],
            check=True, capture_output=True, text=True, timeout=3,
        )
        identity = json.loads(result.stdout)
        if identity.get("Node", {}).get("Tags"):
            return None
        return identity.get("UserProfile", {}).get("LoginName")
    except (OSError, subprocess.SubprocessError, ValueError):
        return None


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, body, content_type="text/html; charset=utf-8"):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'")
        self.end_headers()
        self.wfile.write(data)

    def authorized(self):
        return (
            self.headers.get("Host") in HOSTS
            and hmac.compare_digest(self.headers.get("Tailscale-User-Login", ""), LOGIN)
        )

    def page(self, message="", status=200):
        self.respond(status, f"""<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wake Atlas</title><style>
body{{font:18px system-ui,sans-serif;background:#101720;color:#eef4ff;margin:0;padding:36px 24px}}
main{{max-width:420px;margin:12vh auto}}h1{{font-size:36px}}p{{line-height:1.5;color:#bdcbde}}
button{{width:100%;border:0;border-radius:12px;padding:20px;background:#88b9ff;color:#101720;font:600 20px system-ui;cursor:pointer}}
</style><main><h1>Wake Atlas</h1><p>Wake your PC from sleep. Allow a few seconds for it to reconnect.</p>
<form method="post" action="/wake"><input type="hidden" name="token" value="{TOKEN}"><button>Wake Atlas</button></form>
<p role="status">{html.escape(message)}</p></main></html>""")

    def do_GET(self):
        if self.path == "/healthz":
            ready = tunnel_ready()
            self.respond(200 if ready else 503, "ready\n" if ready else "tunnel unavailable\n", "text/plain")
        elif not self.authorized():
            self.respond(403, "Access denied.")
        elif self.path == "/":
            self.page()
        else:
            self.respond(404, "Not found.")

    def do_POST(self):
        global LAST_WAKE
        origin = self.headers.get("Origin", "")
        if not self.authorized() or origin not in ORIGINS or urlsplit(origin).netloc != self.headers.get("Host"):
            self.respond(403, "Access denied.")
            return
        if self.path != "/wake":
            self.respond(404, "Not found.")
            return
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= 512:
                raise ValueError
            token = parse_qs(self.rfile.read(size).decode()).get("token", [""])[0]
        except (ValueError, UnicodeError):
            self.respond(400, "Invalid request.")
            return
        if not hmac.compare_digest(token, TOKEN):
            self.respond(403, "Invalid form token. Reload the page and try again.")
            return
        if time.monotonic() - LAST_WAKE < 5:
            self.page("A wake packet was just sent. Wait a few seconds before trying again.", 429)
            return
        try:
            wake()
        except (OSError, RuntimeError) as error:
            self.page(str(error), 503)
            return
        LAST_WAKE = time.monotonic()
        self.page("Wake packets sent. Atlas should reconnect shortly.")


class DirectHandler(Handler):
    def authorized(self):
        if self.headers.get("Host") not in HOSTS:
            return False
        login = peer_login(self.client_address)
        return login is not None and hmac.compare_digest(login, LOGIN)


if __name__ == "__main__":
    proxy = HTTPServer(("127.0.0.1", 8091), Handler)
    direct_ip = os.environ.get("WAKE_TAILSCALE_IP")
    if direct_ip:
        if ipaddress.ip_address(direct_ip) not in ipaddress.ip_network("100.64.0.0/10"):
            raise ValueError("The direct listener must bind to a Tailscale IPv4 address")
        direct = HTTPServer((direct_ip, int(os.environ.get("WAKE_TAILSCALE_PORT", "8092"))), DirectHandler)
        threading.Thread(target=direct.serve_forever, daemon=True).start()
    proxy.serve_forever()
