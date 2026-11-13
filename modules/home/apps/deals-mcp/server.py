#!/usr/bin/env python3
import concurrent.futures
import html
import json
import os
import re
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET
from bs4 import BeautifulSoup

COOKIE_DIR = "/tmp/mcp-de-deals-cookies"
os.makedirs(COOKIE_DIR, exist_ok=True)

USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0"
)


def parse_de_price(text: str | None) -> float | None:
    if not text:
        return None
    cleaned = text.replace("\xa0", " ").strip()
    m = re.search(r"(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?|\d+(?:[.,]\d{1,2})?)", cleaned)
    if not m:
        return None
    num = m.group(1)
    if "," in num and "." in num:
        num = num.replace(".", "").replace(",", ".")
    elif "," in num:
        num = num.replace(",", ".")
    try:
        return float(num)
    except ValueError:
        return None


def fetch_url(
    url: str,
    accept: str = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    timeout: int = 15,
) -> tuple[int, str, str | None]:
    domain = urllib.parse.urlparse(url).netloc or "default"
    cookie_file = os.path.join(
        COOKIE_DIR, re.sub(r"[^a-zA-Z0-9._-]", "_", domain) + ".txt"
    )
    cmd = [
        "curl",
        "-sS",
        "-L",
        "--compressed",
        "--max-time",
        str(timeout),
        "-b",
        cookie_file,
        "-c",
        cookie_file,
        "-A",
        USER_AGENT,
        "-H",
        f"Accept: {accept}",
        "-H",
        "Accept-Language: de-DE,de;q=0.9,en-US;q=0.7,en;q=0.5",
        "-H",
        "Upgrade-Insecure-Requests: 1",
        "-H",
        "DNT: 1",
        "-w",
        "\n__MCP_HTTP_CODE__:%{http_code}",
        url,
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout + 3)
    except Exception as exc:
        return 0, "", str(exc)

    if proc.returncode != 0 and not proc.stdout:
        return 0, "", proc.stderr.strip() or f"curl exited with {proc.returncode}"

    raw = proc.stdout
    marker = "\n__MCP_HTTP_CODE__:"
    if marker in raw:
        body, code_str = raw.rsplit(marker, 1)
        try:
            status = int(code_str.strip())
        except ValueError:
            status = 0
    else:
        body = raw
        status = 200

    return status, body, None


def is_bot_blocked(status: int, body: str) -> bool:
    if status in (403, 429, 503) and len(body) < 25000:
        return True
    lower = body[:15000].lower()
    block_markers = [
        "api-services-support@amazon.com",
        "geben sie die zeichen ein",
        "type the characters you see",
        "just a moment...",
        "cf-browser-verification",
        "attention required! | cloudflare",
        "captcha-delivery",
        "datadome",
        "access denied",
        "pardon our interruption",
    ]
    return any(m in lower for m in block_markers)


