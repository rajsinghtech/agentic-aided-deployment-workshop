# Administrator Checklist

Use the root `README.md` for full commands. This checklist is for rehearsal.

## Tailnet

- [ ] Exact author and teammate Tailscale login names recorded.
- [ ] Example logins in the policy repository replaced with those exact values.
- [ ] `tag:ci-deployer` and `tag:demo-host` exist in `tagOwners`.
- [ ] Baseline policy validates and is applied.
- [ ] Baseline lets the author reach `svc:workshop-app:443`.
- [ ] Baseline denies the teammate access to the Service.
- [ ] CI can reach `tag:demo-host:22` and no application port.
- [ ] Tailscale SSH permits only the `deploy` account from `tag:ci-deployer`.
- [ ] HTTPS certificates are enabled.
- [ ] Funnel is not configured.
- [ ] `svc:workshop-app` exists and its host is approved.

## GitHub

- [ ] Application and private policy repositories exist.
- [ ] Branch protection and CODEOWNERS are configured.
- [ ] GitHub OIDC trust is restricted to the application repository and protected branch.
- [ ] The deployment trust credential grants only `auth_keys` and `tag:ci-deployer`.
- [ ] Policy test and policy apply use separate GitHub OIDC trust credentials.
- [ ] No Tailscale API token is stored in GitHub.
- [ ] `TS_CLIENT_ID`, `TS_AUDIENCE`, and `TS_DEPLOY_HOST` are repository variables.
- [ ] CI passes.
- [ ] Deployment passes from GitHub OIDC through Tailscale SSH.
- [ ] The team-access change is a separate pull request.

## Google Cloud Host

- [ ] Dedicated VPC and subnet.
- [ ] No external IP.
- [ ] No ingress firewall rules on the dedicated VPC.
- [ ] Private Google Access enabled.
- [ ] Cloud NAT and NAT error logging enabled.
- [ ] VPC Flow Logs enabled.
- [ ] Dedicated service account attached.
- [ ] Shielded VM protections enabled.
- [ ] App binds only to `127.0.0.1:3000`.
- [ ] Host has only `tag:demo-host`.
- [ ] Route acceptance and tailnet DNS acceptance are disabled unless required.
- [ ] VM joins through Google Cloud workload identity federation.
- [ ] VM trust matches the dedicated service account's immutable unique ID.
- [ ] No Tailscale auth key exists in instance metadata or on disk.

## End-to-End Evidence

- [ ] Author can open the Service before PR 2.
- [ ] Teammate cannot open the Service before PR 2.
- [ ] PR 2 grants only the workshop group to the Service on TCP 443.
- [ ] Both group members can open the Service after PR 2.
- [ ] Neither group member can SSH to the host.
- [ ] Reverting PR 2 revokes teammate access.
