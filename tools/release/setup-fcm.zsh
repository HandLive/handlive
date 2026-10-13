#!/bin/zsh
# Run from anywhere: this script cds to the hub root.
# Moves the Firebase admin SDK and google-services.json to ~/.config/handlive,
# then stores four FCM values as GitHub environment secrets.
# Prints secret names and destination paths only. Never prints secret values.
# Never opens the admin SDK file.
set -euo pipefail
set +x
export GH_PROMPT_DISABLED=1
export GH_PAGER=cat

hub_root="${0:A:h:h:h}"
cd "${hub_root}"

config_dir="${HOME}/.config/handlive"
mkdir -p "${config_dir}"
chmod 700 "${config_dir}"

setopt NULL_GLOB
adminsdk_files=( *-firebase-adminsdk-*.json )
if (( ${#adminsdk_files} > 1 )); then
  print -r -- "FAIL: more than one admin sdk file in the hub root" >&2
  exit 1
fi
if (( ${#adminsdk_files} == 1 )); then
  adminsdk_name="${adminsdk_files[1]:t}"
  adminsdk_dest="${config_dir}/${adminsdk_name}"
  if [[ -e "${adminsdk_dest}" ]]; then
    print -r -- "FAIL: admin sdk destination already exists" >&2
    exit 1
  fi
  mv -- "${adminsdk_files[1]}" "${adminsdk_dest}"
  chmod 600 "${adminsdk_dest}"
else
  existing=( "${config_dir}"/*-firebase-adminsdk-*.json )
  if (( ${#existing} != 1 )); then
    print -r -- "FAIL: admin sdk file not found in the hub root" >&2
    exit 1
  fi
  adminsdk_dest="${existing[1]}"
  chmod 600 "${adminsdk_dest}"
fi
print -r -- "admin sdk: ${adminsdk_dest}"

if [[ ! -f google-services.json ]]; then
  print -r -- "FAIL: google-services.json missing" >&2
  exit 1
fi

python3 -c '
import json
import subprocess
import sys

try:
    with open("google-services.json", encoding="utf-8") as handle:
        data = json.load(handle)
    client = data["client"][0]
    package = client["client_info"]["android_client_info"]["package_name"]
    project = data["project_info"]
    project_id = project["project_id"]
    sender = project["project_number"]
    app_id = client["client_info"]["mobilesdk_app_id"]
    api_key = client["api_key"][0]["current_key"]
except (OSError, json.JSONDecodeError, KeyError, IndexError, TypeError):
    sys.stderr.write("FAIL: google-services.json unreadable or missing fcm fields\n")
    sys.exit(1)

if package != "com.handlive.android":
    sys.stderr.write("FAIL: package_name is not com.handlive.android\n")
    sys.exit(1)

if isinstance(sender, bool) or not isinstance(sender, (str, int)):
    sys.stderr.write("FAIL: project_number\n")
    sys.exit(1)
sender = str(sender)

pairs = (
    ("HANDLIVE_FCM_PROJECT_ID", project_id),
    ("HANDLIVE_FCM_SENDER_ID", sender),
    ("HANDLIVE_FCM_APPLICATION_ID", app_id),
    ("HANDLIVE_FCM_API_KEY", api_key),
)
for name, value in pairs:
    if not isinstance(value, str) or value.strip() == "":
        sys.stderr.write("FAIL: empty " + name + "\n")
        sys.exit(1)

for name, value in pairs:
    # Omit --body. gh uses that flag as the secret itself, so --body - would
    # store a hyphen. Stdin is the documented path (gh secret set NAME < file).
    result = subprocess.run(
        [
            "gh",
            "secret",
            "set",
            name,
            "--env",
            "release",
            "--repo",
            "HandLive/handlive-android",
        ],
        input=value.encode("utf-8"),
        check=False,
    )
    if result.returncode != 0:
        sys.stderr.write("FAIL: gh secret set " + name + "\n")
        sys.exit(result.returncode)
'

services_dest="${config_dir}/google-services.json"
mv -- google-services.json "${services_dest}"
chmod 600 "${services_dest}"

print -r -- "secrets set:"
print -r -- "HANDLIVE_FCM_PROJECT_ID"
print -r -- "HANDLIVE_FCM_SENDER_ID"
print -r -- "HANDLIVE_FCM_APPLICATION_ID"
print -r -- "HANDLIVE_FCM_API_KEY"
print -r -- "admin sdk: ${adminsdk_dest}"
print -r -- "google-services: ${services_dest}"
