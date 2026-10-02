# ---------------------------------------------
# BASE IMAGE — swap this line for your org's
# approved/hardened image if required.
# Must be Debian/Ubuntu-based (apt-get compatible).
# ---------------------------------------------
# Verified 2026-10-02; multi-platform index. Refresh this pin during patch reviews.
FROM debian:bookworm-slim@sha256:3783cc01769c7b2b1b83a5c5ad96c815348e28ed7da68e2e3687004faa906251

# Chromium runs with its real user-namespace sandbox. The runtime must grant
# only CAP_SYS_ADMIN (see docker-compose.yml and README Security section);
# --no-sandbox is intentionally not used.

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Upgrade inherited packages too: installing browser dependencies alone can leave
# older base-image packages untouched. Rebuild with --pull --no-cache for patches.
# Omit optional desktop recommendations; retain all required runtime dependencies.
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    chromium \
    openbox \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    supervisor \
    fonts-liberation \
    dbus-x11 \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY viewer/ /usr/share/novnc/viewer/
RUN cp /usr/share/novnc/viewer/index.html /usr/share/novnc/index.html

RUN useradd -m -s /bin/bash sandboxuser
USER sandboxuser
WORKDIR /home/sandboxuser
RUN mkdir -p /home/sandboxuser/chrome-profile

COPY --chown=sandboxuser:sandboxuser supervisord.conf /home/sandboxuser/supervisord.conf

EXPOSE 9222 5900 6080

HEALTHCHECK --interval=15s --timeout=5s --retries=5 \
  CMD curl -f http://localhost:9222/json/version || exit 1

CMD ["supervisord", "-c", "/home/sandboxuser/supervisord.conf"]
