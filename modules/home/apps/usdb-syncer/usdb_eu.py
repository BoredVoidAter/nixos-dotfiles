"""Scraper and downloader for https://usdb.eu/."""

from __future__ import annotations

import io
import json
import os
import re
import string
import time
import unicodedata
import zipfile
from datetime import datetime
from pathlib import Path
from typing import TYPE_CHECKING
from urllib.parse import urlparse

import requests
from bs4 import BeautifulSoup, Tag

from usdb_syncer import SongId, errors
from usdb_syncer.logger import logger
from usdb_syncer.usdb_song import UsdbSong

if TYPE_CHECKING:
    from usdb_syncer import utils
    from usdb_syncer.logger import Logger
    from usdb_syncer.usdb_scraper import SongDetails

USDB_EU_OFFSET = 1_000_000
USDB_EU_BASE = "https://usdb.eu"
USDB_EU_SITEMAP = "https://usdb.eu/sitemap/songfile.php"
USDB_EU_PLAYER_JSON = "https://player.usdb.eu/2.0.0/json.php"
USDB_EU_DOWNLOAD_WAIT_SECS = 21.0
_USER_AGENT = "usdb-syncer/0.26.0 (+https://usdb.eu/)"
_SITEMAP_BATCH_LIMIT = 120

_SEARCH_URL_RE = re.compile(r"^https?://(?:www\.)?usdb\.eu/[^/]+/[^/]+/(\d+)$")
_PLAYER_LOAD_RE = re.compile(r"loadSongData\((\d+)\)")
_LOC_RE = re.compile(r"<loc>\s*(https?://[^<\s]+)\s*</loc>")
_FLAG_CODE_RE = re.compile(r"/flags/\d+x\d+/([a-zA-Z-]+)\.(?:svg|png)")
_JSONP_RE = re.compile(r"^\s*\((.*)\)\s*;?\s*$", re.DOTALL)

_LANG_MAP = {
    "ar": "Arabic",
    "bg": "Bulgarian",
    "br": "Portuguese (Brazil)",
    "ca": "Catalan",
    "cn": "Chinese",
    "cs": "Czech",
    "cz": "Czech",
    "da": "Danish",
    "de": "German",
    "dk": "Danish",
    "el": "Greek",
    "en": "English",
    "es": "Spanish",
    "et": "Estonian",
    "fi": "Finnish",
    "fr": "French",
    "gb": "English",
    "gr": "Greek",
    "he": "Hebrew",
    "hi": "Hindi",
    "hr": "Croatian",
    "hu": "Hungarian",
    "id": "Indonesian",
    "ie": "Irish",
    "il": "Hebrew",
    "is": "Icelandic",
    "it": "Italian",
    "ja": "Japanese",
    "jp": "Japanese",
    "ko": "Korean",
    "kr": "Korean",
    "la": "Latin",
    "lt": "Lithuanian",
    "lv": "Latvian",
    "ms": "Malay",
    "nl": "Dutch",
    "no": "Norwegian",
    "pl": "Polish",
    "pt": "Portuguese",
    "ro": "Romanian",
    "ru": "Russian",
    "se": "Swedish",
    "sk": "Slovak",
    "sl": "Slovenian",
    "sp": "Spanish",
    "sr": "Serbian",
    "sv": "Swedish",
    "tr": "Turkish",
    "uk": "English",
    "us": "English",
    "vi": "Vietnamese",
    "zh": "Chinese",
}


class _RateLimitError(requests.HTTPError):
    """Raised when usdb.eu returns HTTP 429 after short backoff."""


def to_song_id(eu_id: int) -> SongId:
    return SongId(USDB_EU_OFFSET + eu_id)


def _map_language(code_or_name: str) -> str:
    key = code_or_name.strip().lower()
    if not key:
        return ""
    return _LANG_MAP.get(key, code_or_name.strip())


