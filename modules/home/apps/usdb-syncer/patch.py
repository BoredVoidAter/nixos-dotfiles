import base64
import csv
import hashlib
import pathlib
import sys

root = pathlib.Path(sys.argv[1])


def patch_file(rel: str, replacements: list[tuple[str, str]]) -> None:
    p = root / rel
    text = p.read_text(encoding="utf-8")
    for old, new in replacements:
        assert old in text, f"Pattern not found in {rel}:\n{old}"
        text = text.replace(old, new, 1)
    p.write_text(text, encoding="utf-8")


# 1. Expand SongId range and add usdb.eu helpers
patch_file(
    "usdb_syncer/__init__.py",
    [
        (
            "        if value not in range(100_000):\n            raise errors.SongIdError(value)",
            "        if value not in range(100_000) and value not in range(1_000_000, 2_000_000):\n"
            "            raise errors.SongIdError(value)",
        ),
        (
            "    def usdb_gettxt_url(self) -> str:\n"
            "        return f\"{Usdb.GETTXT_URL}{self:d}\"\n\n"
            "    def usdb_detail_url(self) -> str:\n"
            "        return f\"{Usdb.DETAIL_URL}{self:d}\"",
            "    def is_usdb_eu(self) -> bool:\n"
            "        return int(self) >= 1_000_000\n\n"
            "    def eu_id(self) -> int:\n"
            "        return int(self) - 1_000_000\n\n"
            "    def usdb_gettxt_url(self) -> str:\n"
            "        if self.is_usdb_eu():\n"
            "            return f\"https://usdb.eu/download/{self.eu_id()}\"\n"
            "        return f\"{Usdb.GETTXT_URL}{self:d}\"\n\n"
            "    def usdb_detail_url(self) -> str:\n"
            "        if self.is_usdb_eu():\n"
            "            return f\"https://usdb.eu/song/song/{self.eu_id()}\"\n"
            "        return f\"{Usdb.DETAIL_URL}{self:d}\"",
        ),
    ],
)

# 2. Keep LastUsdbUpdate scoped to animux (< 1_000_000)
patch_file(
    "usdb_syncer/db/__init__.py",
    [
        (
            "                \"SELECT usdb_mtime, song_id FROM usdb_song WHERE usdb_mtime = \"\n"
            "                \"(SELECT max(usdb_mtime) FROM usdb_song)\"",
            "                \"SELECT usdb_mtime, song_id FROM usdb_song WHERE song_id < 1000000 AND usdb_mtime = \"\n"
            "                \"(SELECT max(usdb_mtime) FROM usdb_song WHERE song_id < 1000000)\"",
        ),
    ],
)

# 3. Route details and notes to usdb_eu when song_id >= 1_000_000
patch_file(
    "usdb_syncer/usdb_scraper.py",
    [
        (
            "def get_usdb_details(song_id: SongId) -> SongDetails:\n"
            "    \"\"\"Retrieve song details from usdb webpage, if song exists.\"\"\"\n",
            "def get_usdb_details(song_id: SongId) -> SongDetails:\n"
            "    \"\"\"Retrieve song details from usdb webpage, if song exists.\"\"\"\n"
            "    if song_id.is_usdb_eu():\n"
            "        from usdb_syncer import usdb_eu\n\n"
            "        return usdb_eu.get_usdb_eu_details(song_id)\n",
        ),
        (
            "def get_notes(song_id: SongId, logger: Logger) -> str:\n"
            "    \"\"\"Retrieve notes for a song.\"\"\"\n",
            "def get_notes(song_id: SongId, logger: Logger) -> str:\n"
            "    \"\"\"Retrieve notes for a song.\"\"\"\n"
            "    if song_id.is_usdb_eu():\n"
            "        from usdb_syncer import usdb_eu\n\n"
            "        return usdb_eu.get_usdb_eu_notes(song_id, logger)\n",
        ),
    ],
)