def search_kleinanzeigen(
    query: str,
    min_price: int | None = None,
    max_price: int | None = None,
    postal_code: str | None = None,
    radius_km: int | None = None,
    sort: str = "relevance",
    limit: int = 15,
) -> dict:
    params: dict[str, str] = {"keywords": query}
    if min_price is not None:
        params["minPrice"] = str(int(min_price))
    if max_price is not None:
        params["maxPrice"] = str(int(max_price))
    if postal_code:
        params["locationStr"] = postal_code.strip()
        if radius_km is not None:
            params["radius"] = str(int(radius_km))

    sort_map = {
        "newest": "SORTING_DATE",
        "price_asc": "PRICE_ASCENDING",
        "relevance": "RELEVANCE",
    }
    if sort in sort_map:
        params["sortingField"] = sort_map[sort]

    url = "https://www.kleinanzeigen.de/s-suchanfrage.html?" + urllib.parse.urlencode(
        params
    )
    status, body, err = fetch_url(url)
    if err:
        return {"source": "kleinanzeigen.de", "url": url, "error": err, "results": []}
    if is_bot_blocked(status, body):
        return {
            "source": "kleinanzeigen.de",
            "url": url,
            "blocked_by_bot_protection": True,
            "error": f"HTTP {status} bot/challenge response",
            "results": [],
        }

    soup = BeautifulSoup(body, "html.parser")
    items = []
    for ad in soup.select("article.aditem"):
        title_el = ad.select_one("a.ellipsis") or ad.select_one("h2 a")
        if not title_el:
            continue
        href = title_el.get("href", "")
        full_url = (
            "https://www.kleinanzeigen.de" + href if href.startswith("/") else href
        )
        price_el = ad.select_one(".aditem-main--middle--price-shipping--price")
        shipping_el = ad.select_one(".aditem-main--middle--price-shipping--shipping")
        loc_el = ad.select_one(".aditem-main--top--left")
        date_el = ad.select_one(".aditem-main--top--right")
        desc_el = ad.select_one(".aditem-main--middle--description")

        price_raw = price_el.get_text(" ", strip=True) if price_el else ""
        price_eur = parse_de_price(price_raw)
        if max_price is not None and price_eur is not None and price_eur > max_price:
            continue
        if min_price is not None and price_eur is not None and price_eur < min_price:
            continue

        items.append(
            {
                "id": ad.get("data-adid"),
                "title": title_el.get_text(" ", strip=True),
                "price_raw": price_raw,
                "price_eur": price_eur,
                "negotiable": "VB" in price_raw.upper(),
                "shipping": shipping_el.get_text(" ", strip=True) if shipping_el else "",
                "location": loc_el.get_text(" ", strip=True) if loc_el else "",
                "date": date_el.get_text(" ", strip=True) if date_el else "",
                "description": desc_el.get_text(" ", strip=True) if desc_el else "",
                "url": full_url,
            }
        )
        if len(items) >= limit:
            break

    if sort == "price_desc":
        items.sort(
            key=lambda x: x["price_eur"] if x["price_eur"] is not None else -1.0,
            reverse=True,
        )

    return {
        "source": "kleinanzeigen.de",
        "url": url,
        "count": len(items),
        "results": items,
    }


def search_amazon_de(
    query: str,
    min_price: float | None = None,
    max_price: float | None = None,
    sort: str = "relevance",
    deals_only: bool = False,
    limit: int = 15,
) -> dict:
    params: dict[str, str] = {"k": query}
    sort_map = {
        "price_asc": "price-asc-rank",
        "price_desc": "price-desc-rank",
        "review_rank": "review-rank",
        "newest": "date-desc-rank",
    }
    if sort in sort_map:
        params["s"] = sort_map[sort]
    if min_price is not None:
        params["low-price"] = str(int(min_price))
    if max_price is not None:
        params["high-price"] = str(int(max_price))
    if deals_only:
        params["pct-off"] = "15-95"

    url = "https://www.amazon.de/s?" + urllib.parse.urlencode(params)
    status, body, err = fetch_url(url)
    if err:
        return {"source": "amazon.de", "url": url, "error": err, "results": []}
    if is_bot_blocked(status, body):
        return {
            "source": "amazon.de",
            "url": url,
            "blocked_by_bot_protection": True,
            "error": f"HTTP {status} Amazon CAPTCHA/bot check triggered",
            "results": [],
        }

    soup = BeautifulSoup(body, "html.parser")
    items = []
    for card in soup.select('div[data-component-type="s-search-result"]'):
        asin = card.get("data-asin", "").strip()
        if not asin:
            continue
        title_el = card.select_one("h2 span") or card.select_one("h2")
        if not title_el:
            continue
        title = title_el.get_text(" ", strip=True)

        price_el = card.select_one(
            ".a-price:not(.a-text-price) .a-offscreen"
        ) or card.select_one(".a-price .a-offscreen")
        price_raw = price_el.get_text(" ", strip=True) if price_el else ""
        price_eur = parse_de_price(price_raw)

        if max_price is not None and price_eur is not None and price_eur > max_price:
            continue
        if min_price is not None and price_eur is not None and price_eur < min_price:
            continue

        rrp_el = card.select_one(".a-price.a-text-price .a-offscreen")
        rrp_raw = rrp_el.get_text(" ", strip=True) if rrp_el else ""
        rrp_eur = parse_de_price(rrp_raw)

        discount_pct = None
        if price_eur and rrp_eur and rrp_eur > price_eur:
            discount_pct = round((1 - price_eur / rrp_eur) * 100)

        card_text = card.get_text(" ", strip=True)
        unit_match = re.search(
            r"\((\d+(?:[.,]\d+)?\s*€\s*/\s*(?:kg|g|l|ml|Stück|Kapsel|Tablette|100\s*g|100\s*ml))\)",
            card_text,
            re.IGNORECASE,
        )
        rating_el = card.select_one(".a-icon-alt")
        sponsored = bool(
            re.search(r"\bGesponsert\b|\bSponsored\b", card_text, re.IGNORECASE)
        )

        items.append(
            {
                "asin": asin,
                "title": title,
                "price_raw": price_raw,
                "price_eur": price_eur,
                "rrp_raw": rrp_raw or None,
                "rrp_eur": rrp_eur,
                "discount_pct": discount_pct,
                "unit_price": unit_match.group(1) if unit_match else None,
                "rating": rating_el.get_text(" ", strip=True) if rating_el else None,
                "sponsored": sponsored,
                "url": f"https://www.amazon.de/dp/{asin}",
            }
        )
        if len(items) >= limit:
            break

    return {
        "source": "amazon.de",
        "url": url,
        "count": len(items),
        "results": items,
    }


