# NFP Optimization Task List

## 1. Proactive 24/7 Agent
- [x] Set up cron-based proactive monitoring (syncthing, routers, services)
- [x] Configure alerting via GLaDOS voice
- [x] Add persistent memory for user preferences and environment facts

## 2. JEV Models for Email Sorting
- [x] Check jev-router-proxy.py is running (port 20127)
- [x] Verify jev engine on port 20130
- [x] Configure email sorting pipeline
- [x] Verify langfuse traces are being collected

## 3. LLM/API Routers Optimization
- [x] Verify Kong gateway (port 8090) is routing to all 4 upstreams (extreme-router, omniroute, litellm, manifest)
- [x] Check extremerouter creds can be transferred to omniroute
- [x] Verify model parsing and provider calls flow through
- [x] Confirm langfuse traces are captured

## 4. GLaDOS Voice Alerts
- [x] Configure GLaDOS voice for proactive alerts
- [x] Test voice interaction

## 5. Screen Locking (sanji plugged in)
- [x] Disable screen lock when on AC power
