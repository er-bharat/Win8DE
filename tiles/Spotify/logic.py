import os
import subprocess
import requests
import time
from urllib.parse import unquote

THUMBNAIL_FILE = "art.jpg"
UPDATE_INTERVAL = 10  # seconds between checks


def get_current_art_url():
    """Get the current track's art URL using playerctl."""
    try:
        result = subprocess.run(
            ["playerctl", "metadata", "mpris:artUrl"],
            capture_output=True,
            text=True,
            check=True
        )
        url = result.stdout.strip()
        return url if url else None
    except subprocess.CalledProcessError:
        return None


def download_thumbnail(url):
    """Download image from URL or copy local file."""
    if url.startswith("file://"):
        # Decode URL-encoded path (%20 -> space)
        local_path = unquote(url[7:])

        # Ignore transient / invalid paths
        if not local_path or local_path == "/":
            return

        if os.path.isfile(local_path):
            with open(local_path, "rb") as src, open(THUMBNAIL_FILE, "wb") as dst:
                dst.write(src.read())
            print("Thumbnail copied from local file.")
        else:
            # Silently ignore transient metadata glitches
            pass

    else:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                with open(THUMBNAIL_FILE, "wb") as f:
                    f.write(response.content)
                print("Thumbnail downloaded from URL.")
        except Exception:
            pass


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