def _fix_mojibake(text: str) -> str:
    """Fix UTF-8 bytes that usdb.eu double-decoded as Latin-1."""
    if not any(ord(ch) > 127 for ch in text):
        return text
    try:
        fixed = text.encode("latin-1").decode("utf-8")
        if fixed != text:
            return fixed
    except (UnicodeEncodeError, UnicodeDecodeError):
        pass
    return text


def _slugify(text: str) -> str:
    norm = unicodedata.normalize("NFKD", text)
    ascii_only = norm.encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]", "", ascii_only.lower())


def _sitemap_url_slugs(url: str) -> tuple[str, str] | None:
    parts = [p for p in urlparse(url).path.split("/") if p]
    if len(parts) != 2:
        return None
    return (_slugify(parts[0]), _slugify(parts[1]))


def _catalog_cache_path() -> Path:
    xdg_cache = os.environ.get("XDG_CACHE_HOME")
    base = Path(xdg_cache) if xdg_cache else (Path.home() / ".cache")
    return base / "usdb_syncer" / "usdb_eu_catalog_cache.json"


def _load_catalog_cache() -> dict:
    path = _catalog_cache_path()
    empty = {"seeded": False, "songs": {}, "sitemap_urls": {}}
    if not path.is_file():
        return empty
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            return empty
        return {
            "seeded": bool(data.get("seeded", False)),
            "songs": data.get("songs") if isinstance(data.get("songs"), dict) else {},
            "sitemap_urls": (
                data.get("sitemap_urls")
                if isinstance(data.get("sitemap_urls"), dict)
                else {}
            ),
        }
    except (OSError, ValueError):
        return empty


def _save_catalog_cache(cache: dict) -> None:
    path = _catalog_cache_path()
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(cache), encoding="utf-8")
        tmp.replace(path)
    except OSError as exc:
        logger.debug(f"Failed writing usdb.eu catalog cache: {exc}")


def _new_session() -> requests.Session:
    session = requests.Session()
    session.headers.update({"User-Agent": _USER_AGENT})
    return session


def _request_with_retry(
    session: requests.Session,
    method: str,
    url: str,
    state: dict[str, float],
    max_retries: int = 3,
    max_backoff: float = 15.0,
    **kwargs,
) -> requests.Response:
    for attempt in range(max_retries + 1):
        elapsed = time.monotonic() - state["last_req"]
        wait = state["delay"] - elapsed
        if wait > 0:
            time.sleep(wait)

        state["last_req"] = time.monotonic()
        resp = session.request(method, url, **kwargs)
        if resp.status_code == 429:
            if attempt >= max_retries:
                raise _RateLimitError(f"429 Too Many Requests for {url}", response=resp)
            retry_after = resp.headers.get("Retry-After")
            try:
                backoff = float(retry_after) if retry_after else (3.0 * (2**attempt))
            except ValueError:
                backoff = 3.0 * (2**attempt)
            backoff = min(max(backoff, 2.0), max_backoff)
            state["delay"] = min(max(state["delay"] * 1.4, 1.0), 2.5)
            logger.warning(
                f"usdb.eu HTTP 429 on {url}; waiting {backoff:.1f}s "
                f"(attempt {attempt + 1}/{max_retries})"
            )
            time.sleep(backoff)
            continue

        if resp.status_code in (502, 503, 504) and attempt < max_retries:
            backoff = min(2.0 * (2**attempt), max_backoff)
            time.sleep(backoff)
            continue

        resp.raise_for_status()
        return resp
    raise _RateLimitError(f"Exhausted retries for {url}")


