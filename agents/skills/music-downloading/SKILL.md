---
name: music-downloading
description: Download a music track from a YouTube URL as a high-quality MP3, clean its ID3 metadata with Kid3, and add it to this user's MPD/rmpc library. Use when the user provides a YouTube music link or asks to download, tag, or add a YouTube track to rmpc.
---

# Music downloading

Use `/home/neo/Music` as the destination. MPD is configured to scan this directory; do not use `/home/neo/Musics`.

## Download

1. Confirm `yt-dlp`, `ffmpeg`, `kid3-cli`, and `rmpc` are available.
2. Run `scripts/download-youtube-music.sh --chrome-cookies URL`. This uses local Chrome YouTube session cookies to avoid YouTube's recurring unauthenticated HTTP 403 response while requesting the best available audio, converting it to highest-quality VBR MP3 (`--audio-quality 0`), and embedding YouTube metadata and the cover thumbnail.
3. Use local Chrome cookies only to authenticate the requested download; never print, copy, or retain them. If Chrome cookies are unavailable, offer an unauthenticated attempt with `scripts/download-youtube-music.sh URL`, noting that YouTube may return HTTP 403.

## Tag and verify

1. Inspect the downloaded file with `kid3-cli -c 'get all 2' FILE`.
2. Resolve canonical title, artist, album, album artist, and year from the official release or an authoritative music database. Do not use a YouTube upload title or channel name as song metadata.
3. Write ID3v2 tags and save, quoting multiword frame names:

   ```sh
   kid3-cli \
     -c 'set title "TITLE" 2' \
     -c 'set artist "ARTIST" 2' \
     -c 'set album "ALBUM" 2' \
     -c 'set "album artist" "ARTIST" 2' \
     -c 'set date "YEAR" 2' \
     -c save FILE
   ```

4. Re-read those fields with Kid3 to verify them.
5. Run `rmpc update`, then verify the MPD database contains the file with `rmpc listall`. If the environment sandbox blocks access to the local MPD socket, rerun the rmpc command with the required local-service permission.

Report the final path, MP3 bitrate, and normalized tags.