def search_idealo(
    query: str,
    min_price: float | None = None,
    max_price: float | None = None,
    sort: str = "relevance",
    limit: int = 15,
) -> dict:
    params: dict[str, str] = {"q": query}
    if sort == "price_asc":
        params["sortKey"] = "MIN_PRICE"
    elif sort == "popularity":
        params["sortKey"] = "POPULARITY"

    url = (
        "https://www.idealo.de/preisvergleich/MainSearchProductCategory.html?"
        + urllib.parse.urlencode(params)
    )
    status, body, err = fetch_url(url)
    if err:
        return {"source": "idealo.de", "url": url, "error": err, "results": []}
    if is_bot_blocked(status, body):
        return {
            "source": "idealo.de",
            "url": url,
            "blocked_by_bot_protection": True,
            "error": f"HTTP {status} Idealo anti-bot challenge (try search_geizhals or search_mydealz instead)",
            "results": [],
        }

    soup = BeautifulSoup(body, "html.parser")
    items = []

    tiles = soup.select('[class*="sr-resultItemTile"]') or soup.select(
        "div.offerList-item"
    )
    for tile in tiles:
        link_el = tile.select_one("a[href]")
        if not link_el:
            continue
        href = link_el.get("href", "")
        full_url = "https://www.idealo.de" + href if href.startswith("/") else href
        title_el = (
            tile.select_one('[class*="productSummary__title"]')
            or tile.select_one('[class*="title"]')
            or link_el
        )
        price_el = tile.select_one('[class*="detailedPriceInfo__price"]') or tile.select_one(
            '[class*="price"]'
        )
        offers_el = tile.select_one('[class*="offerCount"]') or tile.select_one(
            '[class*="offers"]'
        )

        price_raw = price_el.get_text(" ", strip=True) if price_el else ""
        price_eur = parse_de_price(price_raw)
        if max_price is not None and price_eur is not None and price_eur > max_price:
            continue
        if min_price is not None and price_eur is not None and price_eur < min_price:
            continue

        items.append(
            {
                "title": title_el.get_text(" ", strip=True),
                "price_raw": price_raw,
                "price_eur": price_eur,
                "offers": offers_el.get_text(" ", strip=True) if offers_el else None,
                "url": full_url,
            }
        )
        if len(items) >= limit:
            break

    if not items:
        for script in soup.select('script[type="application/ld+json"]'):
            try:
                data = json.loads(script.string or "")
            except Exception:
                continue
            entries = data if isinstance(data, list) else [data]
            for entry in entries:
                if isinstance(entry, dict) and entry.get("@type") == "ItemList":
                    for elem in entry.get("itemListElement", []):
                        prod = elem.get("item", elem)
                        name = prod.get("name")
                        if not name:
                            continue
                        offers = prod.get("offers", {})
                        low = offers.get("lowPrice") or offers.get("price")
                        price_eur = float(low) if low is not None else None
                        if (
                            max_price is not None
                            and price_eur is not None
                            and price_eur > max_price
                        ):
                            continue
                        if (
                            min_price is not None
                            and price_eur is not None
                            and price_eur < min_price
                        ):
                            continue
                        items.append(
                            {
                                "title": name,
                                "price_raw": f"{low} €" if low is not None else "",
                                "price_eur": price_eur,
                                "offers": offers.get("offerCount"),
                                "url": prod.get("url") or url,
                            }
                        )
                        if len(items) >= limit:
                            break

    return {
        "source": "idealo.de",
        "url": url,
        "count": len(items),
        "results": items,
    }


