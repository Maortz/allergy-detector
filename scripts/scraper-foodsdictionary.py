#!/usr/bin/env python3
"""Scraper for foodsdictionary.co.il - extracts Hebrew products with allergens."""

import argparse
import csv
import os
import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional

BASE_URL = "https://www.foodsdictionary.co.il"

ALLERGEN_MAP = {
    'בוטנים': 'a0000000-0000-0000-0000-000000000001',
    'אגוזים': 'a0000000-0000-0000-0000-000000000002',
    'ביצים': 'a0000000-0000-0000-0000-000000000003',
    'חלב': 'a0000000-0000-0000-0000-000000000004',
    'גלוטן': 'a0000000-0000-0000-0000-000000000005',
    'סויה': 'a0000000-0000-0000-0000-000000000006',
    'שומשום': 'a0000000-0000-0000-0000-000000000007',
    'דגים': 'a0000000-0000-0000-0000-000000000008',
}

SEARCH_TERMS = ['בוטנים', 'חלב', 'גלוטן', 'סויה', 'ביצים', 'שוקולד', 'חטיף', 'במבה']


def search_products(query: str) -> List[Dict]:
    """Search for products by query."""
    products = []
    search_url = f"{BASE_URL}/FoodsSearch.php"
    try:
        response = requests.get(
            search_url,
            params={'q': query},
            headers={'User-Agent': 'Mozilla/5.0'},
            timeout=10
        )
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            for item in soup.select('.product-item, .food-item, .search-result'):
                name = item.select_one('.name, .food-name, h3, h4')
                if name:
                    products.append({
                        'name_he': name.get_text(strip=True),
                        'url': item.find('a', href=True).get('href', '') if item.find('a') else ''
                    })
    except Exception as e:
        print(f"Search error for '{query}': {e}")
    return products


def parse_product_page(url: str) -> Optional[Dict]:
    """Parse individual product page for details."""
    if not url:
        return None
    try:
        response = requests.get(
            url if url.startswith('http') else f"{BASE_URL}{url}",
            headers={'User-Agent': 'Mozilla/5.0'},
            timeout=10
        )
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            
            name_he = (soup.select_one('.product-name, .food-name, h1') or {}).get_text(strip=True)
            
            barcode_elem = soup.select_one('.barcode, .product-code, .code')
            barcode = barcode_elem.get_text(strip=True) if barcode_elem else None
            
            ingredients = (soup.select_one('.ingredients, .singredients, .recipe') or {}).get_text(strip=True)
            
            allergens = []
            for allergen_he in ALLERGEN_MAP:
                if allergen_he in (ingredients or ''):
                    allergens.append({
                        'allergen_id': ALLERGEN_MAP[allergen_he],
                        'severity': 'contains'
                    })
            
            return {
                'name_he': name_he,
                'barcode': barcode,
                'ingredients': ingredients,
                'allergens': allergens
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
            resp = requests.post(url, json=p, headers=headers)
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
    
    anon_key = os.getenv('SUPABASE_PUBLIC_API_KEY')
    if not anon_key:
        env_file = os.path.join(os.path.dirname(__file__), '..', '.env.local')
        if os.path.exists(env_file):
            with open(env_file) as f:
                for line in f:
                    if line.startswith('SUPABASE_PUBLIC_API_KEY='):
                        anon_key = line.split('=')[1].strip()
                        break
    
    if not anon_key:
        print("Error: SUPABASE_PUBLIC_API_KEY not set")
        return
    
    products = []
    
    for term in SEARCH_TERMS:
        if len(products) >= args.limit:
            break
        print(f"Searching for: {term}")
        results = search_products(term)
        for r in results:
            if len(products) >= args.limit:
                break
            if r.get('url'):
                details = parse_product_page(r['url'])
                if details:
                    products.append(details)
    
    print(f"Collected {len(products)} products")
    
    if args.dry_run:
        for p in products:
            print(f"  - {p.get('name_he')}: {p.get('barcode')}")
        return
    
    if args.csv:
        with open('scraper-output.csv', 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['name_he', 'barcode', 'ingredients'])
            writer.writeheader()
            writer.writerows(products)
        print("Wrote scraper-output.csv")
    else:
        inserted = insert_to_supabase(products, anon_key, args.supabase_url)
        print(f"Inserted {inserted} products into Supabase")


if __name__ == '__main__':
    main()