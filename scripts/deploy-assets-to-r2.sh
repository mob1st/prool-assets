#!/usr/bin/env bash
set -euo pipefail

# This script is run by GitHub Actions after reviewed assets land on main, or
# when someone manually dispatches the workflow for a specific file/folder sync.

ASSET_FORMAT_RULES="${ASSET_FORMAT_RULES:-images=svg,webp documents=pdf animations=json data=json}"
ASSET_PATH="${ASSET_PATH:-}"
ASSET_ROOTS="${ASSET_ROOTS:-images documents animations data}"
PUSH_BEFORE_SHA="${PUSH_BEFORE_SHA:-}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-auto}"

AWS_INCLUDE_ARGS=()

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

  if [[ -z "${ASSET_FORMAT_RULES//[[:space:]]/}" ]]; then
    echo "ASSET_FORMAT_RULES must include at least one root=format list"
    exit 1
  fi

  if [[ -z "${ASSET_ROOTS//[[:space:]]/}" ]]; then
    echo "ASSET_ROOTS must include at least one asset root"
    exit 1
  fi

  validate_format_rules

  aws --version
  R2_ENDPOINT_URL="https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
}

is_asset_root() {
  local root="$1"
  local allowed_root

  for allowed_root in ${ASSET_ROOTS}; do
    if [[ "${root}" == "${allowed_root}" ]]; then
      return 0
    fi
  done

  return 1
}

