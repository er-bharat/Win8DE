import os
import subprocess
import requests
import time

THUMBNAIL_FILE = "art.jpg"  # Updated filename
UPDATE_INTERVAL = 2  # seconds between checks

def get_current_art_url():
    """Get the current track's art URL using playerctl."""
    try:
        result = subprocess.run(
            ["playerctl", "metadata", "mpris:artUrl"],
            capture_output=True, text=True, check=True
        )
        url = result.stdout.strip()
        if url:
            return url
    except subprocess.CalledProcessError:
        pass
    return None

def download_thumbnail(url):
    """Download image from URL or copy local file."""
    if url.startswith("file://"):
        # Local file
        local_path = url[7:]
        if os.path.exists(local_path):
            with open(THUMBNAIL_FILE, "wb") as f:
                with open(local_path, "rb") as orig:
                    f.write(orig.read())
            print("Thumbnail downloaded from local file.")
        else:
            print("Local file does not exist.")
    else:
        # URL download
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                with open(THUMBNAIL_FILE, "wb") as f:
                    f.write(response.content)
                print("Thumbnail downloaded from URL.")
            else:
                print("Failed to download thumbnail. Status:", response.status_code)
        except Exception as e:
            print("Error downloading thumbnail:", e)

def remove_thumbnail():
    if os.path.exists(THUMBNAIL_FILE):
        os.remove(THUMBNAIL_FILE)
        print("No track playing. Thumbnail removed.")

def main():
    last_art_url = None
    while True:
        art_url = get_current_art_url()
        if art_url and art_url != last_art_url:
            download_thumbnail(art_url)
            last_art_url = art_url
        elif not art_url and last_art_url is not None:
            remove_thumbnail()
            last_art_url = None
        time.sleep(UPDATE_INTERVAL)

if __name__ == "__main__":
    main()
