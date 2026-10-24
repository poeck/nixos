#!/usr/bin/env python3
"""Keep Atlas awake for T3 work, using only the authenticated MCP interface."""
import argparse
import base64
import hashlib
import http.client
import json
import math
import os
import secrets
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from urllib.parse import parse_qs, urlencode, urlsplit

ENDPOINT = '127.0.0.1'
PORT = 3774
GRACE = 30 * 60
POLL = 15
ACTIVE = ['preparing', 'queued', 'starting', 'running']
PROTOCOLS = {'2024-11-05', '2025-03-26', '2025-06-18', '2025-11-25'}


class GuardError(Exception):
    pass


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix='.guard-')
    try:
        with os.fdopen(fd, 'w') as out:
            json.dump(value, out)
        os.replace(tmp, path)
    finally:
        Path(tmp).unlink(missing_ok=True)


def sse_response(response, request_id):
    lines = []
    size = 0
    deadline = time.monotonic() + 5
    for raw in response:
        if time.monotonic() > deadline:
            raise GuardError("MCP stream timed out")
        size += len(raw)
        if size > 4 * 1024 * 1024:
            raise GuardError('MCP response too large')
        line = raw.decode('utf-8').rstrip('\r\n')
        if line.startswith('data:'):
            lines.append(line[5:].lstrip(' '))
        elif not line and lines:
            message = json.loads('\n'.join(lines))
            lines = []
            if message.get('id') == request_id:
                return message
    raise GuardError('MCP stream ended without a matching response')


class Mcp:
    def __init__(self, token):
        token = token.strip()
        if not token or '\n' in token or '\r' in token:
            raise GuardError('Invalid MCP credential')
        self.token = token
        self.session = None
        self.version = '2025-06-18'
        self.sequence = 0
        # Do not inherit HTTP proxy settings: this credential is local-only.

    def request(self, method, params=None, notification=False):
        self.sequence += 1
        request_id = self.sequence
        body = {'jsonrpc': '2.0', 'method': method}
        if not notification:
            body['id'] = request_id
        if params is not None:
            body['params'] = params
        headers = {
            'Authorization': 'Bearer ' + self.token,
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/event-stream',
            'MCP-Protocol-Version': self.version,
        }
        if self.session:
            headers['Mcp-Session-Id'] = self.session
        connection = http.client.HTTPConnection(ENDPOINT, PORT, timeout=5)
        try:
            connection.request('POST', '/mcp', json.dumps(body), headers)
            response = connection.getresponse()
            if response.status not in (200, 202):
                raise GuardError(f'MCP HTTP {response.status}')
            session = response.getheader('Mcp-Session-Id')
            if session:
                self.session = session
            if notification:
                return None
            if 'text/event-stream' in response.getheader('Content-Type', ''):
                message = sse_response(response, request_id)
            else:
                data = response.read(4 * 1024 * 1024 + 1)
                if len(data) > 4 * 1024 * 1024:
                    raise GuardError('MCP response too large')
                message = json.loads(data)
            if message.get('id') != request_id or 'error' in message or 'result' not in message:
                raise GuardError(f'MCP {method} failed')
            return message['result']
        finally:
            connection.close()

    def initialize(self):
        result = self.request('initialize', {
            'protocolVersion': self.version, 'capabilities': {},
            'clientInfo': {'name': 'atlas-activity-guard', 'version': '1.0'},
        })
        self.version = result['protocolVersion']
        if self.version not in PROTOCOLS:
            raise GuardError('Unsupported MCP protocol version')
        self.request('notifications/initialized', notification=True)

    def close(self):
        if not self.session:
            return
        connection = http.client.HTTPConnection(ENDPOINT, PORT, timeout=5)
        try:
            connection.request('DELETE', '/mcp', headers={
                'Authorization': 'Bearer ' + self.token,
                'Mcp-Session-Id': self.session,
                'MCP-Protocol-Version': self.version,
            })
            connection.getresponse().close()
        except (OSError, http.client.HTTPException):
            pass
        finally:
            connection.close()

    def tool(self, name, arguments):
        result = self.request('tools/call', {'name': name, 'arguments': arguments})
        if result.get('isError'):
            raise GuardError(f'MCP tool {name} failed')
        if 'structuredContent' in result:
            return result['structuredContent']
        for block in result.get('content', []):
            if block.get('type') == 'text':
                return json.loads(block['text'])
        raise GuardError(f'MCP tool {name} returned no data')

    def active_count(self):
        count, projects, cursor, seen = 0, 0, None, set()
        while True:
            args = {'limit': 100}
            if cursor is not None:
                args['cursor'] = cursor
            page = self.tool('t3_project_list', args)
            if not isinstance(page.get('projects'), list):
                raise GuardError('Invalid project list')
            for project in page['projects']:
                if project.get('deletedAt'):
                    continue
                threads = self.tool('t3_thread_list', {
                    'projectId': project['id'], 'includeSubagents': True,
                    'statuses': ACTIVE, 'limit': 1,
                })
                total = threads.get('total')
                if type(total) is not int or total < 0:
                    raise GuardError('Invalid active thread count')
                if any(t.get('status') not in ACTIVE for t in threads.get('threads', [])):
                    raise GuardError('MCP ignored the active status filter')
                count += total
                projects += 1
            cursor = page.get('nextCursor')
            if cursor is None:
                return count, projects
            if cursor in seen:
                raise GuardError('Repeated project cursor')
            seen.add(cursor)


