# Website image digests (2026-10-05)

Closes the digest part of the LOW finding `docker-compose.yml` OUTDATED-DEPENDENCY in `security-scan-beta2-2026-10-04.md`.

## Pinned images

All four are multi-arch OCI image indexes (`MediaType: application/vnd.oci.image.index.v1+json`), queried from
Docker Hub with `docker buildx imagetools inspect <image:tag>` (Docker 29.4.0) on 2026-10-05. The tag is kept for
readability.

| Service | Image:tag | Index digest |
|---------|-----------|--------------|
| db | `mariadb:10.11` | `sha256:7db29378d4fdab73f8123bbc2b48905c90d1a4b00cf848b028f1e81e623257f2` |
| php | `wordpress:php8.3-fpm-alpine` | `sha256:0163efd355d714a19b86fe438d7c2f3d580fd375d03831da704a9cd87232c680` |
| nginx | `nginx:alpine` | `sha256:df221db836e1754089190208cee7eeda94f233197056426eda74a43ab1abeac2` |
| wpcli | `wordpress:cli-php8.3` | `sha256:36243da432a0f0a3b56dc3240ecee9b159108d71305e7c064d987a20a465bfde` |

## Verification

- `DB_NAME=a DB_USER=b DB_PASSWORD=c DB_ROOT_PASSWORD=d SITE_URL=http://x docker compose -f website/docker-compose.yml --profile tools config --images`
  parses and prints the four pinned references (dummy env, no `.env` written). No other compose file exists under `website/`.
- Images were not pulled or run; setup/seed was not re-run (no ports, volumes, env or install logic changed).
- `tools/docs/check_bilingual_docs.py` run; result in the commit step below.

## Docs

`docs/website.md` + `docs/website.vi.md`: new section "Pinned images and how to update them" (refresh command
`docker buildx imagetools inspect <image:tag> | grep '^Digest:'`). Scan report row 22 and the open-LOW line updated.

## Commits

Branch `worktree-agent-a3e3ecb17fbbe8541`: see `git log` (fix(website) compose; docs bilingual + scan report + this report).

## Unresolved questions

- Refresh cadence ("about monthly") is a suggestion; no automation (Renovate/Dependabot can bump `tag@digest` pins) was added: owner call.
- The `nginx:alpine` and `mariadb:10.11` tags float within their series; a digest bump may move minor versions.
