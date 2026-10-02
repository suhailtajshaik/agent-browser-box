# Architecture

## What this is
A sandboxed, persistent, headful Chromium browser running inside Docker,
controllable two ways:
1. Programmatically, via CDP (Chrome DevTools Protocol) — for AI agents
2. Visually, via a live VNC stream in a web page — for human login/handoff

## Why headful, not headless
Headless Chromium has no visual output to stream. Running it headful
inside a virtual display (Xvfb) lets humans watch and interact with the
exact same browser instance the agent is driving.

## Component chain
Xvfb (virtual display, :99)
  -> Chromium (renders onto :99, exposes CDP on 9222)
  -> x11vnc (captures :99, serves raw VNC on 5900)
  -> noVNC + websockify (wraps VNC as a web-viewable stream on 6080)

All four processes are supervised by `supervisord` so a crash in any one
restarts automatically without killing the others.

## Why sibling containers, not nested Docker
This sandbox is meant to run *alongside* an agent/harness container on
the same Docker network — not nested inside it. Docker-in-Docker adds
kernel-level complexity and security risk with no real benefit here.
The agent container simply connects to this one over the network via
the CDP WebSocket URL.

## Security notes
- Container runs as a non-root user
- No volume mounts into the host filesystem
- Ports bound to 127.0.0.1 only — not exposed beyond the host
- `cap_drop: ALL` — minimal Linux capabilities
- Swap the base image (top of Dockerfile) for an org-approved image
  as needed — no other changes required as long as it's apt-based

## Human login handoff flow
1. Agent navigates to a page requiring login
2. User opens `http://localhost:6080/` (or `viewer/index.html`), which streams the live browser via noVNC
3. User types credentials directly into the live view — never into the
   agent or backend
4. User clicks "I'm logged in", which should call your own
   `/api/login-complete` endpoint
5. Agent resumes driving the *same* browser instance — session cookies
   persist automatically since nothing restarted