def config_directory():
    return Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'atlas-activity-guard'


def runtime_directory():
    return Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'atlas-activity-guard'


def local_json(path, data, form=False):
    connection = http.client.HTTPConnection(ENDPOINT, PORT, timeout=10)
    try:
        body = urlencode(data) if form else json.dumps(data)
        connection.request('POST', path, body, {
            'Content-Type': 'application/x-www-form-urlencoded' if form else 'application/json',
            'Accept': 'application/json',
        })
        response = connection.getresponse()
        if response.status not in (200, 201):
            raise GuardError(f'MCP authorization failed at {path} (HTTP {response.status})')
        return json.loads(response.read(1024 * 1024))
    finally:
        connection.close()


def authorize(renew=False):
    directory = config_directory()
    token = directory / 'token'
    if token.exists() and not renew:
        raise GuardError('Credential already exists; use renew to replace it')
    # MCP has its own OAuth credentials; general T3 bearer sessions are rejected.
    # A local CLI-issued one-time read-only grant approves the OAuth PKCE flow.
    result = subprocess.run([
        't3', 'auth', 'pairing', 'create', '--scope', 'orchestration:read',
        '--ttl', '5m', '--label', 'atlas-activity-guard bootstrap', '--json',
    ], capture_output=True, text=True, timeout=30)
    if result.returncode:
        raise GuardError('T3 could not issue a read-only pairing grant')
    grant = json.loads(result.stdout)
    redirect = 'http://127.0.0.1:41939/callback'
    registration = local_json('/oauth/mcp/register', {
        'client_name': 'atlas-activity-guard', 'redirect_uris': [redirect],
        'token_endpoint_auth_method': 'none',
    })
    verifier = secrets.token_urlsafe(48)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip('=')
    state = secrets.token_urlsafe(24)
    resource = f'http://{ENDPOINT}:{PORT}/mcp'
    authorization = {
        'response_type': 'code', 'client_id': registration['client_id'],
        'redirect_uri': redirect, 'code_challenge': challenge,
        'code_challenge_method': 'S256', 'state': state, 'resource': resource,
    }
    decision = local_json('/oauth/mcp/decision', {
        'authorization': authorization,
        'decision': {'_tag': 'pairing-code', 'access': 'read-only', 'code': grant['credential']},
    })
    callback = urlsplit(decision['redirectTo'])
    params = parse_qs(callback.query)
    if params.get('state') != [state] or 'code' not in params or 'error' in params:
        raise GuardError('MCP OAuth callback did not match the request')
    issued = local_json('/oauth/mcp/token', {
        'grant_type': 'authorization_code', 'code': params['code'][0],
        'redirect_uri': redirect, 'client_id': registration['client_id'],
        'code_verifier': verifier, 'resource': resource,
    }, form=True)
    if set(issued['scope'].split()) != {'orchestration:read'}:
        raise GuardError('MCP returned unexpected authorization scopes')
    candidate = Mcp(issued['access_token'])
    try:
        candidate.initialize()
        count, projects = candidate.active_count()
    finally:
        candidate.close()
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    write_json(directory / 'credential.json', {
        'createdAt': time.time(), 'expiresAt': time.time() + issued['expires_in'],
        'scope': issued['scope'],
    })
    write_json(token, issued['access_token'])
    print(f'Created a read-only MCP OAuth credential; checked {projects} projects, {count} active threads. No secret was printed.')


def client():
    # Credential contents are never put into argv, environment, logs or the store.
    path = config_directory() / 'token'
    credential = json.loads(path.read_text())
    return Mcp(credential)


def snapshot():
    mcp = client()
    try:
        mcp.initialize()
        return mcp.active_count()
    finally:
        mcp.close()


def last_input_at(directory, now):
    try:
        value = json.loads((directory / 'last-input.json').read_text())
        if type(value) not in (int, float) or not math.isfinite(value):
            return now
        return value
    except FileNotFoundError:
        return 0
    except (OSError, ValueError):
        return now


def stamp(action):
    directory = runtime_directory()
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    idle = directory / 'desktop-idle'
    if action == 'idle':
        idle.touch(mode=0o600)
    else:
        if action == 'active':
            idle.unlink(missing_ok=True)
        write_json(directory / 'last-input.json', time.monotonic())