def _fetch_music_tab(
    session: requests.Session, tab: str, state: dict[str, float]
) -> list[UsdbSong]:
    resp = _request_with_retry(
        session,
        "POST",
        f"{USDB_EU_BASE}/music",
        state,
        data={"tab": tab, "number": "0"},
        timeout=15,
    )
    data = resp.json()
    items = data.get("list") if isinstance(data, dict) else data
    if not isinstance(items, list):
        return []
    songs: list[UsdbSong] = []
    for item in items:
        try:
            eu_id = int(item["id"])
        except (KeyError, TypeError, ValueError):
            continue
        year_str = str(item.get("year") or "").strip()
        year = int(year_str) if len(year_str) == 4 and year_str.isdigit() else None
        songs.append(
            UsdbSong(
                song_id=to_song_id(eu_id),
                usdb_mtime=0,
                artist=str(item.get("artist") or "").strip(),
                title=str(item.get("title") or "").strip(),
                genre="",
                year=year,
                language="",
                creator="",
                edition="",
                golden_notes=False,
                rating=0.0,
                views=0,
                sample_url="",
            )
        )
    return songs


def _fetch_search_keyword(
    session: requests.Session,
    keyword: str,
    state: dict[str, float],
    order: str = "ASC",
) -> list[UsdbSong]:
    resp = _request_with_retry(
        session,
        "GET",
        f"{USDB_EU_BASE}/search",
        state,
        params={"keyword": keyword, "vieuw": "table", "limit": "200", "order": order},
        timeout=20,
    )
    soup = BeautifulSoup(resp.text, "lxml")
    songs: list[UsdbSong] = []
    for tr in soup.select("table.style tbody tr"):
        tds = tr.find_all("td")
        if len(tds) < 5:
            continue
        link = tds[0].find("a", href=True)
        if not isinstance(link, Tag):
            continue
        href = str(link.get("href") or "")
        if href.startswith("//"):
            href = "https:" + href
        elif href.startswith("/"):
            href = USDB_EU_BASE + href
        match = _SEARCH_URL_RE.match(href)
        if not match:
            continue
        eu_id = int(match.group(1))
        title = tds[0].get_text(strip=True)
        artist = tds[2].get_text(strip=True)
        genre = tds[3].get_text(strip=True)
        year_str = tds[4].get_text(strip=True)
        year = int(year_str) if len(year_str) == 4 and year_str.isdigit() else None

        golden_notes = bool(
            tds[1].find("i", class_=lambda c: c and "color_gold" in c)
        )
        lang = ""
        if flag_img := tds[1].find("img"):
            alt = str(flag_img.get("alt") or flag_img.get("title") or "")
            if not alt:
                src = str(flag_img.get("src") or "")
                if m := _FLAG_CODE_RE.search(src):
                    alt = m.group(1)
            lang = _map_language(alt)

        songs.append(
            UsdbSong(
                song_id=to_song_id(eu_id),
                usdb_mtime=0,
                artist=artist,
                title=title,
                genre=genre,
                year=year,
                language=lang,
                creator="",
                edition="",
                golden_notes=golden_notes,
                rating=0.0,
                views=0,
                sample_url="",
            )
        )
    return songs


def _fetch_sitemap_song_urls(
    session: requests.Session, state: dict[str, float]
) -> list[str]:
    resp = _request_with_retry(session, "GET", USDB_EU_SITEMAP, state, timeout=30)
    urls: list[str] = []
    seen: set[str] = set()
    for url in _LOC_RE.findall(resp.text):
        if _sitemap_url_slugs(url) is None:
            continue
        if url not in seen:
            seen.add(url)
            urls.append(url)
    return urls


