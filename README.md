# Agentic-Aided Deployment Beyond Localhost

This repository is a forkable workshop showing how an agent-assisted application moves from localhost to a private, identity-scoped Tailscale Service through reviewed GitHub changes.

The application is intentionally not trusted to authenticate users. Tailscale decides who can reach it before traffic reaches the application.

## What You Build

```text
developer or agent
       |
       | pull request
       v
GitHub repository -- CI --> reviewed main branch
                              |
                              | GitHub OIDC
                              v
                    ephemeral tag:ci-deployer
                              |
                              | Tailscale SSH
                              v
private GCP VM: tag:demo-host
  - no external IP
  - no inbound GCP firewall rules
  - app listens on 127.0.0.1:3000
  - Tailscale Service terminates HTTPS
                              |
                              v
              https://workshop-app.<tailnet>.ts.net
```

Access is a separate reviewed change in a tailnet-policy repository:

```json
{
  "src": ["group:workshop-team"],
  "dst": ["svc:workshop-app"],
  "ip": ["tcp:443"]
}
```

## Security Boundaries

- The VM has no external IP and no public inbound firewall rule.
- The application port is published only on VM loopback.
- GitHub Actions receives an ephemeral Tailscale identity from GitHub OIDC.
- The GCP host joins with its Google service-account identity through workload identity federation.
- CI can reach only the deployment host on TCP 22.
- Humans receive access to the named Service, not to the underlying VM.
- Tailscale Funnel is not used.
- The application contains no shared password or public authentication endpoint.
- Every deployment and access change is represented by a GitHub diff.

## Repositories

Use two repositories:

1. This application repository. It contains source, tests, deployment automation, and host bootstrap files.
2. A private policy repository based on [`rajsinghtech/agentic-aided-deployment-policy`](https://github.com/rajsinghtech/agentic-aided-deployment-policy). It contains the tailnet policy and the second pull request.

Keep the policy repository private because policy files commonly contain user login names.

## Prerequisites

You need:

- A Tailscale tailnet where you are Owner, Admin, or Network admin.
- Two Tailscale users for the before/after access demonstration.
- A GitHub account with Actions enabled.
- A Google Cloud project with billing and Compute Engine enabled.
- `git`, `gh`, `gcloud`, `curl`, and `jq` installed locally.
- Permission to create GitHub Actions and Google Cloud OIDC trust credentials in Tailscale.

The example uses Google Cloud, but the deployment host can be any persistent Linux machine that can make outbound connections and run Docker and Tailscale.

## Choose Your Values

Set these once in your shell. Use the exact login names shown on the Tailscale **Users** page, not display names.

```bash
export GITHUB_OWNER="your-github-user-or-org"
export APP_REPO="agentic-aided-deployment-workshop"
export POLICY_REPO="agentic-aided-deployment-policy"

export GCP_PROJECT="your-gcp-project"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"

export TS_TAILNET="your-tailnet-id"
export TS_DNS_NAME="your-tailnet-dns-name"
export TS_AUTHOR="author@example.com"
export TS_TEAMMATE="teammate@example.com"

export TS_SERVICE="svc:workshop-app"
export TS_SERVICE_URL="https://workshop-app.${TS_DNS_NAME}.ts.net"
export TS_DEPLOY_HOST="agentic-workshop-host"
```

Find the values in Tailscale:

- Tailnet ID: **Admin console > Settings > General**.
- DNS name: **Admin console > DNS** or the suffix shown by `tailscale status` on a connected device.
- User logins: **Admin console > Users**.

## Step 1: Fork or Copy the Repositories

Fork this repository and create a private copy of the policy repository.

```bash
gh repo fork rajsinghtech/agentic-aided-deployment-workshop \
  --clone \
  --fork-name "$APP_REPO"

gh repo create "$GITHUB_OWNER/$POLICY_REPO" \
  --private \
  --description "GitOps policy for the private deployment workshop"
```

Copy the contents of the example policy repository into your private policy repository. Do not copy any credential from this workshop environment.

## Step 2: Verify the Application Locally

```bash
npm test
npm start
curl --fail http://127.0.0.1:3000/health
```

Expected health response:

```json
{
  "status": "ok",
  "service": "agentic-aided-deployment-workshop",
  "uptimeSeconds": 1
}
```

You can simulate Tailscale identity headers only for presentation testing:

```bash
curl \
  -H "Tailscale-User-Login: ${TS_AUTHOR}" \
  -H "Tailscale-User-Name: Workshop Author" \
  http://127.0.0.1:3000/
```

These headers are not trustworthy when a client can reach the backend directly. In the deployed design, only Tailscale Serve can reach the loopback backend and it removes spoofed identity headers before adding verified ones.

## Step 3: Create the Baseline Tailnet Policy

Copy `templates/policy.baseline.hujson` from this application repository into the private policy repository as `policy.hujson`. Replace:

- `AUTHOR_LOGIN` with `$TS_AUTHOR`.
- `TEAMMATE_LOGIN` with `$TS_TEAMMATE`.

The baseline must contain:

- `tag:ci-deployer` and `tag:demo-host`.
- Service host auto-approval for `svc:workshop-app`.
- CI-to-host TCP 22 access and a matching Tailscale SSH rule.
- Author-to-Service TCP 443 access.
- A policy test proving the teammate is denied.

If this is a disposable workshop tailnet, the baseline file can be the complete policy. If this is a shared tailnet, merge these sections into the existing policy instead of replacing unrelated rules.

Commit the baseline to the private policy repository. Step 5 configures GitHub OIDC identities that validate it on pull requests and apply the exact merged file. Participants do not create or store a Tailscale API token.

## Step 4: Define the Named Tailscale Service

Define `svc:workshop-app` in **Admin console > Services**:

- Name: `workshop-app`
- Port: `tcp:443`
- Description: `Agentic-aided private deployment workshop`

```text
https://workshop-app.<tailnet-dns-name>.ts.net
```

Enable HTTPS certificates for the tailnet. Do not enable Funnel.

## Step 5: Create the GitHub Workload Identities

Create separate identities for deployment, policy testing, and policy application. Separating them prevents an application deployment job from changing tailnet access.

### Application deployment identity

In **Tailscale Admin console > Settings > Trust credentials**:

1. Select **Credential > OpenID Connect**.
2. Choose GitHub Actions as the issuer.
3. Restrict the subject to your application repository and protected branch. A typical subject is:

   ```text
   repo:GITHUB_OWNER/APP_REPO:ref:refs/heads/main
   ```

4. Prefer additional claim restrictions for repository ID, owner ID, workflow, and branch when available.
5. Grant only the `auth_keys` scope.
6. Permit only `tag:ci-deployer`.
7. Copy the generated Client ID and Audience. They are identifiers, not passwords.

Add repository variables:

```bash
gh variable set TS_CLIENT_ID \
  --repo "$GITHUB_OWNER/$APP_REPO" \
  --body "YOUR_TAILSCALE_CLIENT_ID"

gh variable set TS_AUDIENCE \
  --repo "$GITHUB_OWNER/$APP_REPO" \
  --body "YOUR_TAILSCALE_AUDIENCE"

gh variable set TS_DEPLOY_HOST \
  --repo "$GITHUB_OWNER/$APP_REPO" \
  --body "$TS_DEPLOY_HOST"
```

The workflow requests `id-token: write`, exchanges the GitHub JWT for a short-lived Tailscale identity, and creates an ephemeral `tag:ci-deployer` node. The runner logs out automatically when the job finishes.

### Policy test identity

Create a second GitHub OIDC trust credential for the private policy repository:

1. Restrict it to pull-request jobs for `GITHUB_OWNER/POLICY_REPO`.
2. Grant `policy_file:read` and any read dependencies shown by the Tailscale trust-credential UI.
3. Do not grant `auth_keys`, device administration, or policy write.

Save its Client ID and Audience as policy-repository variables:

```bash
gh variable set TS_POLICY_TEST_CLIENT_ID \
  --repo "$GITHUB_OWNER/$POLICY_REPO" \
  --body "YOUR_POLICY_TEST_CLIENT_ID"

gh variable set TS_POLICY_TEST_AUDIENCE \
  --repo "$GITHUB_OWNER/$POLICY_REPO" \
  --body "YOUR_POLICY_TEST_AUDIENCE"
```

### Policy apply identity

Create a third GitHub OIDC trust credential:

1. Restrict it to the policy repository's protected `main` branch and the policy workflow.
2. Grant `policy_file` write and only its required read dependencies.
3. Do not grant device, DNS, auth-key, or unrelated API scopes.

Save its identifiers:

```bash
gh variable set TS_POLICY_APPLY_CLIENT_ID \
  --repo "$GITHUB_OWNER/$POLICY_REPO" \
  --body "YOUR_POLICY_APPLY_CLIENT_ID"

gh variable set TS_POLICY_APPLY_AUDIENCE \
  --repo "$GITHUB_OWNER/$POLICY_REPO" \
  --body "YOUR_POLICY_APPLY_AUDIENCE"

gh variable set TS_TAILNET \
  --repo "$GITHUB_OWNER/$POLICY_REPO" \
  --body "$TS_TAILNET"
```

The official `tailscale/gitops-acl-action` uses these OIDC identities. Pull requests run `action: test`; the manually approved apply job runs `action: apply` against the exact protected-branch file.

## Step 6: Provision the Private GCP Host

The reference host uses:

- A dedicated custom VPC and subnet.
- No external IP.
- No ingress firewall rules.
- Private Google Access.
- Cloud NAT for outbound package, Tailscale, DERP, and image traffic.
- VPC Flow Logs and Cloud NAT error logging.
- A dedicated GCP service account with no project-wide application role.
- Shielded VM features.

Create the network:

```bash
gcloud config set project "$GCP_PROJECT"

gcloud compute networks create agentic-workshop-net \
  --subnet-mode=custom \
  --bgp-routing-mode=regional

gcloud compute networks subnets create agentic-workshop-subnet \
  --network=agentic-workshop-net \
  --region="$GCP_REGION" \
  --range=10.240.0.0/24 \
  --enable-private-ip-google-access \
  --enable-flow-logs

gcloud compute routers create agentic-workshop-router \
  --network=agentic-workshop-net \
  --region="$GCP_REGION"

gcloud compute routers nats create agentic-workshop-nat \
  --router=agentic-workshop-router \
  --region="$GCP_REGION" \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips \
  --enable-logging \
  --log-filter=ERRORS_ONLY
```

Create a dedicated service account:

```bash
gcloud iam service-accounts create agentic-workshop-host \
  --display-name="Agentic workshop Tailscale host"
```

Get the service account's immutable numeric ID:

```bash
export GCP_HOST_SERVICE_ACCOUNT="agentic-workshop-host@${GCP_PROJECT}.iam.gserviceaccount.com"
export GCP_HOST_SERVICE_ACCOUNT_ID="$(
  gcloud iam service-accounts describe "$GCP_HOST_SERVICE_ACCOUNT" \
    --format='value(uniqueId)'
)"
```

Create a Tailscale workload identity for the VM:

1. Open **Tailscale Admin console > Settings > Trust credentials**.
2. Select **Credential > OpenID Connect > Google Cloud**.
3. Match the immutable service-account unique ID as the subject.
4. Grant only `auth_keys`.
5. Permit only `tag:demo-host`.
6. Copy the Client ID and Audience.

The VM retrieves its signed identity token from the GCP metadata service. No Tailscale auth key is generated, placed in metadata, or stored on disk.

Render the startup script locally:

```bash
export TS_HOST_CLIENT_ID="YOUR_GCP_TAILSCALE_CLIENT_ID"
export TS_HOST_AUDIENCE="YOUR_GCP_TAILSCALE_AUDIENCE"

python - "$TS_HOST_CLIENT_ID" "$TS_HOST_AUDIENCE" <<'PY'
from pathlib import Path
import sys

template = Path("deploy/gcp-startup.sh").read_text()
rendered = template.replace("__TS_HOST_CLIENT_ID__", sys.argv[1])
rendered = rendered.replace("__TS_HOST_AUDIENCE__", sys.argv[2])
Path("/tmp/gcp-startup.sh").write_text(rendered)
PY
```

The Client ID and Audience identify a trust relationship; they are not bearer credentials. The trust is useful only when Tailscale receives a valid Google-signed token matching the configured service-account subject.

Create the VM:

```bash
gcloud compute instances create "$TS_DEPLOY_HOST" \
  --zone="$GCP_ZONE" \
  --machine-type=e2-small \
  --network-interface=network=agentic-workshop-net,subnet=agentic-workshop-subnet,no-address \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-balanced \
  --service-account="agentic-workshop-host@${GCP_PROJECT}.iam.gserviceaccount.com" \
  --scopes=cloud-platform \
  --metadata-from-file=startup-script=/tmp/gcp-startup.sh,activate-workshop-release=deploy/activate-workshop-release \
  --shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=purpose=agentic-workshop,public-ingress=none
```

After the host appears in Tailscale:

1. Confirm it owns only `tag:demo-host`.
2. Confirm Tailscale SSH is enabled.
3. Confirm route acceptance and tailnet DNS acceptance are disabled unless you intentionally need them.
4. Confirm the Service advertisement is approved and reports `ready`.
5. Remove the startup script from instance metadata after provisioning so future configuration comes from reviewed infrastructure code.

```bash
gcloud compute instances remove-metadata "$TS_DEPLOY_HOST" \
  --zone="$GCP_ZONE" \
  --keys=startup-script
```

No GCP ingress firewall rule is required for SSH, port 3000, or HTTPS. All intended ingress arrives through Tailscale.

## Step 7: Deploy Through GitHub Actions

The deployment workflow in `.github/workflows/deploy.yml` runs only after CI succeeds on `main`, or when manually dispatched.

It performs four actions:

1. Checks out the reviewed commit.
2. Creates an application release archive.
3. Joins the tailnet as an ephemeral `tag:ci-deployer` node using GitHub OIDC.
4. Streams the release over Tailscale SSH to `/home/deploy/bin/activate-workshop-release`.

Run it manually for the first deployment:

```bash
gh workflow run deploy.yml --repo "$GITHUB_OWNER/$APP_REPO"
gh run watch --repo "$GITHUB_OWNER/$APP_REPO"
```

Successful deployment proves:

- OIDC token exchange works.
- The CI tag is permitted.
- The policy allows CI to reach only the deployment host on TCP 22.
- Tailscale SSH authorizes the exact `deploy` account.
- The backend answers on VM loopback.

## Step 8: Test Default Deny

Before the team-access pull request:

1. The author opens `$TS_SERVICE_URL` and receives the app.
2. The teammate opens the same URL and cannot connect.
3. Neither person can SSH to the host.
4. The application is not reachable through the VM's GCP address because the VM has no external IP.

A Tailscale policy denial normally looks like a failed connection, not an application-generated HTTP `403`, because traffic never reaches the application.

## Step 9: Open the Team-Access Pull Request

Copy `templates/policy.team-access.hujson` from this application repository over `policy.hujson` in the private policy repository, or make the equivalent small change:

```diff
 "groups": {
   "group:workshop-team": [
+    "AUTHOR_LOGIN",
     "TEAMMATE_LOGIN",
   ],
 },

 "grants": [
+  {
+    "src": ["group:workshop-team"],
+    "dst": ["svc:workshop-app"],
+    "ip": ["tcp:443"],
+  },
 ]
```

The pull request should also change the teammate policy test from `deny` to `accept`. Keep host SSH denied for both people.

Review the diff, merge it, then apply the exact merged `policy.hujson`. Seconds later, both group members should be able to open the named Service.

## Step 10: Revoke Access

Use GitHub's **Revert** button on the merged team-access pull request, or create a revert branch locally:

```bash
git switch main
git pull --ff-only
git switch -c revert-team-access
git revert TEAM_ACCESS_MERGE_COMMIT
git push -u origin revert-team-access
gh pr create --fill --base main
```

After the revert is reviewed, merged, and applied, the teammate loses access while the application and deployment host remain unchanged.

## Repository Protection

Protect `main` in both repositories:

- Require pull requests.
- Require at least one approval.
- Require CODEOWNER review for workflow and policy files.
- Require CI and policy validation.
- Require conversation resolution.
- Disable force pushes and branch deletion.
- Do not let the agent approve or merge its own change.

Pin third-party actions to full commit SHAs before using this outside a workshop. The readable action tags in this repository make the demo easier to follow but are not the final supply-chain hardening step.

## Cleanup

Delete the workshop resources when finished:

```bash
gcloud compute instances delete "$TS_DEPLOY_HOST" --zone="$GCP_ZONE"
gcloud compute routers nats delete agentic-workshop-nat \
  --router=agentic-workshop-router --region="$GCP_REGION"
gcloud compute routers delete agentic-workshop-router --region="$GCP_REGION"
gcloud compute networks subnets delete agentic-workshop-subnet --region="$GCP_REGION"
gcloud compute networks delete agentic-workshop-net
gcloud iam service-accounts delete \
  "agentic-workshop-host@${GCP_PROJECT}.iam.gserviceaccount.com"
```

Also:

- Delete the Tailscale machine record for `agentic-workshop-host`.
- Delete `svc:workshop-app` if it is no longer needed.
- Delete or restrict the three GitHub trust credentials and the GCP host trust credential.
- Remove repository secrets and variables that are no longer used.

## Troubleshooting

### GitHub Action says the requested tag is invalid or not permitted

The OIDC trust credential does not permit `tag:ci-deployer`, or the tag is absent from `tagOwners`.

### The private VM cannot install packages or connect to Tailscale

A no-external-IP VM needs Cloud NAT for public package repositories, Tailscale control traffic, and DERP fallback. Private Google Access alone is not enough.

### The GCP VM cannot exchange its identity

Check that the Tailscale Google Cloud trust credential matches the service account's numeric unique ID, not just its email address. Confirm the credential permits only `tag:demo-host`, has `auth_keys`, and that the VM is attached to that exact service account.

### The Service exists but is unavailable

Check:

- The host is online and tagged `tag:demo-host`.
- The Service host is approved.
- `tailscale serve status --json` reports the Service.
- The container health endpoint answers on `127.0.0.1:3000`.
- The user is named by an active grant.
- The client is connected to the correct tailnet.

### Policy changes do not appear in the console

Refresh the policy page and verify the tailnet ID. The policy API returns an ETag and request ID that can be used as authoritative evidence:

Use the policy workflow's successful apply run and the policy shown in the admin console as evidence. Confirm the workflow used the protected-branch apply identity, not the pull-request test identity.

### A private policy repository does not start GitHub Actions jobs

Check the account or organization Actions billing and runner policy. Do not merge until the OIDC-backed `tailscale/gitops-acl-action` test job actually runs and succeeds.

## Workshop Runbook

See `docs/RUNBOOK.md` for the on-stage sequence and `docs/SETUP.md` for a compact administrator checklist.
