# Client Apps and VS Code Extension API

This API is intended for two classes of clients:

- Client applications that need to create or update tickets, trigger automated work, or query deployment state.
- The DevTeam VS Code extension, which needs fast ticket, PR, test, and deployment workflows inside the editor.

All endpoints are RESTful JSON endpoints under `/api/v1` and use bearer-token authentication.

## Authentication

Use a dedicated DevTeam user or service account for each client application or extension installation. Every request must send the token in the `Authorization` header.

### Get the current token

`GET /api/v1/token`

```bash
curl -s \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:5000/api/v1/token
```

Response:

```json
{
  "api_token": "..."
}
```

### Regenerate the token

`POST /api/v1/token/regenerate`

```bash
curl -s -X POST \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:5000/api/v1/token/regenerate
```

## Shared request conventions

- Content type: `application/json`
- Auth header: `Authorization: Bearer YOUR_API_TOKEN`
- Base URL: `http://localhost:5000/api/v1`
- Response format: JSON

## 1. Create tickets

Used by client apps and the VS Code extension when a user opens a new work item from an incident, task, or editor context.

`POST /api/v1/tickets`

Request body:

```json
{
  "ticket": {
    "project_id": 3,
    "title": "Printer timeout on floor 2",
    "description": "Reported from the desktop client",
    "status": "open",
    "priority": "high",
    "kind": "bug_fix",
    "level": "moderate",
    "how_to_reproduce": "Open print preview and send a large PDF",
    "assignee_id": 8
  }
}
```

Example:

```bash
curl -s -X POST \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/tickets \
  -d '{
    "ticket": {
      "project_id": 3,
      "title": "Printer timeout on floor 2",
      "description": "Reported from the desktop client",
      "status": "open",
      "priority": "high",
      "kind": "bug_fix"
    }
  }'
```

## 2. Update tickets

Used when the extension changes ticket state, records estimates, or stores generated PR metadata.

`PATCH /api/v1/tickets/:id`

Supported fields:

- `title`
- `description`
- `status`
- `priority`
- `kind`
- `level`
- `how_to_reproduce`
- `assignee_id`
- `owner_id`
- `pr_number`
- `pr_url`
- `dev_estimate_hours`
- `tester_estimate_hours`

Example:

```bash
curl -s -X PATCH \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/tickets/88 \
  -d '{
    "ticket": {
      "status": "in_review",
      "priority": "critical",
      "dev_estimate_hours": 4.5,
      "tester_estimate_hours": 1.5
    }
  }'
```

## 3. Generate pull requests

Used mainly by the VS Code extension after a ticket branch is ready. This endpoint creates the PR in Gitea and persists the matching local `PullRequest` record.

`POST /api/v1/pull_requests`

Requirements:

- `ticket_id` is required.
- The ticket's project must have `repo_url` configured.
- The source branch comes from `pull_request.source_branch` or falls back to the ticket's `branch_name`.

Example:

```bash
curl -s -X POST \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/pull_requests \
  -d '{
    "pull_request": {
      "ticket_id": 88,
      "title": "T-88: add deployment status widgets",
      "description": "Generated from the VS Code extension",
      "source_branch": "feature/T-88-add-deployment-status-widgets",
      "base_branch": "main"
    }
  }'
```

Query existing PRs:

`GET /api/v1/pull_requests?project_id=3&status=open`

```bash
curl -s \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:5000/api/v1/pull_requests?project_id=3&status=open
```

## 4. Run tests

Used when a client or extension wants to trigger Jenkins-based automated tests for a project or ticket.

`POST /api/v1/ci_runs`

Behavior:

- Calls `JenkinsService#trigger_build`
- Creates a local pending `CiRun`
- Returns the run payload immediately so the client can poll later

Example:

```bash
curl -s -X POST \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/ci_runs \
  -d '{
    "ci_run": {
      "project_id": 3,
      "ticket_id": 88,
      "job_name": "devteam-hub-smoke",
      "branch_name": "feature/T-88-add-deployment-status-widgets",
      "commit_sha": "f4c3b00c"
    }
  }'
```

Poll the run and current results:

`GET /api/v1/ci_runs/:id`

```bash
curl -s \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:5000/api/v1/ci_runs/15
```

List recent runs by project:

`GET /api/v1/ci_runs?project_id=3&status=failed`

```bash
curl -s \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:5000/api/v1/ci_runs?project_id=3&status=failed
```

## 5. Collect test results

Used by a client-side runner, CI bridge, or extension helper after a run finishes. Posting a result updates the parent CI run to `passed` or `failed` and stamps `finished_at` when needed.

`POST /api/v1/ci_runs/:ci_run_id/test_results`

Example:

```bash
curl -s -X POST \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/ci_runs/15/test_results \
  -d '{
    "test_result": {
      "suite_name": "Playwright smoke",
      "total": 12,
      "passed": 11,
      "failed": 1,
      "skipped": 0,
      "duration_ms": 18900,
      "xml_report": "<testsuite></testsuite>"
    }
  }'
```

Read stored results:

`GET /api/v1/ci_runs/:ci_run_id/test_results`

```bash
curl -s \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:5000/api/v1/ci_runs/15/test_results
```

## 6. Send deployment commands

Used by client apps or extension commands to register a deployment request or execution attempt. The created `Deployment` record is the canonical command/status object.

`POST /api/v1/deployments`

Example:

```bash
curl -s -X POST \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/deployments \
  -d '{
    "deployment": {
      "project_id": 3,
      "version": "2026.05.23",
      "environment": "staging",
      "status": "in_progress",
      "deploy_type": "docker",
      "machine_name": "app-01",
      "notes": "Deploy initiated from VS Code",
      "env_vars": [
        { "key": "RELEASE_SHA", "value": "abc123" },
        { "key": "ROLLING", "value": "true" }
      ]
    }
  }'
```

## 7. Query deployment status

Used when a client or extension needs to poll the state of a deployment.

`GET /api/v1/deployments/:id`

```bash
curl -s \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:5000/api/v1/deployments/22
```

List deployments by project or environment:

`GET /api/v1/deployments?project_id=3&environment=staging&status=in_progress`

```bash
curl -s \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  "http://localhost:5000/api/v1/deployments?project_id=3&environment=staging&status=in_progress"
```

Update deployment status:

`PATCH /api/v1/deployments/:id`

```bash
curl -s -X PATCH \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/deployments/22 \
  -d '{
    "deployment": {
      "status": "succeeded",
      "notes": "Smoke tests passed",
      "deployed_at": "2026-05-23T11:42:00Z"
    }
  }'
```

## VS Code extension usage pattern

Recommended sequence inside the extension:

1. `POST /api/v1/tickets` when the user creates work from the editor.
2. `POST /api/v1/pull_requests` after code is ready and a ticket branch exists.
3. `POST /api/v1/ci_runs` to trigger Jenkins validation.
4. `GET /api/v1/ci_runs/:id` or `GET /api/v1/ci_runs/:id/test_results` to render progress.
5. `POST /api/v1/deployments` and `GET /api/v1/deployments/:id` for release workflows.

## Client app usage pattern

Recommended sequence for desktop, mobile, or internal service clients:

1. Create or update a ticket.
2. Trigger CI when the issue is ready for automated validation.
3. Push suite summaries with `POST /test_results` if the client owns test execution.
4. Register deployment attempts and poll deployment state.