def _fetch_song_by_sitemap_url(
    session: requests.Session, url: str, state: dict[str, float]
) -> UsdbSong | None:
    resp = _request_with_retry(
        session,
        "GET",
        url,
        state,
        max_retries=1,
        max_backoff=4.0,
        timeout=15,
    )
    eu_id: int | None = None
    if m := _SEARCH_URL_RE.match(resp.url):
        eu_id = int(m.group(1))

    soup = BeautifulSoup(resp.text, "lxml")
    if eu_id is None:
        if canonical := soup.select_one('link[rel="canonical"][href]'):
            if m := _SEARCH_URL_RE.match(str(canonical.get("href") or "")):
                eu_id = int(m.group(1))
    if eu_id is None:
        if m := _PLAYER_LOAD_RE.search(resp.text):
            eu_id = int(m.group(1))
    if eu_id is None:
        return None

    artist = ""
    title = ""
    if h1 := soup.select_one(".FileInfoBar h1"):
        links = h1.find_all("a")
        if len(links) >= 2:
            artist = links[0].get_text(strip=True)
            title = links[1].get_text(strip=True)

    genre = ""
    year: int | None = None
    language = ""
    golden_notes = False
    for div in soup.select(".FileInfoBar .MainGrid .grid div"):
        line = div.get_text(" ", strip=True)
        if line.startswith("This is a ") and line.endswith(" song."):
            genre = line.removeprefix("This is a ").removesuffix(" song.").strip()
        elif line.startswith("Song from "):
            y = line.removeprefix("Song from ").rstrip(".").strip()
            if len(y) == 4 and y.isdigit():
                year = int(y)
        elif line.startswith("This song is in "):
            language = line.removeprefix("This song is in ").rstrip(".").strip()
        elif "Contains golden notes" in line:
            golden_notes = True

    rating = 0.0
    up_el = soup.select_one("#rating .Thumb.Up span")
    down_el = soup.select_one("#rating .Thumb.Down span")
    if up_el and down_el:
        try:
            up_v = int(up_el.get_text(strip=True) or 0)
            down_v = int(down_el.get_text(strip=True) or 0)
            votes = up_v + down_v
            if votes > 0:
                rating = 5.0 * up_v / votes
        except ValueError:
            pass

    return UsdbSong(
        song_id=to_song_id(eu_id),
        usdb_mtime=0,
        artist=artist,
        title=title,
        genre=genre,
        year=year,
        language=language,
        creator="",
        edition="",
        golden_notes=golden_notes,
        rating=rating,
        views=0,
        sample_url="",
    )


def _song_to_cache_dict(song: UsdbSong) -> dict:
    return {
        "eu_id": song.song_id.eu_id(),
        "artist": song.artist,
        "title": song.title,
        "genre": song.genre,
        "year": song.year,
        "language": song.language,
        "golden_notes": song.golden_notes,
        "rating": song.rating,
    }


def _song_from_cache_dict(entry: dict) -> UsdbSong | None:
    try:
        eu_id = int(entry["eu_id"])
    except (KeyError, TypeError, ValueError):
        return None
    return UsdbSong(
        song_id=to_song_id(eu_id),
        usdb_mtime=0,
        artist=str(entry.get("artist") or ""),
        title=str(entry.get("title") or ""),
        genre=str(entry.get("genre") or ""),
        year=entry.get("year") if isinstance(entry.get("year"), int) else None,
        language=str(entry.get("language") or ""),
        creator="",
        edition="",
        golden_notes=bool(entry.get("golden_notes")),
        rating=float(entry.get("rating") or 0.0),
        views=0,
        sample_url="",
    )


def _merge_song(by_id: dict[SongId, UsdbSong], song: UsdbSong) -> None:
    existing = by_id.get(song.song_id)
    if existing is None:
        by_id[song.song_id] = song
        return
    if song.artist:
        existing.artist = song.artist
    if song.title:
        existing.title = song.title
    if song.genre:
        existing.genre = song.genre
    if song.year is not None:
        existing.year = song.year
    if song.language:
        existing.language = song.language
    if song.golden_notes:
        existing.golden_notes = True
    if song.rating > 0.0:
        existing.rating = song.rating


