#!/usr/bin/env python3
"""
telemetry_client.py — Standard OpenTelemetry Python Helper for NFP Agents

Emits OTLP/HTTP traces, metrics, and logs to the local or fleet OpenTelemetry
Collector daemon (default: http://127.0.0.1:4318).
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error
from typing import Any, Dict, Optional


class SpanContext:
    def __init__(self, client: "TelemetryClient", name: str, attributes: Optional[Dict[str, Any]] = None):
        self.client = client
        self.name = name
        self.attributes = attributes or {}
        self.events = []
        self.start_time_unix_nano = int(time.time() * 1e9)
        self.end_time_unix_nano = None
        self.status_code = 1  # 1 = OK, 2 = ERROR

    def set_attribute(self, key: str, value: Any):
        self.attributes[key] = value

    def add_event(self, name: str, attributes: Optional[Dict[str, Any]] = None):
        self.events.append({
            "timeUnixNano": str(int(time.time() * 1e9)),
            "name": name,
            "attributes": [{"key": k, "value": {"stringValue": str(v)}} for k, v in (attributes or {}).items()]
        })

    def set_error(self, message: str):
        self.status_code = 2
        self.set_attribute("error.message", message)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.end_time_unix_nano = int(time.time() * 1e9)
        if exc_type is not None:
            self.set_error(str(exc_val))
        self.client._send_span(self)
        return False


class TelemetryClient:
    def __init__(
        self,
        service_name: str = "nfp-agent",
        endpoint: Optional[str] = None,
        timeout: float = 3.0
    ):
        self.service_name = service_name
        self.endpoint = endpoint or os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:4318")
        self.timeout = timeout

    def trace(self, name: str, attributes: Optional[Dict[str, Any]] = None) -> SpanContext:
        return SpanContext(self, name, attributes)

    def record_metric(self, name: str, value: float, attributes: Optional[Dict[str, Any]] = None):
        payload = {
            "resourceMetrics": [{
                "resource": {
                    "attributes": [
                        {"key": "service.name", "value": {"stringValue": self.service_name}},
                        {"key": "host.name", "value": {"stringValue": os.uname().nodename}}
                    ]
                },
                "scopeMetrics": [{
                    "scope": {"name": "nfp.telemetry.client"},
                    "metrics": [{
                        "name": name,
                        "gauge": {
                            "dataPoints": [{
                                "timeUnixNano": str(int(time.time() * 1e9)),
                                "asDouble": float(value),
                                "attributes": [{"key": k, "value": {"stringValue": str(v)}} for k, v in (attributes or {}).items()]
                            }]
                        }
                    }]
                }]
            }]
        }
        self._post("/v1/metrics", payload)

    def emit_log(self, message: str, level: str = "INFO", attributes: Optional[Dict[str, Any]] = None):
        payload = {
            "resourceLogs": [{
                "resource": {
                    "attributes": [
                        {"key": "service.name", "value": {"stringValue": self.service_name}},
                        {"key": "host.name", "value": {"stringValue": os.uname().nodename}}
                    ]
                },
                "scopeLogs": [{
                    "scope": {"name": "nfp.telemetry.client"},
                    "logRecords": [{
                        "timeUnixNano": str(int(time.time() * 1e9)),
                        "severityText": level.upper(),
                        "body": {"stringValue": message},
                        "attributes": [{"key": k, "value": {"stringValue": str(v)}} for k, v in (attributes or {}).items()]
                    }]
                }]
            }]
        }
        self._post("/v1/logs", payload)

    def _send_span(self, span: SpanContext):
        payload = {
            "resourceSpans": [{
                "resource": {
                    "attributes": [
                        {"key": "service.name", "value": {"stringValue": self.service_name}},
                        {"key": "host.name", "value": {"stringValue": os.uname().nodename}}
                    ]
                },
                "scopeSpans": [{
                    "scope": {"name": "nfp.telemetry.client"},
                    "spans": [{
                        "traceId": "1" * 32,
                        "spanId": "2" * 16,
                        "name": span.name,
                        "kind": 1,
                        "startTimeUnixNano": str(span.start_time_unix_nano),
                        "endTimeUnixNano": str(span.end_time_unix_nano or int(time.time() * 1e9)),
                        "attributes": [{"key": k, "value": {"stringValue": str(v)}} for k, v in span.attributes.items()],
                        "events": span.events,
                        "status": {"code": span.status_code}
                    }]
                }]
            }]
        }
        self._post("/v1/traces", payload)

    def _post(self, path: str, data: dict):
        url = f"{self.endpoint.rstrip('/')}{path}"
        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                pass
        except Exception:
            # Telemetry failures must remain non-fatal to calling code
            pass


if __name__ == "__main__":
    client = TelemetryClient(service_name="telemetry-test")
    with client.trace("self-test") as span:
        span.set_attribute("test.status", "executing")
        client.record_metric("telemetry_test_pings_total", 1, {"host": os.uname().nodename})
        client.emit_log("Telemetry self-test executed successfully", "INFO")
    print("Telemetry self-test finished.")
