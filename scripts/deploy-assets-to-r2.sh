#!/usr/bin/env bash
set -euo pipefail

# This script is run by GitHub Actions after reviewed assets land on main, or
# when someone manually dispatches the workflow for a bootstrap/backfill sync.

ASSET_CDN_ROOT="${ASSET_CDN_ROOT:-https://assets.playprool.com}"
ASSET_PREFIX="${ASSET_PREFIX:-}"
ASSET_ROOTS="${ASSET_ROOTS:-images documents animations data fonts}"
VERIFY_ASSET_PATH="${VERIFY_ASSET_PATH:-}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-auto}"

require_env() {
  local name="$1"

  if [[ -z "${!name:-}" ]]; then
    echo "Missing ${name}"
    exit 1
  fi
}

validate_configuration() {
  require_env "AWS_ACCESS_KEY_ID"
  require_env "AWS_SECRET_ACCESS_KEY"
  require_env "CLOUDFLARE_ACCOUNT_ID"
  require_env "R2_BUCKET"

  if [[ -z "${ASSET_ROOTS//[[:space:]]/}" ]]; then
    echo "ASSET_ROOTS must include at least one asset root"
    exit 1
  fi

  aws --version
  R2_ENDPOINT_URL="https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
}

upload_path() {
  local path="${1%/}"

  if [[ ! -d "${path}" ]]; then
    echo "Asset path does not exist or is not a directory: ${path}"
    exit 1
  fi

  # The destination keeps the repository path as the public CDN path. For
  # example, images/foo.svg becomes https://assets.playprool.com/images/foo.svg.
  echo "Uploading ${path}/ to R2 bucket ${R2_BUCKET}"

  # --recursive uploads everything nested under the folder.
  # --no-overwrite preserves immutable published URLs by refusing replacements.
  # Cache-Control is long-lived because versioned filenames carry cache busting.
  aws s3 cp "${path}" "s3://${R2_BUCKET}/${path}/" \
    --recursive \
    --endpoint-url "${R2_ENDPOINT_URL}" \
    --cache-control "public, max-age=31536000, immutable" \
    --exclude "README.md" \
    --exclude "*/README.md" \
    --exclude ".DS_Store" \
    --exclude "*/.DS_Store" \
    --no-overwrite \
    --only-show-errors \
    --no-progress
}

validate_asset_prefix() {
  case "${ASSET_PREFIX}" in
    /*|..|../*|*/../*|*/..)
      echo "ASSET_PREFIX must be a relative path inside an asset root"
      exit 1
      ;;
  esac

  local root
  for root in ${ASSET_ROOTS}; do
    if [[ "${ASSET_PREFIX}" == "${root}" || "${ASSET_PREFIX}" == "${root}/"* ]]; then
      return 0
    fi
  done

  echo "ASSET_PREFIX must start with one of: ${ASSET_ROOTS}"
  exit 1
}

upload_assets() {
  # Manual runs may pass asset_prefix to sync one folder recursively, such as
  # images/country/england. Empty asset_prefix syncs every configured root.
  if [[ -n "${ASSET_PREFIX}" ]]; then
    validate_asset_prefix
    upload_path "${ASSET_PREFIX}"
    return 0
  fi

  local root
  for root in ${ASSET_ROOTS}; do
    if [[ ! -d "${root}" ]]; then
      continue
    fi

    upload_path "${root}"
  done
}

verify_public_asset_url() {
  # Verification is optional because a bootstrap sync may not have one canonical
  # asset to check. Set VERIFY_ASSET_PATH to verify a specific published file.
  if [[ -z "${VERIFY_ASSET_PATH}" ]]; then
    echo "No VERIFY_ASSET_PATH configured; skipping public URL verification."
    return 0
  fi

  local asset_url="${ASSET_CDN_ROOT%/}/${VERIFY_ASSET_PATH#/}"

  echo "Verifying ${asset_url}"
  curl --fail --silent --show-error --location --max-time 30 --range 0-0 --output /dev/null "${asset_url}"
}

validate_configuration
upload_assets
verify_public_asset_url
