#!/bin/zsh
# One run from the hub root: check local Gradle keys, merge the Android R8 branch,
# build a signed gmsRelease AAB, then merge the hub branch.
# Status lines and missing key names only. Property values are never printed.
# Hub has no CI. Do not use `gh pr checks --watch` there: with no checks it exits
# on "no checks reported" and would block the merge. Wait only when checks exist.
set -euo pipefail
set +x

export GH_PAGER="cat"
export GIT_PAGER="cat"
export GIT_EDITOR="true"
export GIT_TERMINAL_PROMPT="0"

step="start"
trap 'trap - ERR; print -r -- "FAIL: ${step}" >&2; exit 1' ERR

die() {
  trap - ERR
  print -r -- "FAIL: ${step}$1" >&2
  exit 1
}

hub_root="${0:A:h:h:h}"
cd "${hub_root}"
android_dir="${hub_root}/android"

required_keys=(
  handlive.relayHost
  handlive.relayExtraPins
  handlive.fcm.applicationId
  handlive.fcm.apiKey
  handlive.fcm.projectId
  handlive.fcm.senderId
  handlive.upload.storeFile
  handlive.upload.storePassword
  handlive.upload.keyAlias
  handlive.upload.keyPassword
)
props_file="${HOME}/.gradle/gradle.properties"

step="check gradle properties"
missing_keys=()
if [[ ! -f "${props_file}" ]]; then
  missing_keys=("${required_keys[@]}")
else
  for key in "${required_keys[@]}"; do
    found="$(
      awk -v key="${key}" '
        /^[[:space:]]*#/ { next }
        {
          eq = index($0, "=")
          if (eq == 0) next
          k = substr($0, 1, eq - 1)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
          if (k != key) next
          v = substr($0, eq + 1)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
          if (length(v) > 0) { print "yes"; exit }
        }
      ' "${props_file}" || true
    )"
    if [[ "${found}" != "yes" ]]; then
      missing_keys+=("${key}")
    fi
  done
fi
if (( ${#missing_keys} )); then
  trap - ERR
  print -r -- "FAIL: ${step}" >&2
  print -r -- "missing keys:" >&2
  for key in "${missing_keys[@]}"; do
    print -r -- "${key}" >&2
  done
  exit 1
fi
print -r -- "ok: ${step}"

step="android push"
cd "${android_dir}"
git push -u origin chore/release-r8
print -r -- "ok: ${step}"

step="android pull request"
pr_status=0
pr_number="$(gh pr view --json number --jq .number 2>/dev/null)" || pr_status=$?
if [[ "${pr_status}" -eq 0 && -n "${pr_number}" ]]; then
  print -r -- "ok: ${step} already open"
else
  gh pr create \
    --base main \
    --title "build(release): enable R8 shrinking and obfuscation" \
    --body "Enable R8 shrinking and obfuscation for the Android release build and ship mapping.txt with the Play upload."
  print -r -- "ok: ${step} opened"
fi

step="android checks"
attempt=0
while true; do
  checks_status=0
  checks_out="$(gh pr checks 2>&1)" || checks_status=$?
  case "${checks_out}" in
    *"no checks reported"*)
      attempt=$((attempt + 1))
      if [[ "${attempt}" -ge 12 ]]; then
        die " no checks reported"
      fi
      sleep 5
      continue
      ;;
  esac
  break
done
gh pr checks --watch
print -r -- "ok: ${step}"

step="android merge"
gh pr merge --squash --delete-branch \
  --subject "build(release): enable R8 shrinking and obfuscation" \
  --body "Enable R8 shrinking and obfuscation for the release build and ship mapping.txt with the Play upload.
Sign the release when upload key settings are present in gradle.properties.

Signed-off-by: Hồ Xuân Dũng <me@hxd.vn>"
print -r -- "ok: ${step}"

step="android update main"
git checkout main
git pull --ff-only
print -r -- "ok: ${step}"

step="android bundle gmsRelease"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="${JAVA_HOME}/bin:${PATH}"
./gradlew :app:bundleGmsRelease
print -r -- "ok: ${step}"

aab_path="${android_dir}/app/build/outputs/bundle/gmsRelease/app-gms-release.aab"
mapping_path="${android_dir}/app/build/outputs/mapping/gmsRelease/mapping.txt"

step="android verify signature"
if [[ ! -f "${aab_path}" ]]; then
  die ""
fi
verify_status=0
verify_out="$(jarsigner -verify "${aab_path}" 2>&1)" || verify_status=$?
if [[ "${verify_status}" -ne 0 ]]; then
  die ""
fi
case "${verify_out}" in
  *unsigned*)
    die ""
    ;;
esac
print -r -- "ok: ${step}"

cd "${hub_root}"

step="hub push"
git push -u origin fix/ios-ipad-screenshots-app-store-connect
print -r -- "ok: ${step}"

step="hub pull request"
pr_status=0
pr_number="$(gh pr view --json number --jq .number 2>/dev/null)" || pr_status=$?
if [[ "${pr_status}" -eq 0 && -n "${pr_number}" ]]; then
  print -r -- "ok: ${step} already open"
else
  gh pr create --base main --fill
  print -r -- "ok: ${step} opened"
fi

# No --watch: a hub PR with no CI exits "no checks reported". Poll only while checks are pending.
step="hub checks"
attempt=0
while true; do
  checks_status=0
  checks_out="$(gh pr checks 2>&1)" || checks_status=$?
  case "${checks_out}" in
    *"no checks reported"*)
      print -r -- "ok: ${step} none reported"
      break
      ;;
  esac
  if [[ "${checks_status}" -eq 0 ]]; then
    print -r -- "ok: ${step} passed"
    break
  fi
  if [[ "${checks_status}" -ne 8 ]]; then
    die ""
  fi
  attempt=$((attempt + 1))
  if [[ "${attempt}" -ge 30 ]]; then
    die " still pending"
  fi
  sleep 10
done

step="hub mergeable"
mergeable="UNKNOWN"
attempt=0
while [[ "${attempt}" -lt 6 ]]; do
  mergeable="$(gh pr view --json mergeable --jq .mergeable)"
  if [[ "${mergeable}" == "MERGEABLE" || "${mergeable}" == "CONFLICTING" ]]; then
    break
  fi
  attempt=$((attempt + 1))
  sleep 5
done
if [[ "${mergeable}" != "MERGEABLE" ]]; then
  die " ${mergeable}"
fi
print -r -- "ok: ${step}"

step="hub merge"
hub_subject="$(gh pr view --json title -q .title)"
gh pr merge --squash --delete-branch \
  --subject "${hub_subject}" \
  --body "Store screenshots, android #13 docs, Phase 4 stopped, the G5 guide, the Play Console guide, and the release script.

Signed-off-by: Hồ Xuân Dũng <me@hxd.vn>"
print -r -- "ok: ${step}"

step="print artifacts"
if [[ ! -f "${aab_path}" || ! -f "${mapping_path}" ]]; then
  die ""
fi
print -r -- "ok: ${step}"
print -r -- "aab: ${aab_path}"
print -r -- "mapping: ${mapping_path}"
