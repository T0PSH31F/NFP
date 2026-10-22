# NFP Optimization Task List

## 1. Proactive 24/7 Agent
- [ ] Set up cron-based proactive monitoring (syncthing, routers, services)
- [ ] Configure alerting via GLaDOS voice
- [ ] Add persistent memory for user preferences and environment facts

## 2. JEV Models for Email Sorting
- [ ] Check jev-router-proxy.py is running (port 20127)
- [ ] Verify jev engine on port 20130
- [ ] Configure email sorting pipeline
- [ ] Verify langfuse traces are being collected

## 3. LLM/API Routers Optimization
- [ ] Verify Kong gateway (port 8090) is routing to all 4 upstreams (extreme-router, omniroute, litellm, manifest)
- [ ] Check extremerouter creds can be transferred to omniroute
- [ ] Verify model parsing and provider calls flow through
- [ ] Confirm langfuse traces are captured

## 4. GLaDOS Voice Alerts
- [ ] Configure GLaDOS voice for proactive alerts
- [ ] Test voice interaction

## 5. Screen Locking (sanji plugged in)
- [x] Disable screen lock when on AC power