def get_all_songs_from_usdb_eu(
    progress: utils.ProgressProxy, force_reload: bool = False
) -> tuple[list[UsdbSong], bool]:
    """Fetch available songs from usdb.eu. Returns (songs, complete)."""
    logger.debug("Getting songs from usdb.eu.")
    cache = (
        {"seeded": False, "songs": {}, "sitemap_urls": {}}
        if force_reload
        else _load_catalog_cache()
    )
    by_id: dict[SongId, UsdbSong] = {}
    for entry in cache["songs"].values():
        if isinstance(entry, dict):
            if song := _song_from_cache_dict(entry):
                _merge_song(by_id, song)

    session = _new_session()
    state = {"delay": 0.6, "last_req": 0.0}
    complete = True
    cache_dirty = False

    try:
        sitemap_urls: list[str] = []
        if cache["seeded"] and len(by_id) >= 1500 and not force_reload:
            progress.reset("Checking usdb.eu for new songs.", maximum=2)
            try:
                sitemap_urls = _fetch_sitemap_song_urls(session, state)
            except requests.RequestException as exc:
                complete = False
                logger.warning(f"Failed fetching usdb.eu sitemap: {exc}")
            progress.increase()

            try:
                for s in _fetch_search_keyword(session, "", state, order="DESC"):
                    _merge_song(by_id, s)
                    cache["songs"][str(s.song_id.eu_id())] = _song_to_cache_dict(
                        by_id[s.song_id]
                    )
                    cache_dirty = True
            except requests.RequestException as exc:
                complete = False
                logger.warning(f"Failed fetching recent usdb.eu songs: {exc}")
            progress.increase()
        else:
            tabs = ["all", "tab_#"] + [f"tab_{c}" for c in string.ascii_lowercase]
            keywords = [""] + list(string.ascii_lowercase) + list(string.digits)
            progress.reset(
                "Fetching songs from usdb.eu.", maximum=1 + len(tabs) + len(keywords)
            )

            try:
                sitemap_urls = _fetch_sitemap_song_urls(session, state)
            except requests.RequestException as exc:
                complete = False
                logger.warning(f"Failed fetching usdb.eu sitemap: {exc}")
            progress.increase()

            for tab in tabs:
                try:
                    for s in _fetch_music_tab(session, tab, state):
                        _merge_song(by_id, s)
                except (requests.RequestException, ValueError) as exc:
                    complete = False
                    logger.warning(f"Failed fetching usdb.eu /music tab={tab}: {exc}")
                progress.increase()

            saturated_keywords: list[str] = []
            for kw in keywords:
                try:
                    songs = _fetch_search_keyword(session, kw, state, order="ASC")
                    for s in songs:
                        _merge_song(by_id, s)
                    if len(songs) >= 180:
                        saturated_keywords.append(kw)
                except requests.RequestException as exc:
                    complete = False
                    logger.warning(
                        f"Failed fetching usdb.eu /search keyword={kw!r}: {exc}"
                    )
                progress.increase()

            if saturated_keywords:
                progress.reset(
                    "Fetching additional usdb.eu search pages.",
                    maximum=len(saturated_keywords),
                )
                for kw in saturated_keywords:
                    try:
                        for s in _fetch_search_keyword(session, kw, state, order="DESC"):
                            _merge_song(by_id, s)
                    except requests.RequestException as exc:
                        complete = False
                        logger.warning(
                            f"Failed fetching usdb.eu /search keyword={kw!r} DESC: {exc}"
                        )
                    progress.increase()

            for sid, song in by_id.items():
                cache["songs"][str(sid.eu_id())] = _song_to_cache_dict(song)
            if by_id:
                cache["seeded"] = True
                cache_dirty = True

        if sitemap_urls:
            seen_slugs = {
                (_slugify(s.artist), _slugify(s.title)) for s in by_id.values()
            }
            to_fetch: list[str] = []
            for url in sitemap_urls:
                if url in cache["sitemap_urls"]:
                    continue
                if _sitemap_url_slugs(url) in seen_slugs:
                    continue
                to_fetch.append(url)

            if to_fetch:
                # Fetch newest sitemap entries first and cap per sync to avoid rate-limit stalls
                batch = list(reversed(to_fetch))[:_SITEMAP_BATCH_LIMIT]
                if len(to_fetch) > len(batch):
                    complete = False
                progress.reset(
                    f"Fetching {len(batch)} remaining usdb.eu songs.",
                    maximum=len(batch),
                )
                state["delay"] = max(state["delay"], 0.75)
                for idx, url in enumerate(batch, start=1):
                    try:
                        song = _fetch_song_by_sitemap_url(session, url, state)
                    except _RateLimitError as exc:
                        complete = False
                        logger.warning(
                            f"Stopping remaining usdb.eu sitemap fetch due to rate limit: {exc}"
                        )
                        break
                    except requests.RequestException as exc:
                        complete = False
                        logger.warning(f"Failed fetching usdb.eu song page {url}: {exc}")
                    else:
                        if song is not None:
                            _merge_song(by_id, song)
                            eu_id = song.song_id.eu_id()
                            cache["songs"][str(eu_id)] = _song_to_cache_dict(
                                by_id[song.song_id]
                            )
                            cache["sitemap_urls"][url] = eu_id
                            cache_dirty = True
                    if cache_dirty and idx % 10 == 0:
                        _save_catalog_cache(cache)
                        cache_dirty = False
                    progress.increase()
    finally:
        if cache_dirty:
            _save_catalog_cache(cache)

    logger.info(f"Fetched {len(by_id)} songs from usdb.eu (complete={complete}).")
    return list(by_id.values()), complete