validate_format_rules() {
  local ext
  local rule
  local root
  local rule_exts

  for rule in ${ASSET_FORMAT_RULES}; do
    if [[ "${rule}" != *=* ]]; then
      echo "Invalid ASSET_FORMAT_RULES entry: ${rule}"
      exit 1
    fi

    root="${rule%%=*}"
    rule_exts="${rule#*=}"

    if [[ -z "${root}" || -z "${rule_exts}" ]]; then
      echo "Invalid ASSET_FORMAT_RULES entry: ${rule}"
      exit 1
    fi

    if ! is_asset_root "${root}"; then
      echo "ASSET_FORMAT_RULES includes unknown root: ${root}"
      exit 1
    fi

    for ext in ${rule_exts//,/ }; do
      if [[ -z "${ext}" || "${ext}" == *"."* || "${ext}" == *"/"* ]]; then
        echo "Invalid extension in ASSET_FORMAT_RULES entry: ${rule}"
        exit 1
      fi
    done
  done
}

asset_root_for_path() {
  local path="$1"

  printf "%s" "${path%%/*}"
}

allowed_extensions_for_root() {
  local root="$1"
  local rule
  local rule_root

  for rule in ${ASSET_FORMAT_RULES}; do
    rule_root="${rule%%=*}"
    if [[ "${rule_root}" == "${root}" ]]; then
      printf "%s" "${rule#*=}"
      return 0
    fi
  done

  return 1
}

build_aws_include_args_for_root() {
  local root="$1"
  local allowed_exts
  local ext

  if ! allowed_exts="$(allowed_extensions_for_root "${root}")"; then
    echo "No publish formats configured for ${root}/"
    exit 1
  fi

  AWS_INCLUDE_ARGS=(--exclude "*")
  for ext in ${allowed_exts//,/ }; do
    AWS_INCLUDE_ARGS+=(--include "*.${ext}")
  done
}

is_skipped_file() {
  local path="$1"

  [[ "${path}" == README.md || "${path}" == */README.md || "${path}" == .DS_Store || "${path}" == */.DS_Store ]]
}

validate_asset_root() {
  local path="$1"
  local root

  for root in ${ASSET_ROOTS}; do
    if [[ "${path}" == "${root}" || "${path}" == "${root}/"* ]]; then
      return 0
    fi
  done

  echo "ASSET_PATH must start with one of: ${ASSET_ROOTS}"
  exit 1
}

normalize_asset_path() {
  local path="${1#/}"
  while [[ "${path}" == */ ]]; do
    path="${path%/}"
  done
  while [[ "${path}" == *//* ]]; do
    path="${path//\/\//\/}"
  done

  case "${path}" in
    ""|/*|..|../*|*/../*|*/..|*\\*)
      echo "ASSET_PATH must be a repo path inside an asset root"
      exit 1
      ;;
  esac

  validate_asset_root "${path%\/*}"

  printf "%s" "${path}"
}

validate_allowed_file_extension() {
  local file="$1"
  local root
  local ext
  local allowed_exts
  local allowed_ext

  if [[ "${file}" != *.* ]]; then
    echo "Asset file must have an allowed extension: ${file}"
    exit 1
  fi

  root="$(asset_root_for_path "${file}")"
  if ! allowed_exts="$(allowed_extensions_for_root "${root}")"; then
    echo "No publish formats configured for ${root}/"
    exit 1
  fi

  ext="${file##*.}"
  for allowed_ext in ${allowed_exts//,/ }; do
    if [[ "${ext}" == "${allowed_ext}" ]]; then
      return 0
    fi
  done

  echo "Asset file extension .${ext} is not allowed under ${root}/. Allowed: ${allowed_exts//,/ }"
  exit 1
}

validate_folder_file_extensions() {
  local folder="$1"
  local file

  while IFS= read -r file; do
    if is_skipped_file "${file}"; then
      continue
    fi

    validate_allowed_file_extension "${file}"
  done < <(find "${folder}" -type f -print)
}

upload_file() {
  local file="$1"

  if is_skipped_file "${file}"; then
    echo "Skipping non-asset file: ${file}"
    return 0
  fi

  if [[ -d "${file}" ]]; then
    echo "ASSET_PATH points to a folder. Use /${file}/* to upload it recursively."
    exit 1
  fi

  if [[ ! -f "${file}" ]]; then
    echo "Asset file does not exist: ${file}"
    exit 1
  fi

  validate_allowed_file_extension "${file}"

  # Repository paths are public CDN paths. For example, images/foo.svg becomes
  # https://assets.playprool.com/images/foo.svg.
  echo "Uploading file ${file} to R2 bucket ${R2_BUCKET}"
  aws s3 cp "${file}" "s3://${R2_BUCKET}/${file}" \
    --endpoint-url "${R2_ENDPOINT_URL}" \
    --cache-control "public, max-age=31536000, immutable" \
    --no-overwrite \
    --only-show-errors \
    --no-progress
}

upload_folder() {
  local folder="$1"
  local root

  if [[ ! -d "${folder}" ]]; then
    echo "Asset folder does not exist: ${folder}"
    exit 1
  fi

  root="$(asset_root_for_path "${folder}")"
  validate_folder_file_extensions "${folder}"
  build_aws_include_args_for_root "${root}"

  echo "Uploading folder ${folder}/ to R2 bucket ${R2_BUCKET}"

  # --recursive uploads everything nested under the folder.
  # --no-overwrite preserves immutable published URLs by refusing replacements.
  # Cache-Control is long-lived because versioned filenames carry cache busting.
  aws s3 cp "${folder}" "s3://${R2_BUCKET}/${folder}/" \
    --recursive \
    --endpoint-url "${R2_ENDPOINT_URL}" \
    --cache-control "public, max-age=31536000, immutable" \
    --exclude "README.md" \
    --exclude "*/README.md" \
    --exclude ".DS_Store" \
    --exclude "*/.DS_Store" \
    "${AWS_INCLUDE_ARGS[@]}" \
    --no-overwrite \
    --only-show-errors \
    --no-progress
}

upload_manual_asset_path() {
  local path
  path="$(normalize_asset_path "${ASSET_PATH}")"

  case "${path}" in
    *"*"*)
      if [[ "${path}" != */\* ]]; then
        echo "ASSET_PATH only supports * at the end of a folder path, such as /images/country/england/*"
        exit 1
      fi

      upload_folder "${path%/\*}"
      ;;
    *)
      upload_file "${path}"
      ;;
  esac
}

upload_changed_push_files() {
  local before="${PUSH_BEFORE_SHA}"
  local after="${GITHUB_SHA:-HEAD}"
  local file
  local changed_files
  local uploaded=0

  if [[ -z "${before}" || "${before}" == "0000000000000000000000000000000000000000" ]]; then
    echo "Could not determine previous push SHA; refusing to guess upload scope."
    exit 1
  fi

  changed_files="$(git diff --name-only --diff-filter=AMR "${before}" "${after}" -- ${ASSET_ROOTS})"

  while IFS= read -r file; do
    if [[ -z "${file}" || ! -f "${file}" ]] || is_skipped_file "${file}"; then
      continue
    fi

    upload_file "${file}"
    uploaded=1
  done <<< "${changed_files}"

  if [[ "${uploaded}" -eq 0 ]]; then
    echo "No changed asset files to upload."
  fi
}

upload_assets() {
  if [[ -n "${ASSET_PATH}" ]]; then
    upload_manual_asset_path
    return 0
  fi

  if [[ "${GITHUB_EVENT_NAME:-}" == "push" ]]; then
    upload_changed_push_files
    return 0
  fi

  echo "ASSET_PATH is required. Use a file path or a folder path ending in /*."
  exit 1
}

validate_configuration
upload_assets
