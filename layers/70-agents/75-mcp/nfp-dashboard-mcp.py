#!/usr/bin/env python3
"""
NFP Dashboard MCP Server (stdio)
Read-only declarative contract, service inventory, and fleet telemetry provider.
"""

import json
import os
import sys
import urllib.error
import urllib.request

DASHBOARD_API = os.environ.get("NFP_DASHBOARD_URL", "http://127.0.0.1:3007")

TOOLS = [
    {
        "name": "list_dashboard_services",
        "description": "List all enabled user-facing dashboard services and their canonical contracts.",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "get_dashboard_service",
        "description": "Get details for a specific dashboard service by ID.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "id": {"type": "string", "description": "Service identifier (e.g. jellyfin, sonarr, adguard)"}
            },
            "required": ["id"],
        },
    },
    {
        "name": "get_dashboard_health",
        "description": "Get real-time healthcheck status for a dashboard service.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "id": {"type": "string", "description": "Service identifier"}
            },
            "required": ["id"],
        },
    },
    {
        "name": "get_dashboard_metrics",
        "description": "Get parsed real-time telemetry metrics and bounty figure for a dashboard service.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "id": {"type": "string", "description": "Service identifier"}
            },
            "required": ["id"],
        },
    },
    {
        "name": "list_fleet_hosts",
        "description": "List all machines in the Grand Line fleet (z0r0, luffy, nami).",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "get_fleet_host_vitals",
        "description": "Get high-definition telemetry vitals for a fleet host from Netdata (CPU, RAM, Disk, Net, Load, Uptime).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "host_id": {"type": "string", "description": "Host identifier (z0r0, luffy, or nami)"}
            },
            "required": ["host_id"],
        },
    },
    {
        "name": "list_dashboard_categories",
        "description": "List all active dashboard crew categories and their service counts.",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "validate_dashboard_contracts",
        "description": "Validate all evaluated contracts against NFP Single Source of Truth invariants.",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "list_observability_targets",
        "description": "List observability telemetry targets (Prometheus scrape jobs, Netdata instances, Loki logs destinations).",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "get_observability_coverage",
        "description": "Get comprehensive host and service observability coverage matrix.",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
]


