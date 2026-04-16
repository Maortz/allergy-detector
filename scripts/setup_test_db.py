#!/usr/bin/env python3
"""Setup test database for integration tests."""

import argparse
import os
import subprocess
import sys


def check_supabase_running(url, anon_key):
    """Check if local Supabase is running."""
    try:
        import requests
        resp = requests.get(f"{url}/rest/v1/", headers={"apikey": anon_key, "Authorization": f"Bearer {anon_key}"}, timeout=5)
        return resp.status_code == 200
    except:
        return False


def apply_sql_file(sql_file):
    """Apply SQL file via psql."""
    try:
        result = subprocess.run([
            'psql', '-h', 'localhost', '-p', '54322',
            '-U', 'postgres', '-f', sql_file
        ], capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        print("Error: psql not found. Install PostgreSQL client.")
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply-schema', action='store_true')
    parser.add_argument('--apply-seed', action='store_true')
    args = parser.parse_args()

    supabase_url = os.getenv('SUPABASE_URL', 'http://127.0.0.1:54321')
    anon_key = os.getenv('SUPABASE_PUBLIC_API_KEY', '')

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
        sys.exit(1)

    print(f"Checking Supabase at {supabase_url}...")
    if not check_supabase_running(supabase_url, anon_key):
        print("Error: Supabase is not running. Run 'supabase start' first.")
        sys.exit(1)

    project_root = os.path.dirname(os.path.dirname(__file__))
    schema_file = os.path.join(project_root, 'supabase', 'schema.sql')
    seed_file = os.path.join(project_root, 'supabase', 'seed.sql')

    if args.apply_schema:
        print("Applying schema.sql...")
        if apply_sql_file(schema_file):
            print("Schema applied")
        else:
            print("Failed to apply schema")
            sys.exit(1)

    if args.apply_seed:
        print("Applying seed.sql...")
        if apply_sql_file(seed_file):
            print("Seed data applied")
        else:
            print("Failed to apply seed data")
            sys.exit(1)

    print("Done!")


if __name__ == '__main__':
    main()