# Administrative Setup

The supplied Tailscale workload identity must be configured for the exact GitHub OIDC identity used by this repository and must include the `auth_keys` scope plus `tag:ci-deployer`. Set these GitHub environment variables on `production`:

- `TS_CLIENT_ID`
- `TS_AUDIENCE`
- `TS_DEPLOY_HOST=agentic-workshop-host`
- The service URL is `https://workshop-app.rajsingh.ts.net`.

The target is a persistent Google Cloud VM in a dedicated network with no inbound firewall rules. GitHub Actions reaches it only as an ephemeral `tag:ci-deployer` node over Tailscale SSH. The application binds to loopback and `svc:workshop-app` provides the stable HTTPS name.

A Docker-based host script remains in `deploy/activate-workshop-release` for the follow-on persistent-host exercise.

No long-lived deployment credential belongs in GitHub.
