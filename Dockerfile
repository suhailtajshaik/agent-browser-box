# ---------------------------------------------
# BASE IMAGE — swap this line for your org's
# approved/hardened image if required.
# Must be Debian/Ubuntu-based (apt-get compatible).
# ---------------------------------------------
FROM debian:bookworm-slim

# Chromium runs with its real user-namespace sandbox. The runtime must grant
# only CAP_SYS_ADMIN (see docker-compose.yml and README Security section);
# --no-sandbox is intentionally not used.

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

RUN apt-get update && apt-get install -y \
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
