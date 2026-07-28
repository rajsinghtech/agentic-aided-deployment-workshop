# Live Runbook

1. Show the application on localhost.
2. Ask OpenCode to ship it privately and open PR 1.
3. Review CI, OIDC permissions, deployment scope, and absence of stored deployment keys.
4. Merge and watch the private deployment complete.
5. Show the presenter receiving the app while a team identity remains denied.
6. Ask OpenCode to grant `group:workshop-team` only `svc:workshop-app:443` and open PR 2 in the policy repository.
7. Read the grant and positive/negative policy tests on stage.
8. Merge, reload from the team device, and show the outsider still denied.
9. Close on both PRs, both workflow identities, policy history, and revert.
