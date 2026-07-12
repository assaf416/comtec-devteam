# DevTeam Hub — Tool Recommendations & Decisions

> Generated for a team of 16–50 developers. All tools are **open source, self-hosted**. Based on projects: .NET 4.8/Core 10, ASP.NET MVC, Vue 3, NestJS, Next.js 16 (Bun), Docker (Windows Containers).

---

## 1. Git Server

### ✅ Recommended: **Gitea**

| Feature | Detail |
|---|---|
| Install | Single binary / Docker – runs on Linux |
| UI | GitHub-like: PRs, issues, code review, wikis |
| CI | Gitea Actions (compatible with GitHub Actions syntax) |
| Webhooks | Push, PR, issue → DevTeam Hub |
| License | MIT |

**Installation (Docker, Linux server):**

```bash
docker run -d \
  --name gitea \
  -p 3000:3000 -p 222:22 \
  -v /opt/gitea:/data \
  gitea/gitea:latest
```

**Alternative: GitLab CE** (heavier, but includes built-in CI/CD, more enterprise features).

---

## 2. Automatic Testing

### Per Technology

| Project | Framework | Cucumber/BDD |
|---|---|---|
| C# .NET 4.8 / ASP.NET Core | **NUnit** (already in use) + **SpecFlow** | SpecFlow = Cucumber for .NET |
| Vue 3 + TypeScript | **Vitest** (Vite-native, fast) + **Playwright** (E2E) | **Cucumber.js** with Playwright |
| NestJS (Node.js) | **Jest** (built-in) + **Supertest** (API) | **Cucumber.js** |
| Next.js 16 (Bun) | **Vitest** or **Jest** + **Testing Library** | **Cucumber.js** |
| Rails (this app) | **RSpec** + **Capybara** | **Cucumber-Rails** (installed ✓) |

### SpecFlow Example (.NET – Cucumber style)

```gherkin
# Features/Login.feature
Feature: User Login
  Scenario: Successful login
    Given I am on the login page
    When I enter valid credentials
    Then I should see the dashboard
```

### Cucumber.js Example (Node.js)

```gherkin
# features/api.feature
Feature: Ticket API
  Scenario: Create a ticket
    Given the API is running
    When I POST to /api/tickets with valid data
    Then the response status is 201
```

---

## 3. Application Monitoring (APM)

### Comparison

| Tool | Cost | Type | Highlights |
|---|---|---|---|
| **Sentry** (self-hosted) | Free | Error tracking, crash reports, performance | ✅ Already integrated. Supports .NET, Node, Vue, Rails |
| **OpenTelemetry + Jaeger** | Free | Distributed tracing | Standard protocol, language-agnostic |
| **Prometheus + Grafana** | Free | Metrics & dashboards | Best for infrastructure metrics, custom dashboards |
| **Seq** | Free (1 user) | Structured logging | Great for Serilog (.NET already uses it!) |
| **Elastic APM (ELK Stack)** | Free | Full observability | Heavier, but excellent search over logs |
| Datadog | Paid ($15+/host/mo) | All-in-one | Best commercial option |
| New Relic | Paid (free tier) | All-in-one | Strong .NET support |
| AppSignal | Paid ($19+/mo) | Rails-focused | Excellent for Rails APM |

### ✅ Recommended Stack (open source)

1. **Sentry** – crash reports + error tracking for all projects
2. **Seq** – structured log aggregation (Serilog → Seq for .NET projects)
3. **Prometheus + Grafana** – metrics dashboards

### Sentry for .NET

```csharp
// Program.cs
builder.WebHost.UseSentry(o => {
    o.Dsn = Environment.GetEnvironmentVariable("SENTRY_DSN");
    o.TracesSampleRate = 0.1;
});
```

### Sentry for Vue 3

```typescript
import * as Sentry from "@sentry/vue";
Sentry.init({ app, dsn: import.meta.env.VITE_SENTRY_DSN });
```

### Sentry for NestJS

```typescript
import * as Sentry from "@sentry/node";
Sentry.init({ dsn: process.env.SENTRY_DSN });
```

---

## 4. Deployment Tools

### Recommended: **Ansible + Kamal + Inno Setup**

| Use Case | Tool | Notes |
|---|---|---|
| Web apps (Linux) | **Kamal** (Rails 8 built-in) | Docker-based, zero-downtime deploy |
| Web apps (Windows Server) | **Ansible** | WinRM-based, idempotent scripts |
| Windows desktop installers | **Inno Setup** + **Chocolatey** | Build MSI, track via DevTeam Hub |
| .NET services | **Octopus Deploy Community** or Ansible | |
| Docker (Windows Containers) | **Ansible + Docker** | Push images, update containers |

### Ansible Example – deploy ASP.NET Core to Windows