def search_geizhals(
    query: str,
    min_price: float | None = None,
    max_price: float | None = None,
    sort: str = "relevance",
    limit: int = 15,
) -> dict:
    params: dict[str, str] = {"fs": query, "in": ""}
    if sort == "price_asc":
        params["sort"] = "p"
    elif sort == "rating":
        params["sort"] = "r"
    if min_price is not None:
        params["bpmin"] = str(min_price)
    if max_price is not None:
        params["bpmax"] = str(max_price)

    url = "https://geizhals.de/?" + urllib.parse.urlencode(params)
    status, body, err = fetch_url(url)
    if err:
        return {"source": "geizhals.de", "url": url, "error": err, "results": []}
    if is_bot_blocked(status, body):
        return {
            "source": "geizhals.de",
            "url": url,
            "blocked_by_bot_protection": True,
            "error": f"HTTP {status} Geizhals challenge",
            "results": [],
        }

    soup = BeautifulSoup(body, "html.parser")
    items = []
    rows = soup.select(".listview__item") or soup.select(".productlist__item")
    for row in rows:
        name_el = (
            row.select_one("a.listview__name-link")
            or row.select_one(".productlist__link")
            or row.select_one("a[href]")
        )
        if not name_el:
            continue
        href = name_el.get("href", "")
        full_url = "https://geizhals.de/" + href.lstrip("/") if not href.startswith("http") else href
        price_el = (
            row.select_one(".gh_price")
            or row.select_one('[class*="price-link"]')
            or row.select_one('[class*="price"]')
        )
        offers_el = row.select_one('[class*="offers"]')
        specs_el = row.select_one('[class*="specs"]') or row.select_one(
            '[class*="subtext"]'
        )

        price_raw = price_el.get_text(" ", strip=True) if price_el else ""
        price_eur = parse_de_price(price_raw)
        if max_price is not None and price_eur is not None and price_eur > max_price:
            continue
        if min_price is not None and price_eur is not None and price_eur < min_price:
            continue

        items.append(
            {
                "title": name_el.get_text(" ", strip=True),
                "price_raw": price_raw,
                "price_eur": price_eur,
                "offers": offers_el.get_text(" ", strip=True) if offers_el else None,
                "specs": specs_el.get_text(" ", strip=True) if specs_el else None,
                "url": full_url,
            }
        )
        if len(items) >= limit:
            break

    return {
        "source": "geizhals.de",
        "url": url,
        "count": len(items),
        "results": items,
    }


def _parse_mydealz_rss(xml_text: str, query: str | None, min_temp: int | None, limit: int) -> list[dict]:
    items = []
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return items

    q_terms = [t.lower() for t in (query or "").split() if t.strip()]
    for item in root.findall("./channel/item"):
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        pub_date = (item.findtext("pubDate") or "").strip()
        desc_html = item.findtext("description") or ""
        desc_text = BeautifulSoup(desc_html, "html.parser").get_text(" ", strip=True)

        if q_terms:
            haystack = f"{title} {desc_text}".lower()
            if not all(term in haystack for term in q_terms):
                continue

        price_match = re.search(r"(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?\s*€)", title)
        price_raw = price_match.group(1) if price_match else ""
        items.append(
            {
                "title": html.unescape(title),
                "price_raw": price_raw,
                "price_eur": parse_de_price(price_raw),
                "published": pub_date,
                "snippet": desc_text[:280],
                "url": link,
            }
        )
        if len(items) >= limit:
            break
    return items


