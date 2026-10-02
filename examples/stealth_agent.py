"""
Stealth AI Agent Browser Box Connector (Python)

Demonstrates:
1. Anti-detection headers and Chrome User-Agent configuration
2. Humanized action delays (100-400ms)
3. Automatic Bot-Check / CAPTCHA detection with human handoff fallback
"""

import time
import random
# pyrefly: ignore [missing-import]
from playwright.sync_api import sync_playwright

def human_delay(min_ms=100, max_ms=400):
    time.sleep(random.randint(min_ms, max_ms) / 1000.0)

def human_click(page, selector):
    human_delay(150, 350)
    page.click(selector)
    human_delay(100, 250)

def human_type(page, selector, text):
    human_delay(100, 300)
    page.focus(selector)
    for char in text:
        page.keyboard.type(char, delay=random.randint(40, 120))
    human_delay(150, 350)

def check_bot_or_captcha(page):
    selectors = [
        'iframe[src*="recaptcha"]',
        'iframe[src*="hcaptcha"]',
        'iframe[src*="turnstile"]',
        '.g-recaptcha',
        '.h-captcha',
        '#cf-please-wait',
        '#challenge-running'
    ]
    for sel in selectors:
        if page.query_selector(sel):
            return True
    return False

def handle_captcha_fallback(page, live_view_url="http://localhost:6080/"):
    if check_bot_or_captcha(page):
        print("\n⚠️ [BOT CHECK / CAPTCHA DETECTED]")
        print(f"PAUSING AGENT TASK: Please solve the CAPTCHA in the live view at: {live_view_url}")
        input("Press ENTER in this terminal once you have solved it to resume agent execution...\n")
        print("✅ Human intervention complete. Resuming agent execution...")

def main():
    print("Connecting to Agent Browser Box over CDP...")
    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp("http://localhost:9222")
        context = browser.contexts[0] if browser.contexts else browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800},
            locale="en-US",
            timezone_id="America/New_York"
        )
        page = context.pages[0] if context.pages else context.new_page()

        print("Navigating to target site...")
        response = page.goto("https://example.com")
        
        if response and response.status in (403, 429):
            print(f"HTTP {response.status} detected.")
            handle_captcha_fallback(page)

        handle_captcha_fallback(page)

        print("Page Title:", page.title())

if __name__ == "__main__":
    main()