```yaml
# deploy_tdi2.yml
- hosts: tdi2_servers
  tasks:
    - name: Stop IIS site
      win_iis_website:
        name: TDI2
        state: stopped

    - name: Copy application files
      win_copy:
        src: "{{ build_output }}"
        dest: "C:\\inetpub\\wwwroot\\TDI2"

    - name: Start IIS site
      win_iis_website:
        name: TDI2
        state: started

    - name: Report deployment
      uri:
        url: "{{ devteam_hub_url }}/webhooks/deploy"
        method: POST
        body_format: json
        body:
          project: TDI2
          version: "{{ version }}"
          machine: "{{ inventory_hostname }}"
          status: succeeded
```

### Inno Setup + Chocolatey for Windows installers

```iss
; installer.iss
[Setup]
AppName=PrintServer
AppVersion={#Version}
OutputDir=dist
OutputBaseFilename=PrintServer-{#Version}
```

---

## 5. Project Management

**This app (DevTeam Hub)** provides sprint/ticket/milestone management.

For additional tools:

| Tool | Use Case |
|---|---|
| **DevTeam Hub** (this app) | Sprints, tickets, CI, deployments, docs |
| **Plane** (open source Jira alternative) | Can replace if you want a separate tool |
| **Taiga** | Agile project management, open source |

---

## 6. CI/CD

### ✅ Recommended: **Jenkins** (already in use)

**Extend with:**

- **Gitea Actions** – for PR-triggered tests (like GitHub Actions, simpler)
- **Jenkins Pipeline** – for complex multi-stage builds

### Jenkins Pipeline for .NET

```groovy
pipeline {
  agent any
  stages {
    stage('Build') {
      steps { sh 'dotnet build TDI2.sln -c Release' }
    }
    stage('Test') {
      steps { sh 'dotnet test --logger "nunit;LogFileName=results.xml"' }
    }
    stage('Notify DevTeam Hub') {
      steps {
        httpRequest url: "${DEVTEAM_URL}/webhooks/jenkins",
                    httpMode: 'POST',
                    requestBody: groovy.json.JsonOutput.toJson([build: [number: BUILD_NUMBER, status: currentBuild.result]])
      }
    }
  }
}
```

### Jenkins Pipeline for Vue 3 / NestJS

```groovy
pipeline {
  agent { docker { image 'node:22' } }
  stages {
    stage('Install') { steps { sh 'npm ci' } }
    stage('Test')    { steps { sh 'npm test -- --reporter=junit' } }
    stage('Build')   { steps { sh 'npm run build' } }
  }
}
```

---

## 7. Documentation

### ✅ Built into DevTeam Hub (Active Storage, Markdown)

Additional standalone tools:

| Tool | Notes |
|---|---|
| **BookStack** | Wiki-style, excellent for team docs |
| **Wiki.js** | Modern UI, Git storage backend |
| **Outline** | Notion-like, open source |

All three support self-hosting on Linux.

---

## 8. Team Communication

### ✅ Recommended: **Mattermost** + **Jitsi Meet**

| Tool | Purpose | Install |
|---|---|---|
| **Mattermost** (Community Edition) | Team chat, channels, threads, file sharing | Docker on Linux |
| **Jitsi Meet** | Video calls, screen share, recording | Docker on Linux |

**Mattermost Docker:**

```bash
docker run -d --name mattermost \
  -p 8065:8065 \
  -v /opt/mattermost:/mattermost/data \
  mattermost/mattermost-team-edition:latest
```

**Jitsi Meet Docker:**

```bash
git clone https://github.com/jitsi/docker-jitsi-meet
cd docker-jitsi-meet
cp env.example .env
# Edit .env for your domain
docker-compose up -d
```

---

## 9. Linux Server Requirements (for self-hosted tools)

| Service | RAM | CPU | Storage |
|---|---|---|---|
| Gitea | 512 MB | 1 core | 10 GB+ |
| Jenkins | 2 GB | 2 cores | 20 GB |
| Sentry | 4 GB | 2 cores | 50 GB |
| Mattermost | 1 GB | 1 core | 10 GB |
| Jitsi Meet | 2 GB | 2 cores | 10 GB |
| DevTeam Hub (Rails) | 1 GB | 1 core | 10 GB |
| **Total (recommended)** | **16 GB** | **8 cores** | **200 GB** | |

---

## Summary Architecture

```
Developers
    │
    ▼
[Gitea] ──webhooks──► [DevTeam Hub (Rails 8)]
    │                        │
    ▼                        ▼
[Jenkins CI] ──webhooks──► [Tickets / CI Dashboard]
    │                        │
    ▼                        ▼
[Sentry APM] ─────────► [APM Alerts → Email]
    │
    ▼
[Ansible Deploy] ──► [Windows / Linux servers]
                      track in DevTeam Hub

Team Communication:
[Mattermost chat] + [Jitsi Meet video]
```