def search_mydealz(
    query: str | None = None,
    feed: str = "search",
    min_temp: int | None = None,
    limit: int = 15,
) -> dict:
    if query and feed == "search":
        url = "https://www.mydealz.de/search?" + urllib.parse.urlencode({"q": query})
        status, body, err = fetch_url(url)
        if not err and not is_bot_blocked(status, body):
            soup = BeautifulSoup(body, "html.parser")
            items = []
            for art in soup.select("article.thread"):
                vue_data = {}
                vue_node = art if art.has_attr("data-vue2") else art.select_one("[data-vue2]")
                if vue_node and vue_node.get("data-vue2"):
                    try:
                        parsed = json.loads(vue_node["data-vue2"])
                        vue_data = parsed.get("props", {}).get("thread", {}) or parsed.get("props", {})
                    except Exception:
                        vue_data = {}

                title_el = art.select_one("a.thread-title") or art.select_one(".thread-title a")
                title = vue_data.get("title") or (
                    title_el.get_text(" ", strip=True) if title_el else ""
                )
                if not title:
                    continue

                href = ""
                if vue_data.get("titleSlug") and vue_data.get("threadId"):
                    href = f"https://www.mydealz.de/deals/{vue_data['titleSlug']}-{vue_data['threadId']}"
                elif title_el:
                    href = title_el.get("href", "")
                    if href.startswith("/"):
                        href = "https://www.mydealz.de" + href

                temp_val = vue_data.get("temperature")
                if temp_val is None:
                    temp_el = art.select_one(".cept-vote-temp")
                    if temp_el:
                        m = re.search(r"-?\d+", temp_el.get_text())
                        temp_val = int(m.group(0)) if m else None

                if min_temp is not None and temp_val is not None and temp_val < min_temp:
                    continue

                price_val = vue_data.get("price")
                if price_val is not None:
                    price_raw = f"{price_val} €"
                    price_eur = float(price_val)
                else:
                    p_el = art.select_one(".thread-price")
                    price_raw = p_el.get_text(" ", strip=True) if p_el else ""
                    price_eur = parse_de_price(price_raw)

                next_best = vue_data.get("nextBestPrice")
                merchant_el = art.select_one(".cept-merchant-name")
                merchant = (
                    (vue_data.get("merchant") or {}).get("merchantName")
                    if isinstance(vue_data.get("merchant"), dict)
                    else None
                ) or (merchant_el.get_text(" ", strip=True) if merchant_el else None)

                items.append(
                    {
                        "title": title,
                        "price_raw": price_raw,
                        "price_eur": price_eur,
                        "next_best_price_eur": next_best,
                        "temperature": temp_val,
                        "merchant": merchant,
                        "is_expired": bool(vue_data.get("isExpired", False)),
                        "url": href,
                    }
                )
                if len(items) >= limit:
                    break

            if items:
                return {
                    "source": "mydealz.de",
                    "url": url,
                    "count": len(items),
                    "results": items,
                }

    feed_slug = feed if feed in ("hot", "new", "discussed") else "hot"
    rss_url = f"https://www.mydealz.de/rss/{feed_slug}"
    status, xml_body, err = fetch_url(
        rss_url, accept="application/rss+xml, application/xml, text/xml, */*"
    )
    if err:
        return {"source": "mydealz.de", "url": rss_url, "error": err, "results": []}
    if is_bot_blocked(status, xml_body):
        return {
            "source": "mydealz.de",
            "url": rss_url,
            "blocked_by_bot_protection": True,
            "error": f"HTTP {status} MyDealz RSS blocked",
            "results": [],
        }

    items = _parse_mydealz_rss(xml_body, query, min_temp, limit)
    return {
        "source": "mydealz.de",
        "url": rss_url,
        "count": len(items),
        "results": items,
    }


def search_all_deals(
    query: str,
    max_price: float | None = None,
    sources: list[str] | None = None,
    limit_per_source: int = 8,
) -> dict:
    chosen = sources or ["mydealz", "geizhals", "kleinanzeigen", "amazon_de", "idealo"]
    tasks = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        if "mydealz" in chosen:
            tasks["mydealz"] = pool.submit(
                search_mydealz, query=query, feed="search", limit=limit_per_source
            )
        if "kleinanzeigen" in chosen:
            tasks["kleinanzeigen"] = pool.submit(
                search_kleinanzeigen,
                query=query,
                max_price=int(max_price) if max_price is not None else None,
                limit=limit_per_source,
            )
        if "amazon_de" in chosen:
            tasks["amazon_de"] = pool.submit(
                search_amazon_de,
                query=query,
                max_price=max_price,
                limit=limit_per_source,
            )
        if "idealo" in chosen:
            tasks["idealo"] = pool.submit(
                search_idealo,
                query=query,
                max_price=max_price,
                limit=limit_per_source,
            )
        if "geizhals" in chosen:
            tasks["geizhals"] = pool.submit(
                search_geizhals,
                query=query,
                max_price=max_price,
                limit=limit_per_source,
            )

    results = {}
    for name, fut in tasks.items():
        try:
            results[name] = fut.result(timeout=20)
        except Exception as exc:
            results[name] = {"source": name, "error": str(exc), "results": []}

    return {"query": query, "max_price": max_price, "sources": results}


