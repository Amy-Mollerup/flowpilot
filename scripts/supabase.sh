#!/usr/bin/env bash
# Supabase helpers for FlowPilot. Usage: source "$FLOWPILOT_HOME/scripts/supabase.sh"
# Reads $FLOWPILOT_ENV (default: $FLOWPILOT_HOME/.env, then ~/.env).
# Needs SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.
# sb_sql also needs SUPABASE_DB_HOST, SUPABASE_DB_USER and SUPABASE_DB_PASSWORD
# (Supabase dashboard > Connect > Session/Transaction pooler).

_fp_env="${FLOWPILOT_ENV:-${FLOWPILOT_HOME:-$HOME/flowpilot}/.env}"
[[ -f "$_fp_env" ]] || _fp_env="$HOME/.env"

eval "$(python3 - "$_fp_env" <<'PY'
import shlex, sys
with open(sys.argv[1]) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, _, value = line.partition('=')
        if len(value) >= 2 and value[0] == value[-1] and value[0] in '"\'':
            value = value[1:-1]
        print(f'export {key}={shlex.quote(value)}')
PY
)"

_sb_headers=(-H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

# sb_query <table> [postgrest_params]
sb_query() {
    local url="${SUPABASE_URL}/rest/v1/$1"
    [[ -n "${2:-}" ]] && url="${url}?$2"
    curl -sf "${_sb_headers[@]}" -H "Accept: application/json" "$url"
}

# sb_insert <table> <json>
sb_insert() {
    curl -sf -X POST "${_sb_headers[@]}" -H "Content-Type: application/json" \
        -H "Prefer: return=representation" -d "$2" "${SUPABASE_URL}/rest/v1/$1"
}

# sb_update <table> <postgrest_filter> <json>
sb_update() {
    curl -sf -X PATCH "${_sb_headers[@]}" -H "Content-Type: application/json" \
        -H "Prefer: return=representation" -d "$3" "${SUPABASE_URL}/rest/v1/$1?$2"
}

# sb_upsert <table> <json>   (merges on primary key)
sb_upsert() {
    curl -sf -X POST "${_sb_headers[@]}" -H "Content-Type: application/json" \
        -H "Prefer: return=representation,resolution=merge-duplicates" -d "$2" "${SUPABASE_URL}/rest/v1/$1"
}

# sb_delete <table> <postgrest_filter>
sb_delete() {
    curl -sf -X DELETE "${_sb_headers[@]}" "${SUPABASE_URL}/rest/v1/$1?$2"
}

# sb_rpc <function_name> [json_args]
sb_rpc() {
    local body="${2:-}"
    [[ -z "$body" ]] && body='{}'
    curl -sf -X POST "${_sb_headers[@]}" -H "Content-Type: application/json" \
        -d "$body" "${SUPABASE_URL}/rest/v1/rpc/$1"
}

# sb_sql <sql>   (direct Postgres via psql; for DDL and joins PostgREST can't do)
sb_sql() {
    if [[ -z "${SUPABASE_DB_PASSWORD:-}" || -z "${SUPABASE_DB_HOST:-}" || -z "${SUPABASE_DB_USER:-}" ]]; then
        echo "Error: set SUPABASE_DB_HOST, SUPABASE_DB_USER and SUPABASE_DB_PASSWORD in your .env" >&2
        return 1
    fi
    PGPASSWORD="$SUPABASE_DB_PASSWORD" psql \
        "host=${SUPABASE_DB_HOST} port=${SUPABASE_DB_PORT:-6543} dbname=postgres user=${SUPABASE_DB_USER} sslmode=require" \
        -c "$1"
}
