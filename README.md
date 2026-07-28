# Agentic-Aided Deployment Beyond Localhost

This repository is the live application for a workshop demonstrating reviewed, agent-authored deployment and identity-scoped access with GitHub Actions and Tailscale.

## Local verification

```bash
npm test
npm start
curl http://127.0.0.1:3000/health
```

Simulate identity headers locally only to verify presentation:

```bash
curl -H 'Tailscale-User-Login: raj@example.com' -H 'Tailscale-User-Name: Raj Singh' http://127.0.0.1:3000/
```

These headers are trustworthy only when the backend cannot be reached directly and all requests arrive through Tailscale Serve. Network authorization remains in the tailnet policy repository.

## Deployment contract

The protected `main` branch builds the release, joins the tailnet with GitHub OIDC as an ephemeral `tag:ci-deployer` node, deploys to `TS_DEPLOY_HOST`, and verifies `TS_SERVICE_URL`. The workflow intentionally has no auth key, SSH key, registry password, public tunnel, or Funnel configuration.

See `docs/SETUP.md` and `docs/RUNBOOK.md` for administrative prerequisites and the stage sequence.
