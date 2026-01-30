import os
import subprocess
import requests
from urllib.parse import unquote

THUMBNAIL_FILE = "art.jpg"


def download_thumbnail(url):
    """Download image from URL or copy local file."""
    if url.startswith("file://"):
        local_path = unquote(url[7:])

        if local_path and local_path != "/" and os.path.isfile(local_path):
            with open(local_path, "rb") as src, open(THUMBNAIL_FILE, "wb") as dst:
                dst.write(src.read())
            print("Thumbnail copied from local file.")
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
        print("Thumbnail removed.")


def main():
    last_art_url = None

    process = subprocess.Popen(
        ["playerctl", "--follow", "metadata", "mpris:artUrl"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True
    )

    for line in process.stdout:
        art_url = line.strip()

        # playerctl prints an empty line when nothing is playing
        if not art_url:
            if last_art_url is not None:
                remove_thumbnail()
                last_art_url = None
            continue

        if art_url != last_art_url:
            download_thumbnail(art_url)
            last_art_url = art_url


if __name__ == "__main__":
    main()
