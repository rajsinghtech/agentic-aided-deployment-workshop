# Administrative Setup

The supplied Tailscale workload identity must be configured for the exact GitHub OIDC identity used by this repository and must include the `auth_keys` scope plus `tag:ci-deployer`. Set these GitHub environment variables on `production`:

- `TS_CLIENT_ID`
- `TS_AUDIENCE`
- `TS_DEPLOY_HOST`
- `TS_SERVICE_URL`

The target is a persistent tagged Linux node with Tailscale SSH enabled, an existing `deploy` account, and `/home/deploy/bin/activate-workshop-release` installed. The workflow streams a tar archive to that command over standard input. The app must bind to loopback and Tailscale Serve must proxy the named service over HTTPS.

A Docker-based host script is provided in `deploy/activate-workshop-release` and should be installed as `/home/deploy/bin/activate-workshop-release` with mode `0755`.

No long-lived deployment credential belongs in GitHub.
