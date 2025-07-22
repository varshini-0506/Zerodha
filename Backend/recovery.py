import os
import time
import pyotp
from dotenv import load_dotenv
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from kiteconnect import KiteConnect
from supabase import create_client, Client
from webdriver_manager.chrome import ChromeDriverManager
from selenium.common.exceptions import StaleElementReferenceException
from datetime import datetime

# Load environment variables
load_dotenv()
USER_ID = os.getenv("KITE_USERNAME")
PASSWORD = os.getenv("KITE_PASSWORD")
TOTP_SECRET = os.getenv("TOTP_SECRET")
API_KEY = os.getenv("KITE_API_KEY")
API_SECRET = os.getenv("KITE_API_SECRET")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Supabase setup
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Selenium Chrome setup
opts = Options()
opts.add_argument("--start-maximized")
opts.add_argument("--disable-blink-features=AutomationControlled")
opts.add_experimental_option("excludeSwitches", ["enable-automation"])
opts.add_experimental_option("useAutomationExtension", False)

driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=opts)
wait = WebDriverWait(driver, 30)

try:
    # Step 1: Navigate to Zerodha login
    login_url = f"https://kite.zerodha.com/connect/login?v=3&api_key={API_KEY}"
    driver.get(login_url)

    # Step 2: Enter username and password
    wait.until(EC.presence_of_element_located((By.ID, "userid"))).send_keys(USER_ID)
    driver.find_element(By.ID, "password").send_keys(PASSWORD)
    driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()

    # Step 3: Generate TOTP and submit
    totp = pyotp.TOTP(TOTP_SECRET).now()
    for attempt in range(2):  # Try twice
        try:
            ext_totp_field = wait.until(EC.element_to_be_clickable((By.ID, "userid")))
            print("Found External TOTP field (id='userid'), clicking and entering TOTP...")
            ext_totp_field.click()
            time.sleep(0.2)
            ext_totp_field.clear()
            ext_totp_field.send_keys(totp)
            break  # Success, exit loop
        except StaleElementReferenceException:
            print("Stale element reference, retrying...")
            if attempt == 1:
                raise
        except Exception as e:
            print("❌ Could not interact with External TOTP field:", e)
            raise

    driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()

    # Step 4: Wait for redirect and get request_token
    wait.until(lambda d: "request_token=" in d.current_url)
    request_token = driver.current_url.split("request_token=")[-1].split("&")[0]
    print("✅ Request token:", request_token)

    # Step 5: Exchange request_token for access_token using KiteConnect
    kite = KiteConnect(api_key=API_KEY)
    data = kite.generate_session(request_token, api_secret=API_SECRET)
    access_token = data["access_token"]
    print("✅ Access token:", access_token)

    # Step 6: Store in Supabase
    response = supabase.table("api_tokens").upsert({
        "service": "zerodha",
        "access_token": access_token,
        "created_at": datetime.now().isoformat()
    }, on_conflict="service").execute()
    print("✅ Saved to Supabase:", response.data)

except Exception as e:
    print("❌ Error:", e)

finally:
    time.sleep(2)
    driver.quit()
