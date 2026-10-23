#!/usr/bin/env python3
"""
Offline Unit Tests for Jev Tier Router (layers/70-agents/70-jev/jev-router-proxy.py)
Zero network calls required.
"""

import asyncio
import importlib.util
import json
import os
import unittest

PROXY_PATH = os.path.join(os.path.dirname(__file__), "../jev-router-proxy.py")
spec = importlib.util.spec_from_file_location("jev_router_proxy", PROXY_PATH)
jev = importlib.util.module_from_spec(spec)
spec.loader.exec_module(jev)


class TestJevTierRouter(unittest.TestCase):
    def setUp(self):
        jev.SESSION_FAILURES.clear()
        jev.METRICS["requests_total"].clear()
        jev.METRICS["escalations_total"].clear()
        jev.METRICS["fail_open_total"] = 0
        jev.METRICS["sensitive_guarded_total"] = 0
        jev.METRICS["destructive_flagged_total"] = 0

    def test_never_synthesizes_answer_for_classification(self):
        """Jev must never synthesize an answer, even for pure classification prompts."""
        self.assertFalse(hasattr(jev, "build_direct_jev_response"))
        payload = {
            "messages": [{"role": "user", "content": "Classify this email as spam or invoice."}]
        }
        called_upstream = False

        async def mock_upstream(mod_payload, decision):
            nonlocal called_upstream
            called_upstream = True
            return 200, {
                "id": "chatcmpl-upstream-1",
                "choices": [{"index": 0, "message": {"role": "assistant", "content": "invoice"}, "finish_reason": "stop"}],
            }

        async def mock_engine(_prompt):
            return {"status": "ok"}, False

        status, resp, decision = asyncio.run(
            jev.execute_with_escalation(payload, {}, mock_upstream, engine_decide=mock_engine)
        )
        self.assertTrue(called_upstream)
        self.assertEqual(status, 200)
        self.assertEqual(resp["id"], "chatcmpl-upstream-1")
        self.assertIn(decision["tier"], jev.TIER_ORDER)

    def test_voice_consumer_routes_to_voice_fast_and_caps_max_tokens(self):
        payload = {"messages": [{"role": "user", "content": "What time is it in Tokyo?"}]}
        headers = {"X-Consumer-Username": "hermes-voice"}
        decision = jev.select_tier_and_model(payload, headers)
        self.assertEqual(decision["tier"], "voice-fast")
        self.assertEqual(decision["combo"], "Penny-Pincher")
        mod = jev.apply_decision_to_payload(payload, decision)
        self.assertEqual(mod["model"], "Penny-Pincher")
        self.assertEqual(mod["max_tokens"], 200)

    def test_short_general_turn_routes_to_free_first(self):
        payload = {"messages": [{"role": "user", "content": "Hello, how are you today?"}]}
        decision = jev.select_tier_and_model(payload, {}, session_failures=0, fail_open=False)
        self.assertEqual(decision["tier"], "free-first")
        self.assertEqual(decision["combo"], "Free")

    def test_tool_bearing_turn_never_routes_to_free_first(self):
        payload = {
            "messages": [{"role": "user", "content": "Check git status"}],
            "tools": [
                {
                    "type": "function",
                    "function": {
                        "name": "git_status",
                        "parameters": {"type": "object", "properties": {"repo": {"type": "string"}}, "required": ["repo"]},
                    },
                }
            ],
        }
        decision = jev.select_tier_and_model(payload, {}, session_failures=0, fail_open=False)
        self.assertTrue(decision["has_tools"])
        self.assertEqual(decision["tier"], "cascade-balanced")
        self.assertEqual(decision["combo"], "Coding")

    def test_destructive_tool_context_requires_validated_retry_or_approval(self):
        payload = {
            "messages": [{"role": "user", "content": "Run rm -rf /tmp/build and deploy with clan machines update"}],
            "tools": [
                {
                    "type": "function",
                    "function": {
                        "name": "run_shell",
                        "description": "Execute shell command or rm -rf",
                        "parameters": {"type": "object", "properties": {"cmd": {"type": "string"}}, "required": ["cmd"]},
                    },
                }
            ],
        }
        decision = jev.select_tier_and_model(payload, {}, session_failures=0, fail_open=False)
        self.assertTrue(decision["destructive_context"])
        self.assertEqual(decision["destructive_policy"], "validated_retry_required")
        self.assertIn(decision["tier"], ("cascade-balanced", "frontier"))

        # Verify unsafe root wipe tool call is rejected by output validator when unapproved
        unsafe_resp = {
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": None,
                        "tool_calls": [
                            {
                                "id": "call_1",
                                "type": "function",
                                "function": {"name": "run_shell", "arguments": json.dumps({"cmd": "rm -rf /"})},
                            }
                        ],
                    },
                    "finish_reason": "tool_calls",
                }
            ]
        }
        valid, reason = jev.validate_response_output(unsafe_resp, payload, destructive_context=True, human_approved=False)
        self.assertFalse(valid)
        self.assertIn("blocked_destructive_call", reason)

    def test_sensitive_prompt_routes_only_to_trusted_model(self):
        payload = {
            "model": "felo/gpt-5-6-luna",
            "messages": [
                {
                    "role": "user",
                    "content": "Here is my AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ and password=supersecret",
                }
            ],
        }
        decision = jev.select_tier_and_model(payload, {}, session_failures=0, fail_open=False)
        self.assertTrue(decision["sensitive_guarded"])
        self.assertEqual(decision["selected_model"], jev.TRUSTED_SENSITIVE_MODEL)
        self.assertNotIn("felo", decision["selected_model"])

    def test_output_validation_and_retry_same_tier_then_escalate_one_tier(self):
        """
        Verify output-based escalation:
        - Attempt 1 (free-first): returns truncated / invalid JSON tool call -> fails validation
        - Attempt 2 (retry ONCE at same tier free-first): returns repetitive loop -> fails validation
        - Attempt 3 (escalate ONE tier to cascade-balanced): returns valid response -> succeeds!
        """
        payload = {"messages": [{"role": "user", "content": "Say hello briefly."}]}
        seen_models = []

        async def mock_upstream(mod_payload, decision):
            seen_models.append((decision["tier"], mod_payload["model"]))
            if len(seen_models) == 1:
                # Attempt 1: empty content
                return 200, {"choices": [{"index": 0, "message": {"role": "assistant", "content": "   "}, "finish_reason": "stop"}]}
            elif len(seen_models) == 2:
                # Attempt 2 (same tier): repetitive token loop
                loop_str = "repeat this exact thirty char! " * 8
                return 200, {"choices": [{"index": 0, "message": {"role": "assistant", "content": loop_str}, "finish_reason": "stop"}]}
            else:
                # Attempt 3 (escalated tier): valid response
                return 200, {"choices": [{"index": 0, "message": {"role": "assistant", "content": "Hello from escalated tier!"}, "finish_reason": "stop"}]}

        async def mock_engine(_prompt):
            return {"status": "ok"}, False

        status, resp, decision = asyncio.run(
            jev.execute_with_escalation(payload, {"X-Session-Id": "test-sess-1"}, mock_upstream, engine_decide=mock_engine)
        )
        self.assertEqual(status, 200)
        self.assertEqual(decision["attempts"], 3)
        self.assertTrue(decision["escalated"])
        self.assertEqual(seen_models[0], ("free-first", "Free"))
        self.assertEqual(seen_models[1], ("free-first", "Free"))
        self.assertEqual(seen_models[2], ("cascade-balanced", "Coding"))

    def test_tool_call_schema_validation_triggers_retry(self):
        payload = {
            "messages": [{"role": "user", "content": "Read file /etc/hosts"}],
            "tools": [
                {
                    "type": "function",
                    "function": {
                        "name": "read_file",
                        "parameters": {
                            "type": "object",
                            "properties": {"path": {"type": "string"}, "max_lines": {"type": "integer"}},
                            "required": ["path"],
                        },
                    },
                }
            ],
        }
        # Missing required 'path'
        bad_resp_1 = {
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "tool_calls": [{"id": "1", "type": "function", "function": {"name": "read_file", "arguments": '{"max_lines": 10}'}}],
                    },
                    "finish_reason": "tool_calls",
                }
            ]
        }
        ok, reason = jev.validate_response_output(bad_resp_1, payload)
        self.assertFalse(ok)
        self.assertEqual(reason, "missing_required_tool_arg:read_file.path")

        # Wrong type for 'max_lines'
        bad_resp_2 = {
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "tool_calls": [
                            {"id": "1", "type": "function", "function": {"name": "read_file", "arguments": '{"path": "/etc/hosts", "max_lines": "ten"}'}}
                        ],
                    },
                    "finish_reason": "tool_calls",
                }
            ]
        }
        ok2, reason2 = jev.validate_response_output(bad_resp_2, payload)
        self.assertFalse(ok2)
        self.assertEqual(reason2, "invalid_arg_type:read_file.max_lines:expected_integer")

        # Valid tool call
        good_resp = {
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "tool_calls": [
                            {"id": "1", "type": "function", "function": {"name": "read_file", "arguments": '{"path": "/etc/hosts", "max_lines": 10}'}}
                        ],
                    },
                    "finish_reason": "tool_calls",
                }
            ]
        }
        ok3, reason3 = jev.validate_response_output(good_resp, payload)
        self.assertTrue(ok3)
        self.assertIsNone(reason3)

    def test_fail_open_when_jev_engine_exceeds_50ms(self):
        """If Jev engine exceeds 50ms or is down, query_jev_engine fails open to default combo."""
        orig_url = jev.JEV_ENGINE_URL
        try:
            # Point to unroutable loopback port so it fails/times out quickly
            jev.JEV_ENGINE_URL = "http://127.0.0.1:19999"
            res, fail_open = asyncio.run(jev.query_jev_engine("Hello world", timeout_ms=20.0))
            self.assertIsNone(res)
            self.assertTrue(fail_open)
            decision = jev.select_tier_and_model(
                {"messages": [{"role": "user", "content": "Hello world"}]},
                {},
                fail_open=fail_open,
            )
            self.assertTrue(decision["fail_open"])
            self.assertEqual(decision["tier"], "cascade-balanced")
            self.assertEqual(decision["combo"], "Coding")
        finally:
            jev.JEV_ENGINE_URL = orig_url


if __name__ == "__main__":
    unittest.main(verbosity=2)