# 4. Load both usdb.animux.de and usdb.eu songs during catalog sync
patch_file(
    "usdb_syncer/song_routines.py",
    [
        (
            "    try:\n"
            "        if last.is_zero():\n"
            "            songs = usdb_scraper.get_all_songs_from_usdb(progress, session=session)\n"
            "        else:\n"
            "            songs = usdb_scraper.get_updated_songs_from_usdb(\n"
            "                last, progress, session=session\n"
            "            )\n"
            "    except errors.UsdbLoginError:\n"
            "        logger.debug(\"Skipping fetching new songs as there is no login.\")\n"
            "        result.no_usdb_login = True\n"
            "    except requests.exceptions.ConnectionError:\n"
            "        logger.exception(\"Failed to fetch new songs; check network connection.\")\n"
            "        result.no_connection = True\n"
            "    else:\n"
            "        progress.reset(\"Writing USDB songs to database.\")\n"
            "        result.synced_with_usdb = True\n"
            "        if songs:\n"
            "            UsdbSong.upsert_many(songs)\n"
            "            result.new_songs.update(s.song_id for s in songs)\n"
            "            if force_reload:\n"
            "                UsdbSong.delete_many(\n"
            "                    [i for i in db.all_song_ids() if i not in result.new_songs]\n"
            "                )\n"
            "    return result",
            "    from usdb_syncer import usdb_eu\n\n"
            "    try:\n"
            "        if last.is_zero():\n"
            "            songs = usdb_scraper.get_all_songs_from_usdb(progress, session=session)\n"
            "        else:\n"
            "            songs = usdb_scraper.get_updated_songs_from_usdb(\n"
            "                last, progress, session=session\n"
            "            )\n"
            "    except errors.UsdbLoginError:\n"
            "        logger.debug(\"Skipping fetching new songs as there is no login.\")\n"
            "        result.no_usdb_login = True\n"
            "    except requests.exceptions.ConnectionError:\n"
            "        logger.exception(\"Failed to fetch new songs; check network connection.\")\n"
            "        result.no_connection = True\n"
            "    else:\n"
            "        progress.reset(\"Writing USDB songs to database.\")\n"
            "        result.synced_with_usdb = True\n"
            "        if songs:\n"
            "            UsdbSong.upsert_many(songs)\n"
            "            result.new_songs.update(s.song_id for s in songs)\n"
            "            if force_reload:\n"
            "                UsdbSong.delete_many(\n"
            "                    [\n"
            "                        i\n"
            "                        for i in db.all_song_ids()\n"
            "                        if not i.is_usdb_eu() and i not in result.new_songs\n"
            "                    ]\n"
            "                )\n\n"
            "    try:\n"
            "        eu_songs, eu_complete = usdb_eu.get_all_songs_from_usdb_eu(\n"
            "            progress, force_reload=force_reload\n"
            "        )\n"
            "    except requests.exceptions.RequestException:\n"
            "        logger.exception(\"Failed to fetch songs from usdb.eu.\")\n"
            "    else:\n"
            "        if eu_songs:\n"
            "            progress.reset(\"Writing usdb.eu songs to database.\")\n"
            "            UsdbSong.upsert_many(eu_songs)\n"
            "            eu_ids = {s.song_id for s in eu_songs}\n"
            "            result.new_songs.update(eu_ids)\n"
            "            result.synced_with_usdb = True\n"
            "            if force_reload and eu_complete:\n"
            "                UsdbSong.delete_many(\n"
            "                    [\n"
            "                        i\n"
            "                        for i in db.all_song_ids()\n"
            "                        if i.is_usdb_eu() and i not in eu_ids\n"
            "                    ]\n"
            "                )\n"
            "    return result",
        ),
    ],
)

# 5. Wire YouTube ID into meta_tags and set #PROVIDEDBY for usdb.eu
patch_file(
    "usdb_syncer/song_loader.py",
    [
        (
            "    txt.headers.creator = txt.headers.creator or details.uploader or None\n"
            "    return details, txt",
            "    txt.headers.creator = txt.headers.creator or details.uploader or None\n"
            "    if song_id.is_usdb_eu() and not txt.meta_tags.video:\n"
            "        if yt_id := next(details.all_comment_videos(), None):\n"
            "            txt.meta_tags.video = yt_id\n"
            "    return details, txt",
        ),
        (
            "    if version >= FormatVersion.V1_1_0:\n"
            "        ctx.txt.headers.providedby = constants.Usdb.BASE_URL",
            "    if version >= FormatVersion.V1_1_0:\n"
            "        ctx.txt.headers.providedby = (\n"
            "            \"https://usdb.eu/\" if ctx.song.song_id.is_usdb_eu() else constants.Usdb.BASE_URL\n"
            "        )",
        ),
    ],
)

# 6. Avoid querying animux cover URL for usdb.eu songs during table preview
patch_file(
    "usdb_syncer/usdb_song.py",
    [
        (
            "    def cover_remote_url(self) -> str:\n"
            "        return f\"{Usdb.COVER_URL}{self.song_id:d}.jpg\"",
            "    def cover_remote_url(self) -> str | None:\n"
            "        if self.song_id.is_usdb_eu():\n"
            "            return None\n"
            "        return f\"{Usdb.COVER_URL}{self.song_id:d}.jpg\"",
        ),
    ],
)

# 7. Support importing usdb.eu song URLs (.url / .desktop / .webloc)
patch_file(
    "usdb_syncer/usdb_id_file.py",
    [
        (
            "    if parsed_url.netloc != \"usdb.animux.de\":\n"
            "        raise UsdbIdFileInvalidDomainMalformedUrlFormatError(url, parsed_url.netloc)",
            "    if parsed_url.netloc in (\"usdb.eu\", \"www.usdb.eu\"):\n"
            "        parts = [p for p in parsed_url.path.split(\"/\") if p]\n"
            "        if parts and parts[-1].isdigit():\n"
            "            return SongId(1_000_000 + int(parts[-1]))\n"
            "        raise UsdbIdFileMalformedUrlFormatError(url)\n"
            "    if parsed_url.netloc != \"usdb.animux.de\":\n"
            "        raise UsdbIdFileInvalidDomainMalformedUrlFormatError(url, parsed_url.netloc)",
        ),
    ],
)

# 8. Bump wheel version to 0.26.0+eu4 and regenerate dist-info RECORD
dist_info = next(root.glob("usdb_syncer-*.dist-info"))
meta = dist_info / "METADATA"
meta.write_text(
    meta.read_text(encoding="utf-8").replace("Version: 0.26.0\n", "Version: 0.26.0+eu4\n", 1),
    encoding="utf-8",
)
new_dist_info = root / "usdb_syncer-0.26.0+eu4.dist-info"
dist_info.rename(new_dist_info)

record_path = new_dist_info / "RECORD"
rows = []
for f in sorted(root.rglob("*")):
    if not f.is_file() or f == record_path:
        continue
    rel = f.relative_to(root).as_posix()
    digest = hashlib.sha256(f.read_bytes()).digest()
    b64 = base64.urlsafe_b64encode(digest).rstrip(b"=").decode("ascii")
    rows.append((rel, f"sha256={b64}", str(f.stat().st_size)))
rows.append((record_path.relative_to(root).as_posix(), "", ""))

with record_path.open("w", encoding="utf-8", newline="") as fp:
    csv.writer(fp).writerows(rows)