def eligible(now, last_busy, last_input, idle, count, error):
    if not idle or now - last_input < GRACE:
        return False
    # MCP failures restore ordinary desktop idle behavior, ignoring AI grace.
    return bool(error) or (count == 0 and now - last_busy >= GRACE)


def fallback_needed(now, last_input, idle, state, wall_now):
    if not idle or now - last_input < GRACE:
        return False
    # A missing/stale heartbeat also covers a stopped/crashed main service.
    if not state:
        return True
    heartbeat = state.get('updatedAt')
    if type(heartbeat) not in (int, float) or not math.isfinite(heartbeat):
        return True
    if not -60 <= wall_now - heartbeat <= 60:
        return True
    return bool(state.get('error'))


def suspend():
    subprocess.run(['systemctl', 'suspend'], check=False, timeout=30)


def fallback():
    directory = runtime_directory()
    try:
        state = json.loads((directory / 'status.json').read_text())
        if not isinstance(state, dict):
            state = None
    except (OSError, ValueError):
        state = None
    now = time.monotonic()
    if fallback_needed(now, last_input_at(directory, now),
                       (directory / 'desktop-idle').exists(), state, time.time()):
        print('Activity monitor unavailable; applying normal desktop idle suspend', flush=True)
        # Reset the wake/input grace before requesting suspend so the fallback
        # timer cannot immediately repeat it on the next wake.
        stamp('wake')
        suspend()


def watch():
    directory = runtime_directory()
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    last_busy = time.monotonic()
    previous_poll = last_busy
    previous_reason = None
    while True:
        started = time.monotonic()
        # Long scheduling gaps/restarts/wake get a fresh grace period.
        if started - previous_poll > POLL * 3:
            last_busy = started
        previous_poll = started
        count, projects, error = None, 0, None
        try:
            count, projects = snapshot()
        except (GuardError, OSError, ValueError, KeyError, TypeError, http.client.HTTPException) as exc:
            # Never echo server bodies, credentials or exception details.
            error = str(exc) if isinstance(exc, GuardError) else type(exc).__name__
        now = time.monotonic()
        if count:
            last_busy = now
        idle = (directory / 'desktop-idle').exists()
        last_input = last_input_at(directory, now)
        remaining = max(0, int(GRACE - (now - max(last_busy, last_input))))
        reason = ('MCP unavailable; normal desktop idle timeout applies' if error else
                  'T3 work is running' if count else
                  'Waiting for desktop inactivity' if not idle else
                  'Waiting for grace period' if remaining else 'Ready to suspend')
        write_json(directory / 'status.json', {
            'updatedAt': time.time(), 'reason': reason, 'activeThreads': count,
            'projectsChecked': projects, 'desktopIdle': idle,
            'graceRemainingSeconds': remaining, 'error': error,
        })
        if reason != previous_reason:
            print(reason, flush=True)
            previous_reason = reason
        if eligible(now, last_busy, last_input, idle, count, error):
            # The all-project scan is not atomic. Confirm again immediately
            # before sleep, then recheck input/wake events received during it.
            if not error:
                try:
                    count, _ = snapshot()
                except (GuardError, OSError, ValueError, KeyError, TypeError, http.client.HTTPException):
                    error = 'MCP confirmation failed'
            now = time.monotonic()
            if eligible(now, last_busy, last_input_at(directory, now),
                        (directory / 'desktop-idle').exists(), count, error):
                stamp('wake')
                try:
                    suspend()
                except (OSError, subprocess.TimeoutExpired):
                    print('Suspend request failed', flush=True)
            last_busy = time.monotonic()
        time.sleep(max(1, POLL - (time.monotonic() - started)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['authorize', 'renew', 'probe', 'run', 'status', 'fallback', 'idle', 'active', 'wake'])
    action = parser.parse_args().action
    if action in ('authorize', 'renew'):
        authorize(renew=action == 'renew')
    elif action == 'probe':
        count, projects = snapshot()
        print(json.dumps({'activeThreads': count, 'projectsChecked': projects}))
    elif action == 'run':
        watch()
    elif action == 'fallback':
        fallback()
    elif action == 'status':
        state = json.loads((runtime_directory() / 'status.json').read_text())
        if time.time() - state['updatedAt'] > 60:
            state['warning'] = 'Status is stale; check atlas-activity-guard.service'
        print(json.dumps(state, indent=2))
    else:
        stamp(action)
        if action == 'idle':
            fallback()


if __name__ == '__main__':
    try:
        main()
    except (GuardError, OSError, ValueError, KeyError, TypeError, http.client.HTTPException) as exc:
        print('atlas-activity-guard: ' + (str(exc) if isinstance(exc, GuardError) else type(exc).__name__), file=sys.stderr)
        sys.exit(1)
