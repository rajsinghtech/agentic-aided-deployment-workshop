# Live Runbook

1. Show the application on localhost and its passing tests.
2. Show the baseline policy: author allowed, teammate denied, CI limited to host TCP 22.
3. Ask OpenCode to ship the application privately and open PR 1.
4. Review CI, OIDC permissions, the ephemeral CI tag, and the absence of stored deployment keys.
5. Merge PR 1 and watch GitHub Actions deploy over Tailscale SSH to the private GCP VM.
6. Open the named Service as the author.
7. Attempt the same URL as the teammate and show that the connection is denied before reaching the app.
8. Ask OpenCode to give the workshop group access and open PR 2 in the policy repository.
9. Read the one-Service, one-port grant and the policy test changing from deny to accept.
10. Merge and apply PR 2.
11. Reload from both group members' devices and show that both now receive the application.
12. Show that neither human identity can SSH to the host.
13. Close on the two PRs, the two machine identities, the policy ETag, and the revert path.