def fetch_product_page(url: str) -> dict:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        return {"error": "URL must start with http:// or https://"}

    status, body, err = fetch_url(url, timeout=18)
    if err:
        return {"url": url, "error": err}
    if is_bot_blocked(status, body):
        return {
            "url": url,
            "blocked_by_bot_protection": True,
            "error": f"HTTP {status} anti-bot page returned",
        }

    soup = BeautifulSoup(body, "html.parser")
    title = soup.title.get_text(" ", strip=True) if soup.title else ""

    json_ld = []
    for script in soup.select('script[type="application/ld+json"]'):
        try:
            obj = json.loads(script.string or "")
            json_ld.append(obj)
        except Exception:
            continue

    meta = {}
    for tag in soup.select("meta[property], meta[name]"):
        key = tag.get("property") or tag.get("name")
        val = tag.get("content")
        if key and val and any(
            k in key.lower() for k in ("price", "title", "description", "availability", "brand")
        ):
            meta[key] = val

    for junk in soup(["script", "style", "noscript", "svg"]):
        junk.decompose()

    text = re.sub(r"\s+", " ", soup.get_text(" ", strip=True)).strip()
    return {
        "url": url,
        "status": status,
        "title": title,
        "meta": meta,
        "json_ld": json_ld[:5],
        "text_excerpt": text[:6000],
    }


TOOLS = [
    {
        "name": "search_kleinanzeigen",
        "description": (
            "Search Kleinanzeigen.de (German classifieds) for used or new tech, electronics, "
            "and local/shipping deals without API keys. Supports min/max price, postal code, radius, and sorting."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Search query in German or English"},
                "min_price": {"type": "integer", "description": "Minimum price in EUR"},
                "max_price": {"type": "integer", "description": "Maximum price in EUR"},
                "postal_code": {"type": "string", "description": "German PLZ (e.g. '10115')"},
                "radius_km": {"type": "integer", "description": "Search radius in km around postal_code"},
                "sort": {
                    "type": "string",
                    "enum": ["relevance", "price_asc", "price_desc", "newest"],
                    "default": "relevance",
                },
                "limit": {"type": "integer", "default": 15},
            },
            "required": ["query"],
        },
    },
    {
        "name": "search_amazon_de",
        "description": (
            "Search Amazon.de for tech, supplements (protein, creatine, vitamins), and everyday products. "
            "Returns prices, RRP/discounts, unit prices (e.g. €/kg), ratings, and ASIN URLs."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Search query"},
                "min_price": {"type": "number", "description": "Minimum price in EUR"},
                "max_price": {"type": "number", "description": "Maximum price in EUR"},
                "sort": {
                    "type": "string",
                    "enum": ["relevance", "price_asc", "price_desc", "review_rank", "newest"],
                    "default": "relevance",
                },
                "deals_only": {
                    "type": "boolean",
                    "description": "Filter for discounted items (>=15% off)",
                    "default": False,
                },
                "limit": {"type": "integer", "default": 15},
            },
            "required": ["query"],
        },
    },
    {
        "name": "search_idealo",
        "description": (
            "Search Idealo.de (German price comparison) for current lowest online prices across German shops."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Product name or model"},
                "min_price": {"type": "number", "description": "Minimum price in EUR"},
                "max_price": {"type": "number", "description": "Maximum price in EUR"},
                "sort": {
                    "type": "string",
                    "enum": ["relevance", "price_asc", "popularity"],
                    "default": "relevance",
                },
                "limit": {"type": "integer", "default": 15},
            },
            "required": ["query"],
        },
    },
    {
        "name": "search_geizhals",
        "description": (
            "Search Geizhals.de (German/EU price comparison, great for PC hardware, tech, and electronics)."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Product name or model"},
                "min_price": {"type": "number", "description": "Minimum price in EUR"},
                "max_price": {"type": "number", "description": "Maximum price in EUR"},
                "sort": {
                    "type": "string",
                    "enum": ["relevance", "price_asc", "rating"],
                    "default": "relevance",
                },
                "limit": {"type": "integer", "default": 15},
            },
            "required": ["query"],
        },
    },
    {
        "name": "search_mydealz",
        "description": (
            "Search MyDealz.de (Germany's largest community deal platform for tech, supplements, coupons, and flash sales) "
            "or browse hot/new/discussed feeds without any API key."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Optional search terms; omit to browse current hot/new deals",
                },
                "feed": {
                    "type": "string",
                    "enum": ["search", "hot", "new", "discussed"],
                    "default": "search",
                },
                "min_temp": {
                    "type": "integer",
                    "description": "Minimum community temperature/votes (e.g. 100)",
                },
                "limit": {"type": "integer", "default": 15},
            },
        },
    },
    {
        "name": "search_all_deals",
        "description": (
            "Run a parallel deal search across MyDealz, Geizhals, Kleinanzeigen, Amazon.de, and Idealo "
            "to compare new, used, and community-voted prices in Germany in one call."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Product or category to search"},
                "max_price": {"type": "number", "description": "Optional max price filter in EUR"},
                "sources": {
                    "type": "array",
                    "items": {
                        "type": "string",
                        "enum": ["mydealz", "geizhals", "kleinanzeigen", "amazon_de", "idealo"],
                    },
                    "description": "Optional subset of sources to query",
                },
                "limit_per_source": {"type": "integer", "default": 8},
            },
            "required": ["query"],
        },
    },
    {
        "name": "fetch_product_page",
        "description": (
            "Fetch and extract structured metadata, JSON-LD pricing, and page text from a specific product or deal URL "
            "(e.g. to check €/kg, supplement ingredients, shipping costs, or retailer offers)."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "url": {"type": "string", "description": "Full http(s) URL to inspect"},
            },
            "required": ["url"],
        },
    },
]