def _fetch_player_json(eu_id: int) -> dict:
    resp = requests.get(
        USDB_EU_PLAYER_JSON,
        params={"songFile": str(eu_id)},
        timeout=15,
    )
    resp.raise_for_status()
    text = resp.text
    if m := _JSONP_RE.match(text):
        text = m.group(1)
    data = json.loads(text)
    if not isinstance(data, dict) or "error" in data:
        raise errors.UsdbNotFoundError
    return data


def get_usdb_eu_details(song_id: SongId) -> SongDetails:
    """Retrieve song details from player.usdb.eu and the usdb.eu song page."""
    from usdb_syncer.usdb_scraper import CommentContents, SongComment, SongDetails

    eu_id = song_id.eu_id()
    pdata = _fetch_player_json(eu_id)

    page_url = str(pdata.get("link") or "").strip()
    if page_url.startswith("//"):
        page_url = "https:" + page_url
    if not page_url:
        raise errors.UsdbNotFoundError

    title_obj = pdata.get("title") if isinstance(pdata.get("title"), dict) else {}
    artist_obj = pdata.get("artist") if isinstance(pdata.get("artist"), dict) else {}
    title = str(title_obj.get("label") or "").strip()
    artist = str(artist_obj.get("label") or "").strip()
    cover_url = str(title_obj.get("link") or "").strip() or None
    youtube_id = str(pdata.get("youtube") or "").strip()

    try:
        gap = float(pdata.get("gap") or 0)
    except (TypeError, ValueError):
        gap = 0.0

    language = ""
    year: int | None = None
    genre = ""
    bpm = 0.0
    golden_notes = False
    song_check = False
    uploader = ""
    date_time = datetime.now()
    rating = 0.0
    votes = 0

    try:
        resp = requests.get(page_url, timeout=15)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")

        if h1 := soup.select_one(".FileInfoBar h1"):
            links = h1.find_all("a")
            if len(links) >= 2:
                artist = links[0].get_text(strip=True) or artist
                title = links[1].get_text(strip=True) or title

        if cover_a := soup.select_one('.FileInfoBar .MainGrid a[href*="/hosting/song/"]'):
            href = str(cover_a.get("href") or "")
            if href.startswith("//"):
                href = "https:" + href
            if href:
                cover_url = href

        info_text_lines = [
            div.get_text(" ", strip=True)
            for div in soup.select(".FileInfoBar .MainGrid .grid div")
        ]
        for line in info_text_lines:
            if line.startswith("Uploaded by "):
                uploader = line.removeprefix("Uploaded by ").rstrip(".").strip()
            elif line.startswith("Bpm:"):
                try:
                    bpm = float(line.split(":", 1)[1].strip().replace(",", "."))
                except ValueError:
                    pass
            elif line.startswith("Gap:"):
                try:
                    gap = float(line.split(":", 1)[1].strip().replace(",", "."))
                except ValueError:
                    pass
            elif line.startswith("Added on "):
                raw_date = line.removeprefix("Added on ").strip()
                try:
                    date_time = datetime.strptime(raw_date, "%d-%m-%y")
                except ValueError:
                    pass
            elif line.startswith("This is a ") and line.endswith(" song."):
                genre = line.removeprefix("This is a ").removesuffix(" song.").strip()
            elif line.startswith("Song from "):
                y = line.removeprefix("Song from ").rstrip(".").strip()
                if len(y) == 4 and y.isdigit():
                    year = int(y)
            elif line.startswith("This song is in "):
                language = line.removeprefix("This song is in ").rstrip(".").strip()
            elif "Contains golden notes" in line:
                golden_notes = True
            elif "song has been checked" in line:
                song_check = True

        up_el = soup.select_one("#rating .Thumb.Up span")
        down_el = soup.select_one("#rating .Thumb.Down span")
        if up_el and down_el:
            try:
                up_v = int(up_el.get_text(strip=True) or 0)
                down_v = int(down_el.get_text(strip=True) or 0)
                votes = up_v + down_v
                if votes > 0:
                    rating = 5.0 * up_v / votes
            except ValueError:
                pass
    except requests.RequestException as exc:
        logger.warning(f"Failed to scrape full usdb.eu page {page_url}: {exc}")

    comments: list[SongComment] = []
    if youtube_id:
        comments.append(
            SongComment(
                date_time=date_time.strftime("%d.%m.%y - %H:%M"),
                author=uploader or "usdb.eu",
                contents=CommentContents(
                    text=f"https://www.youtube.com/watch?v={youtube_id}",
                    youtube_ids=[youtube_id],
                    urls=[],
                ),
            )
        )

    return SongDetails(
        song_id=song_id,
        artist=artist,
        title=title,
        cover_url=cover_url,
        language=language,
        year=year,
        genre=genre,
        edition="",
        bpm=bpm,
        gap=gap,
        golden_notes=golden_notes,
        song_check=song_check,
        date_time=date_time,
        uploader=uploader,
        editors=[],
        views=0,
        rating=rating,
        votes=votes,
        audio_sample=None,
        comments=comments,
    )


