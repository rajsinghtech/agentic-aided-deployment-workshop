# Administrative Setup

The supplied Tailscale workload identity must be configured for the exact GitHub OIDC identity used by this repository and must include the `auth_keys` scope plus `tag:ci-deployer`. Set these GitHub environment variables on `production`:

- `TS_CLIENT_ID`
- `TS_AUDIENCE`
- The service URL is `https://workshop-app.rajsingh.ts.net`.

For the self-contained workshop path, the GitHub-hosted runner is the ephemeral deployment machine. It runs the reviewed application on loopback and advertises `svc:workshop-app` for up to three hours. This deliberately avoids a public URL and every stored deployment credential.

A Docker-based host script remains in `deploy/activate-workshop-release` for the follow-on persistent-host exercise.

No long-lived deployment credential belongs in GitHub.
