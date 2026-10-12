#!/bin/zsh
# One run from the hub root: confirm the four FCM secrets, merge the Android
# play-bundle branch, download the signed Play bundle built on CI, then merge the hub branch.
# Status lines and secret names only. Secret values are never printed.
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

fcm_secrets=(
  HANDLIVE_FCM_PROJECT_ID
  HANDLIVE_FCM_SENDER_ID
  HANDLIVE_FCM_APPLICATION_ID
  HANDLIVE_FCM_API_KEY
)

step="check fcm secrets"
secret_status=0
secret_list="$(gh secret list --env release --repo HandLive/handlive-android)" || secret_status=$?
if [[ "${secret_status}" -ne 0 ]]; then
  die " could not list release secrets"
fi
missing_secrets=()
for name in "${fcm_secrets[@]}"; do
  present=0
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    field="${line%%[[:space:]]*}"
    if [[ "${field}" == "${name}" ]]; then
      present=1
      break
    fi
  done <<< "${secret_list}"
  if [[ "${present}" -eq 0 ]]; then
    missing_secrets+=("${name}")
  fi
done
if (( ${#missing_secrets} )); then
  trap - ERR
  print -r -- "FAIL: ${step}" >&2
  print -r -- "missing secrets:" >&2
  for name in "${missing_secrets[@]}"; do
    print -r -- "${name}" >&2
  done
  print -r -- "run tools/release/setup-fcm.zsh" >&2
  exit 1
fi
print -r -- "ok: ${step}"

step="android branch"
cd "${android_dir}"
branch="$(git branch --show-current)"
if [[ "${branch}" != "chore/play-bundle-ci" ]]; then
  die " branch is ${branch:-detached}"
fi
print -r -- "ok: ${step}"

step="android index"
index_status=0
git diff --cached --quiet || index_status=$?
if [[ "${index_status}" -eq 1 ]]; then
  trap - ERR
  print -r -- "FAIL: ${step} staged changes remain" >&2
  git diff --cached --name-only >&2 || true
  exit 1
fi
if [[ "${index_status}" -ne 0 ]]; then
  die " git diff --cached failed"
fi
print -r -- "ok: ${step}"

step="android commits"
git fetch origin
ahead="$(git rev-list --count origin/main..HEAD)"
if [[ "${ahead}" -eq 0 ]]; then
  die " no commits beyond origin/main"
fi
print -r -- "ok: ${step}"

step="android pull request state"
pr_state_status=0
pr_state="$(gh pr view --json state --jq .state 2>/dev/null)" || pr_state_status=$?
if [[ "${pr_state_status}" -eq 0 && "${pr_state}" == "MERGED" ]]; then
  die " pull request already merged"
fi
print -r -- "ok: ${step}"

step="android push"
git push -u origin chore/play-bundle-ci
print -r -- "ok: ${step}"

step="android pull request"
pr_status=0
pr_number="$(gh pr view --json number --jq .number 2>/dev/null)" || pr_status=$?
if [[ "${pr_status}" -eq 0 && -n "${pr_number}" ]]; then
  print -r -- "ok: ${step} already open"
else
  gh pr create \
    --base main \
    --title "ci(release): sign the release build and build a Play bundle on CI" \
    --body "Sign the release on CI with the release keystore in the release environment. The play-bundle workflow uploads the AAB and mapping.txt."
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
  --subject "ci(release): sign the release build and build a Play bundle on CI" \
  --body "Sign the release on CI with the release keystore in the release environment. The play-bundle workflow uploads the AAB and mapping.txt.

Signed-off-by: Hồ Xuân Dũng <me@hxd.vn>"
print -r -- "ok: ${step}"

step="android update main"
git checkout main
git pull --ff-only
print -r -- "ok: ${step}"

step="android workflow on main"
workflow_on_main=0
gh api "repos/HandLive/handlive-android/contents/.github/workflows/play-bundle.yml?ref=main" >/dev/null || workflow_on_main=$?
if [[ "${workflow_on_main}" -ne 0 ]]; then
  die " play-bundle.yml is not on main"
fi
print -r -- "ok: ${step}"

# 30s skew so the newest play-bundle run on main is the one this dispatch created.
step="android workflow"
dispatched_after="$(date -u -v-30S +%Y-%m-%dT%H:%M:%SZ)"
gh workflow run play-bundle.yml --ref main --repo HandLive/handlive-android
print -r -- "ok: ${step}"

step="android workflow run"
run_id=""
attempt=0
while [[ -z "${run_id}" ]]; do
  run_id="$(
    gh run list \
      --workflow play-bundle.yml \
      --branch main \
      --repo HandLive/handlive-android \
      --limit 5 \
      --json databaseId,createdAt \
      --jq "[.[] | select(.createdAt >= \"${dispatched_after}\")] | .[0].databaseId // empty"
  )"
  if [[ -n "${run_id}" ]]; then
    break
  fi
  attempt=$((attempt + 1))
  if [[ "${attempt}" -ge 30 ]]; then
    die " workflow run did not appear"
  fi
  sleep 5
done
print -r -- "ok: ${step} ${run_id}"

step="android workflow watch"
gh run watch "${run_id}" --exit-status --repo HandLive/handlive-android
print -r -- "ok: ${step}"

step="android workflow download"
cd "${hub_root}"
mkdir -p android/app/build/outputs/play
gh run download "${run_id}" -n play-bundle -D android/app/build/outputs/play/ --repo HandLive/handlive-android
aab_path="${hub_root}/android/app/build/outputs/play/app-gms-release.aab"
mapping_path="${hub_root}/android/app/build/outputs/play/mapping.txt"
if [[ ! -f "${aab_path}" || ! -f "${mapping_path}" ]]; then
  die ""
fi
print -r -- "ok: ${step}"
print -r -- "aab: ${aab_path}"
print -r -- "mapping: ${mapping_path}"

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