def get_usdb_eu_notes(song_id: SongId, log: Logger) -> str:
    """Download song txt from usdb.eu via the /download zip countdown flow."""
    eu_id = song_id.eu_id()
    session = requests.Session()
    session.cookies.set("archief", json.dumps([eu_id]), domain="usdb.eu", path="/")

    init_resp = session.get(f"{USDB_EU_BASE}/download", timeout=15)
    init_resp.raise_for_status()

    post_resp = session.post(f"{USDB_EU_BASE}/download", timeout=15)
    post_resp.raise_for_status()

    log.info(f"Waiting {int(USDB_EU_DOWNLOAD_WAIT_SECS)}s for usdb.eu download timer...")
    time.sleep(USDB_EU_DOWNLOAD_WAIT_SECS)

    zip_resp = session.get(f"{USDB_EU_BASE}/download", timeout=30)
    zip_resp.raise_for_status()
    if "zip" not in (zip_resp.headers.get("content-type") or "").lower():
        raise errors.UsdbParseError("usdb.eu did not return a zip archive")

    with zipfile.ZipFile(io.BytesIO(zip_resp.content)) as zf:
        txt_names = [
            n
            for n in zf.namelist()
            if n.lower().endswith(".txt") and not n.lower().endswith("readme.txt")
        ]
        if not txt_names:
            raise errors.UsdbNotFoundError
        raw_bytes = zf.read(txt_names[0])

    for enc in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            text = raw_bytes.decode(enc)
            return _fix_mojibake(text)
        except UnicodeDecodeError:
            continue
    return _fix_mojibake(raw_bytes.decode("utf-8", errors="replace"))
