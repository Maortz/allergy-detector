#!/usr/bin/env python3
"""Scraper for foodsdictionary.co.il - extracts Hebrew products."""

import argparse
import csv
import json
import os
import time
from urllib.parse import urlencode

import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional

BASE_URL = "https://www.foodsdictionary.co.il"

SEARCH_TERMS = ['בוטנים', 'חלב', 'גלוטן', 'סויה', 'ביצים', 'שוקולד', 'חטיף', 'במבה']


def get_suggestions(session: requests.Session, query: str) -> List[str]:
    """Get autocomplete suggestions for a query."""
    try:
        response = session.get(
            f"{BASE_URL}/services/c/getSuggestions.php",
            params={'q': query.encode('utf-8')},
            headers={'User-Agent': 'Mozilla/5.0'},
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            return data.get('suggestions', [])
    except Exception as e:
        print(f"Suggestions error for '{query}': {e}")
    return []


def search_products(session: requests.Session, query: str) -> List[Dict]:
    """Search for products by query using FoodsSearch.php."""
    products = []
    try:
        response = session.get(
            f"{BASE_URL}/FoodsSearch.php",
            params={'food': query.encode('utf-8')},
            headers={'User-Agent': 'Mozilla/5.0'},
            timeout=10
        )
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            for item in soup.select('.col-limit'):
                link = item.select_one('a')
                title = item.select_one('.card-title')
                if link and title:
                    products.append({
                        'name_he': title.get_text(strip=True),
                        'url': link.get('href', '')
                    })
    except Exception as e:
        print(f"Search error for '{query}': {e}")
    return products


def parse_product_page(session: requests.Session, url: str) -> Optional[Dict]:
    """Parse individual product page for details."""
    if not url:
        return None
    full_url = url if url.startswith('http') else f"{BASE_URL}{url}"
    try:
        response = session.get(
            full_url,
            headers={'User-Agent': 'Mozilla/5.0'},
            timeout=10
        )
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            
            name_elem = soup.select_one('h1')
            name_he = name_elem.get_text(strip=True) if name_elem else None
            
            calories_elem = soup.select_one('[title*="קלוריות"]')
            calories = calories_elem.get_text(strip=True) if calories_elem else None
            
            return {
                'name_he': name_he,
                'calories': calories,
                'url': url,
            }
    except Exception as e:
        print(f"Parse error for '{url}': {e}")
    return None


def insert_to_supabase(products: List[Dict], anon_key: str, supabase_url: str = "http://127.0.0.1:54321") -> int:
    """Insert products to local Supabase."""
    url = f"{supabase_url}/rest/v1/products"
    headers = {
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    inserted = 0
    for p in products:
        try:
            data = {'name_he': p.get('name_he'), 'ingredients': p.get('calories')}
            resp = requests.post(url, json=data, headers=headers)
            if resp.status_code in (200, 201):
                inserted += 1
        except Exception as e:
            print(f"Insert error: {e}")
    return inserted


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true', help='Print what would be scraped without inserting')
    parser.add_argument('--csv', action='store_true', help='Output CSV instead of inserting')
    parser.add_argument('--limit', type=int, default=30, help='Maximum products to collect')
    parser.add_argument('--supabase-url', default='http://127.0.0.1:54321')
    args = parser.parse_args()
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_file = os.path.join(script_dir, '..', 'env.local.json')
    env_file = os.path.normpath(env_file.replace('\\', '/'))
    with open(env_file) as f:
        env = json.load(f)
        anon_key = env.get('SUPABASE_KEY')
    
    session = requests.Session()
    products = []
    seen_urls = set()
    
    for term in SEARCH_TERMS:
        if len(products) >= args.limit:
            break
        print(f"Getting suggestions for: {term}")
        suggestions = get_suggestions(session, term)
        
        for suggestion in suggestions:
            if len(products) >= args.limit:
                break
            print(f"  Searching: {suggestion}")
            results = search_products(session, suggestion)
            
            for r in results:
                if len(products) >= args.limit:
                    break
                url = r.get('url')
                if url and url not in seen_urls:
                    seen_urls.add(url)
                    details = parse_product_page(session, url)
                    if details:
                        products.append(details)
                        time.sleep(0.5)
    
    print(f"Collected {len(products)} products")
    
    if args.dry_run:
        for p in products:
            name = p.get('name_he', 'unknown')
            url = p.get('url', '')
            print(f"  - {name}")
            print(f"    {url}")
        return
    
    if args.csv:
        with open('scraper-output.csv', 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['name_he', 'calories', 'url'], extrasaction='ignore')
            writer.writeheader()
            writer.writerows(products)
        print("Wrote scraper-output.csv")
    else:
        inserted = insert_to_supabase(products, anon_key, args.supabase_url)
        print(f"Inserted {inserted} products into Supabase")


if __name__ == '__main__':
    main()