def fetch_json(endpoint, timeout=2.5):
    try:
        url = f"{DASHBOARD_API.rstrip('/')}{endpoint}"
        req = urllib.request.Request(url, headers={"User-Agent": "NFP-Dashboard-MCP/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        return {"error": f"Failed to query dashboard daemon at {endpoint}: {str(e)}"}


def handle_list_dashboard_services(args):
    data = fetch_json("/api/config")
    if "error" in data:
        return data
    widget_map = data.get("widget_map", {})
    services = []
    for sid, svc in widget_map.items():
        services.append({
            "id": sid,
            "name": svc.get("name"),
            "category": svc.get("category"),
            "host": svc.get("host"),
            "url": svc.get("url"),
            "role": svc.get("onePieceSub"),
            "satellite": svc.get("satellite"),
            "metricMode": svc.get("metric", {}).get("mode", "health-only"),
        })
    return {"total": len(services), "services": sorted(services, key=lambda s: s["id"])}


def handle_get_dashboard_service(args):
    sid = args.get("id")
    if not sid:
        return {"error": "Missing service id"}
    data = fetch_json("/api/config")
    if "error" in data:
        return data
    widget_map = data.get("widget_map", {})
    svc = widget_map.get(sid)
    if not svc:
        return {"error": f"Service '{sid}' not found in active contracts"}
    return {
        "id": sid,
        "name": svc.get("name"),
        "category": svc.get("category"),
        "host": svc.get("host"),
        "url": svc.get("url"),
        "role": svc.get("onePieceSub"),
        "satellite": svc.get("satellite"),
        "satelliteName": svc.get("satelliteName"),
        "logs": svc.get("logs", {}),
        "metric": svc.get("metric", {}),
    }


def handle_get_dashboard_health(args):
    sid = args.get("id")
    if not sid:
        return {"error": "Missing service id"}
    data = fetch_json(f"/api/widget/{sid}")
    if "error" in data and "health" not in data:
        return data
    return {
        "id": sid,
        "status": data.get("status", "unknown"),
        "health": data.get("health", {}),
        "updatedAt": data.get("updatedAt"),
    }


def handle_get_dashboard_metrics(args):
    sid = args.get("id")
    if not sid:
        return {"error": "Missing service id"}
    data = fetch_json(f"/api/widget/{sid}")
    if "error" in data and "metric" not in data:
        return data
    return {
        "id": sid,
        "status": data.get("status"),
        "bountyStat": data.get("bountyStat"),
        "metric": data.get("metric", {}),
        "updatedAt": data.get("updatedAt"),
    }


def handle_list_fleet_hosts(args):
    return {
        "hosts": [
            {"id": "z0r0", "name": "z0r0 (Workstation / AI Server)", "tailnet": "z0r0.nfp.nix", "role": "primary-workstation"},
            {"id": "luffy", "name": "luffy (Homelab Server / Control Plane)", "tailnet": "luffy.nfp.nix", "role": "homelab-server"},
            {"id": "nami", "name": "nami (Mini Edge / Ingress)", "tailnet": "nami.nfp.nix", "role": "edge-mini"},
        ]
    }


def handle_get_fleet_host_vitals(args):
    hid = args.get("host_id")
    if not hid:
        return {"error": "Missing host_id"}
    data = fetch_json("/api/fleet/vitals")
    if "error" in data:
        return data
    hosts = data.get("hosts", [])
    for h in hosts:
        if h.get("id") == hid:
            return {"host": h, "updatedAt": data.get("updatedAt")}
    return {"error": f"Host '{hid}' not found in fleet vitals (available: z0r0, luffy, nami)"}


def handle_list_dashboard_categories(args):
    data = fetch_json("/api/config")
    if "error" in data:
        return data
    cats = data.get("categories", [])
    result = []
    for c in cats:
        result.append({
            "id": c.get("id"),
            "title": c.get("title"),
            "subtitle": c.get("subtitle"),
            "crewMember": c.get("crewMember"),
            "serviceCount": len(c.get("services", [])),
            "services": [s.get("id") for s in c.get("services", [])],
        })
    return {"total": len(result), "categories": result}


def handle_validate_dashboard_contracts(args):
    data = fetch_json("/api/config")
    if "error" in data:
        return data
    widget_map = data.get("widget_map", {})
    errors = []
    seen_ids = set()

    for sid, svc in widget_map.items():
        if sid in seen_ids:
            errors.append(f"Duplicate contract id: {sid}")
        seen_ids.add(sid)

        url = svc.get("url", "")
        if ".local" in url:
            errors.append(f"Forbidden .local domain in contract '{sid}': {url}")
        if "127.0.0.1" in url or "localhost" in url:
            errors.append(f"Forbidden localhost destination in user-facing card '{sid}': {url}")

    return {
        "valid": len(errors) == 0,
        "totalContracts": len(widget_map),
        "errors": errors,
    }


def handle_list_observability_targets(args):
    return {
        "prometheus": {
            "url": "http://luffy.nfp.nix:9090",
            "scrapeJobs": ["node-exporter", "netdata", "caddy", "adguard", "synapse"],
        },
        "loki": {
            "url": "http://luffy.nfp.nix:3100",
            "exploreUrl": "http://luffy.nfp.nix:3000/explore",
            "shipper": "Grafana Alloy",
        },
        "grafana": {
            "url": "http://luffy.nfp.nix:3000",
            "dashboards": ["Fleet Overview", "Services Health", "Hermes Activity", "Logs Explorer"],
        },
        "netdata": {
            "z0r0": "http://z0r0.nfp.nix:19999",
            "luffy": "http://luffy.nfp.nix:19999",
            "sanji": "http://sanji.nfp.nix:19999",
        },
        "alertmanager": {
            "url": "http://luffy.nfp.nix:9093",
            "receiver": "ntfy (http://luffy.nfp.nix:8080)",
        },
    }


def handle_get_observability_coverage(args):
    return {
        "hostCoverage": [
            {"host": "z0r0", "nodeExporter": True, "netdata": True, "glances": False, "alloy": True, "loki": True, "promScrape": True, "status": "nominal"},
            {"host": "luffy", "nodeExporter": True, "netdata": True, "glances": False, "alloy": True, "loki": True, "promScrape": True, "status": "nominal"},
            {"host": "sanji", "nodeExporter": True, "netdata": True, "glances": False, "alloy": True, "loki": True, "promScrape": True, "status": "nominal"},
        ],
        "glancesPolicy": "Glances permanently disabled and removed across all hosts. Netdata is sole real-time vitals authority.",
        "tracingAuthority": "Langfuse for LLM/agent spans. Tempo recommended for non-LLM OTLP tracing in future ADR.",
    }


TOOL_HANDLERS = {
    "list_dashboard_services": handle_list_dashboard_services,
    "get_dashboard_service": handle_get_dashboard_service,
    "get_dashboard_health": handle_get_dashboard_health,
    "get_dashboard_metrics": handle_get_dashboard_metrics,
    "list_fleet_hosts": handle_list_fleet_hosts,
    "get_fleet_host_vitals": handle_get_fleet_host_vitals,
    "list_dashboard_categories": handle_list_dashboard_categories,
    "validate_dashboard_contracts": handle_validate_dashboard_contracts,
    "list_observability_targets": handle_list_observability_targets,
    "get_observability_coverage": handle_get_observability_coverage,
}


def send_response(req_id, result=None, error=None):
    resp = {"jsonrpc": "2.0", "id": req_id}
    if error is not None:
        resp["error"] = error
    else:
        resp["result"] = result
    line = json.dumps(resp) + "\n"
    sys.stdout.write(line)
    sys.stdout.flush()


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except Exception:
            continue

        req_id = req.get("id")
        method = req.get("method")
        params = req.get("params", {})

        if method == "initialize":
            send_response(
                req_id,
                {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "nfp-dashboard-mcp", "version": "1.0.0"},
                },
            )
        elif method == "notifications/initialized":
            pass
        elif method == "tools/list":
            send_response(req_id, {"tools": TOOLS})
        elif method == "tools/call":
            tool_name = params.get("name")
            tool_args = params.get("arguments", {})
            handler = TOOL_HANDLERS.get(tool_name)
            if not handler:
                send_response(
                    req_id,
                    error={"code": -32601, "message": f"Method/Tool '{tool_name}' not found"},
                )
            else:
                out = handler(tool_args)
                send_response(
                    req_id,
                    {
                        "content": [
                            {"type": "text", "text": json.dumps(out, indent=2)}
                        ]
                    },
                )
        else:
            if req_id is not None:
                send_response(
                    req_id,
                    error={"code": -32601, "message": f"Unhandled method '{method}'"},
                )


if __name__ == "__main__":
    main()