TOOL_DISPATCH = {
    "search_kleinanzeigen": search_kleinanzeigen,
    "search_amazon_de": search_amazon_de,
    "search_idealo": search_idealo,
    "search_geizhals": search_geizhals,
    "search_mydealz": search_mydealz,
    "search_all_deals": search_all_deals,
    "fetch_product_page": fetch_product_page,
}


def send_response(msg: dict) -> None:
    sys.stdout.write(json.dumps(msg, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def handle_request(req: dict) -> None:
    method = req.get("method")
    req_id = req.get("id")
    params = req.get("params") or {}

    if method == "initialize":
        proto = params.get("protocolVersion") or "2024-11-05"
        send_response(
            {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "protocolVersion": proto,
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "de-deals", "version": "1.0.0"},
                },
            }
        )
    elif method == "notifications/initialized":
        return
    elif method == "ping":
        if req_id is not None:
            send_response({"jsonrpc": "2.0", "id": req_id, "result": {}})
    elif method == "tools/list":
        send_response({"jsonrpc": "2.0", "id": req_id, "result": {"tools": TOOLS}})
    elif method == "tools/call":
        name = params.get("name")
        args = params.get("arguments") or {}
        fn = TOOL_DISPATCH.get(name)
        if not fn:
            send_response(
                {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "content": [{"type": "text", "text": f"Unknown tool: {name}"}],
                        "isError": True,
                    },
                }
            )
            return
        try:
            result = fn(**args)
            send_response(
                {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "content": [
                            {
                                "type": "text",
                                "text": json.dumps(result, ensure_ascii=False, indent=2),
                            }
                        ],
                        "isError": False,
                    },
                }
            )
        except Exception as exc:
            send_response(
                {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "content": [{"type": "text", "text": f"Tool error: {exc}"}],
                        "isError": True,
                    },
                }
            )
    elif req_id is not None:
        send_response(
            {
                "jsonrpc": "2.0",
                "id": req_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"},
            }
        )


def main() -> None:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError as exc:
            sys.stderr.write(f"Invalid JSON input: {exc}\n")
            sys.stderr.flush()
            continue
        handle_request(req)


if __name__ == "__main__":
    main()
