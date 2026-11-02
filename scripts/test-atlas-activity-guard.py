#!/usr/bin/env python3
"""Policy and MCP transport tests; never request a real suspend."""
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('guard', Path(__file__).with_name('atlas-activity-guard.py'))
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class PolicyTests(unittest.TestCase):
    def test_cloud_work_is_busy_without_cpu_or_recent_output(self):
        self.assertFalse(guard.eligible(10000, 0, 0, True, 1, None))

    def test_thirty_minutes_after_work_ends(self):
        self.assertFalse(guard.eligible(1899, 100, 0, True, 0, None))
        self.assertTrue(guard.eligible(1900, 100, 0, True, 0, None))

    def test_errors_input_and_wake_prevent_sleep(self):
        self.assertTrue(guard.eligible(10000, 9999, 0, True, None, 'HTTP 401'))
        self.assertFalse(guard.eligible(10000, 0, 9999, True, None, 'HTTP 401'))
        self.assertFalse(guard.eligible(10000, 0, 0, False, 0, None))
        self.assertFalse(guard.eligible(10000, 0, 9999, True, 0, None))

    def test_monitor_failure_restores_normal_idle_suspend(self):
        self.assertTrue(guard.fallback_needed(10000, 0, True, None, 100))
        self.assertTrue(guard.fallback_needed(10000, 0, True, {'updatedAt': 0}, 100))
        self.assertTrue(guard.fallback_needed(10000, 0, True, {'updatedAt': 99, 'error': 'HTTP 401'}, 100))
        self.assertFalse(guard.fallback_needed(10000, 0, True, {'updatedAt': 99, 'error': None}, 100))
        self.assertFalse(guard.fallback_needed(10000, 0, False, None, 100))
        self.assertFalse(guard.fallback_needed(10000, 9999, True, None, 100))

    def test_fallback_can_suspend_after_monitor_stops_without_waiting_for_input(self):
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {'XDG_RUNTIME_DIR': tmp}):
            directory = guard.runtime_directory()
            guard.stamp('idle')
            guard.write_json(directory / 'status.json', {'updatedAt': 0, 'activeThreads': 1})
            with patch.object(guard, 'suspend') as sleep, patch.object(guard.time, 'monotonic', return_value=10000):
                guard.fallback()
                sleep.assert_called_once()
                # A second fallback after wake must not instantly suspend again.
                guard.fallback()
                sleep.assert_called_once()

    def test_events_and_corrupt_timestamps(self):
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {'XDG_RUNTIME_DIR': tmp}):
            directory = guard.runtime_directory()
            guard.stamp('idle')
            self.assertTrue((directory / 'desktop-idle').exists())
            guard.stamp('wake')
            self.assertTrue((directory / 'desktop-idle').exists())
            self.assertGreater(guard.last_input_at(directory, 0), 0)
            guard.stamp('active')
            self.assertFalse((directory / 'desktop-idle').exists())
            (directory / 'last-input.json').write_text('NaN')
            self.assertEqual(guard.last_input_at(directory, 123), 123)

    def test_state_files_are_private(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'token'
            guard.write_json(path, 'test-only')
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)


class McpTests(unittest.TestCase):
    def test_all_projects_pagination_and_subagents(self):
        client = guard.Mcp('test-only')
        calls = []
        def tool(name, args):
            calls.append((name, args))
            if name == 't3_project_list':
                if 'cursor' not in args:
                    return {'projects': [{'id': 'a'}], 'nextCursor': 100}
                return {'projects': [{'id': 'b'}], 'nextCursor': None}
            self.assertTrue(args['includeSubagents'])
            self.assertEqual(args['statuses'], guard.ACTIVE)
            return {'total': 2 if args['projectId'] == 'b' else 0, 'threads': []}
        with patch.object(client, 'tool', side_effect=tool):
            self.assertEqual(client.active_count(), (2, 2))
        self.assertEqual(len(calls), 4)

    def test_bad_status_result_is_not_mistaken_for_idle(self):
        client = guard.Mcp('test-only')
        with patch.object(client, 'tool', side_effect=[{'projects': [{'id': 'a'}]}, {'threads': []}]):
            with self.assertRaises(guard.GuardError):
                client.active_count()

    def test_sse_notifications_before_rpc_result(self):
        response = io.BytesIO(b'event: message\ndata: {"jsonrpc":"2.0","method":"notice"}\n\ndata: {"jsonrpc":"2.0","id":2,"result":{"ok":true}}\n\n')
        self.assertEqual(guard.sse_response(response, 2)['result'], {'ok': True})

    def test_tool_errors_do_not_expose_response_or_report_idle(self):
        client = guard.Mcp('test-only')
        with patch.object(client, 'request', return_value={'isError': True, 'content': [{'type': 'text', 'text': 'PRIVATE'}]}):
            with self.assertRaises(guard.GuardError) as error:
                client.tool('t3_thread_list', {})
            self.assertNotIn('PRIVATE', str(error.exception))

    def test_protocol_and_session_headers(self):
        class Response:
            status = 200
            def getheader(self, key, default=None):
                return {'Content-Type': 'application/json', 'Mcp-Session-Id': 'session-test'}.get(key, default)
            def read(self, size):
                return b'{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-06-18"}}'
        class Connection:
            def __init__(self, *args, **kwargs): pass
            def request(self, *args): self.args = args; calls.append(args)
            def getresponse(self): return Response()
            def close(self): pass
        calls = []
        client = guard.Mcp('test-only')
        with patch.object(guard.http.client, 'HTTPConnection', Connection):
            result = client.request('initialize', {})
        self.assertEqual(result['protocolVersion'], '2025-06-18')
        self.assertEqual(client.session, 'session-test')
        self.assertEqual(calls[0][3]['Authorization'], 'Bearer test-only')
        self.assertIn('text/event-stream', calls[0][3]['Accept'])


if __name__ == '__main__':
    unittest.main()
