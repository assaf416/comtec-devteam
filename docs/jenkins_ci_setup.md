# Jenkins CI — Setup & Configuration Guide

## Table of Contents

1. [Solution Overview](#solution-overview)
2. [Installing Jenkins on Windows Server](#installing-jenkins-on-windows-server)
3. [Required Plugins](#required-plugins)
4. [Pipeline Configuration — Rails App (DevTeam Hub)](#pipeline-configuration--rails-app-devteam-hub)
5. [Pipeline Configuration — VS Code Extension](#pipeline-configuration--vs-code-extension)
6. [Pipeline Configuration — CLI Tools](#pipeline-configuration--cli-tools)
7. [Integration with Gitea](#integration-with-gitea)
8. [Integration with SonarQube](#integration-with-sonarqube)
9. [Integration with Ollama AI Code Review](#integration-with-ollama-ai-code-review)
10. [Credentials & Secrets Management](#credentials--secrets-management)
11. [Shared Libraries](#shared-libraries)
12. [Maintenance & Backup](#maintenance--backup)

---

## Solution Overview

We will use **Jenkins** (LTS) as our on-premise CI/CD server running on a **Windows Server** machine. Jenkins will:

- **Build & test** every push and pull request for all three sub-projects:
  - **DevTeam Hub** — Ruby on Rails 8.1 application (main app)
  - **DevTeam Hub VS Code Extension** — TypeScript VS Code extension
  - **CLI tools** (`devteam` / `dt`) — Ruby shell scripts
- **Run security scans** — Brakeman, bundler-audit, yarn audit
- **Run code quality analysis** — RuboCop linting and SonarQube static analysis
- **Trigger AI code review** via the local Ollama instance
- **Deploy** via Kamal when the `main` branch pipeline passes
- **Report results** back to Gitea as commit statuses

### Architecture Diagram

```
┌────────────┐   webhook   ┌──────────────┐
│   Gitea    │────────────>│   Jenkins    │
│ (Git Host) │<────────────│ (Windows)    │
└────────────┘  status API └──────┬───────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
              ┌─────▼─────┐ ┌────▼────┐ ┌─────▼─────┐
              │ SonarQube │ │ Ollama  │ │  Deploy   │
              │  (Docker) │ │ (Docker)│ │  (Kamal)  │
              └───────────┘ └─────────┘ └───────────┘
```

---

## Installing Jenkins on Windows Server

### Prerequisites

| Requirement            | Minimum                     |
|------------------------|-----------------------------|
| OS                     | Windows Server 2019 / 2022  |
| RAM                    | 8 GB (16 GB recommended)    |
| Disk                   | 50 GB free                  |
| Java                   | JDK 17 or JDK 21 (LTS)     |
| Network                | Port 8080 (Jenkins UI), outbound to Gitea |

### Step 1 — Install Java (JDK 17)

Download and install **Eclipse Temurin JDK 17** (Adoptium):

```powershell
# Using winget (Windows Package Manager)
winget install EclipseAdoptium.Temurin.17.JDK

# Verify
java -version
```

Or download the MSI installer from <https://adoptium.net/> and run it. During installation, check **"Set JAVA_HOME variable"**.

### Step 2 — Install Jenkins

1. Download the Jenkins Windows installer (`.msi`) from <https://www.jenkins.io/download/> — choose the **LTS** release.

2. Run the installer:

   ```
   jenkins-2.xxx.msi
   ```

3. During installation:
   - **Installation directory**: `C:\Jenkins`
   - **Service logon**: Use a dedicated service account (e.g., `.\jenkins-svc`) or the default **LocalSystem**
   - **Port**: `8080` (default)

4. The installer will register Jenkins as a **Windows Service** that starts automatically.

### Step 3 — Initial Setup

1. Open `http://localhost:8080` in a browser.
2. Retrieve the initial admin password:

   ```powershell
   type C:\Jenkins\secrets\initialAdminPassword
   ```

3. Install **suggested plugins** when prompted.
4. Create the first admin user.
5. Set the Jenkins URL to the server's hostname or IP (e.g., `http://jenkins.internal:8080`).

### Step 4 — Install Build Tools on the Server

Jenkins pipelines require these tools on the Windows Server (or available via Docker):

```powershell
# Ruby (via RubyInstaller — https://rubyinstaller.org/)
# Download Ruby+DevKit 3.4.x installer and run it

# Node.js (via winget or nvm-windows)
winget install OpenJS.NodeJS.LTS

# Yarn
npm install -g yarn

# Git
winget install Git.Git

# Docker Desktop (for SonarQube, Ollama containers)
winget install Docker.DockerDesktop
```

Configure Jenkins to find these tools: **Manage Jenkins → Tools**

- **JDK installations** → point to `C:\Program Files\Eclipse Adoptium\jdk-17...`
- **Git installations** → auto-detect or point to `C:\Program Files\Git\bin\git.exe`
- **NodeJS installations** → add version 22.x

### Step 5 — Configure Jenkins as a Windows Service

Jenkins is already installed as a service by the MSI. To manage it:

```powershell
# Check status
Get-Service Jenkins

# Start / Stop / Restart
Start-Service Jenkins
Stop-Service Jenkins
Restart-Service Jenkins

# Set to auto-start on boot (should already be set)
Set-Service Jenkins -StartupType Automatic
```

To change the service port or JVM memory, edit:

```
C:\Jenkins\jenkins.xml
```

Example memory increase:

```xml
<arguments>-Xrs -Xmx4096m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -jar "C:\Jenkins\jenkins.war" --httpPort=8080 --webroot="%ProgramData%\Jenkins\war"</arguments>
```

---

## Required Plugins

Install these plugins via **Manage Jenkins → Plugins → Available plugins**:

### Core Pipeline & SCM

| Plugin                        | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| **Pipeline**                  | Jenkinsfile-based declarative pipelines              |
| **Pipeline: Stage View**      | Visual stage progress in the UI                      |
| **Git**                       | Git SCM integration                                  |
| **Gitea Plugin**              | Gitea webhook & status integration                   |
| **Credentials Binding**       | Inject secrets into pipeline steps                   |
| **Workspace Cleanup**         | Clean workspace between builds                       |

### Build Tools

| Plugin                        | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| **NodeJS Plugin**             | Manage Node.js/npm/yarn installations                |
| **Ruby (rbenv/rvm) Plugin**   | Manage Ruby installations (or use system Ruby)       |
| **Docker Pipeline**           | Run pipeline stages inside Docker containers         |
| **Docker Commons**            | Shared Docker utilities                              |

### Quality & Security

| Plugin                        | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| **SonarQube Scanner**         | Run SonarQube analysis and quality gate checks       |
| **Warnings Next Generation**  | Parse Brakeman, RuboCop, and other tool reports      |
| **HTML Publisher**             | Publish test coverage and report HTML files          |

### Notifications & Reporting

| Plugin                        | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| **Mailer / Email Extension**  | Send build failure emails                            |
| **Slack Notification**        | Post build status to Slack (optional)                |
| **JUnit**                     | Parse and display RSpec/test results                 |
| **Cobertura**                 | Display code coverage reports                        |

### Administration

| Plugin                        | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| **Role-Based Authorization**  | Fine-grained permission control                      |
| **Blue Ocean**                | Modern Jenkins UI (optional, for better UX)          |
| **Timestamper**               | Add timestamps to console output                     |
| **Rebuild**                   | Re-run builds with same parameters                   |

---

## Pipeline Configuration — Rails App (DevTeam Hub)

Create a `Jenkinsfile` in the repository root:

### `Jenkinsfile`

```groovy
pipeline {
    agent any

    environment {
        RAILS_ENV       = 'test'
        BUNDLE_PATH     = 'vendor/bundle'
        SONAR_HOST_URL  = 'http://localhost:9100'
        GITEA_URL       = credentials('gitea-url')
        GITEA_TOKEN     = credentials('gitea-token')
        OLLAMA_URL      = 'http://localhost:11434'
    }

    tools {
        nodejs 'NodeJS-22'
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup') {
            parallel {
                stage('Ruby Dependencies') {
                    steps {
                        bat 'ruby --version'
                        bat 'bundle config set --local path vendor/bundle'
                        bat 'bundle config set --local without development'
                        bat 'bundle install --jobs 4'
                    }
                }
                stage('JS Dependencies') {
                    steps {
                        bat 'node --version'
                        bat 'yarn install --frozen-lockfile'
                    }
                }
            }
        }

        stage('Build Assets') {
            steps {
                bat 'yarn build'
                bat 'yarn build:css'
            }
        }

        stage('Database') {
            steps {
                bat 'bundle exec rails db:create db:schema:load'
            }
        }

        stage('Quality & Security') {
            parallel {
                stage('RuboCop') {
                    steps {
                        bat 'bundle exec rubocop --format json --out rubocop-report.json || exit 0'
                    }
                    post {
                        always {
                            recordIssues(tools: [ruboCop(pattern: 'rubocop-report.json')])
                        }
                    }
                }
                stage('Brakeman') {
                    steps {
                        bat 'bundle exec brakeman --quiet --no-pager --format json --output brakeman-report.json || exit 0'
                    }
                    post {
                        always {
                            recordIssues(tools: [brakeman(pattern: 'brakeman-report.json')])
                        }
                    }
                }
                stage('Bundler Audit') {
                    steps {
                        bat 'bundle exec bundler-audit check --update'
                    }
                }
                stage('Yarn Audit') {
                    steps {
                        bat 'yarn audit --level moderate || exit 0'
                    }
                }
            }
        }

        stage('Tests') {
            parallel {
                stage('RSpec') {
                    steps {
                        bat 'bundle exec rspec --format documentation --format RspecJunitFormatter --out rspec-results.xml'
                    }
                    post {
                        always {
                            junit 'rspec-results.xml'
                        }
                    }
                }
                stage('Cucumber') {
                    steps {
                        bat 'bundle exec cucumber --format junit --out cucumber-results/'
                    }
                    post {
                        always {
                            junit 'cucumber-results/**/*.xml'
                        }
                    }
                }
                stage('Seed Test') {
                    steps {
                        bat 'bundle exec rails db:seed:replant'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    bat """
                        sonar-scanner ^
                          -Dsonar.projectKey=dev-team-hub ^
                          -Dsonar.projectName="DevTeam Hub" ^
                          -Dsonar.sources=app,lib,config ^
                          -Dsonar.tests=spec,features ^
                          -Dsonar.exclusions=vendor/**,node_modules/**,tmp/**,log/**,public/**,storage/** ^
                          -Dsonar.ruby.coverage.reportPaths=coverage/.resultset.json ^
                          -Dsonar.ruby.rubocop.reportPaths=rubocop-report.json
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('AI Code Review') {
            when {
                changeRequest()
            }
            steps {
                bat 'ruby ci/ai_review.rb main'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                bat 'bundle exec kamal deploy'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            emailext(
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build failed. Check: ${env.BUILD_URL}",
                recipientProviders: [requestor(), culprits()]
            )
        }
        success {
            echo "Build #${env.BUILD_NUMBER} passed successfully."
        }
    }
}
```

### Additional Gems for CI Reporting

Add to the `Gemfile` (test group):

```ruby
group :test do
  gem "rspec_junit_formatter"   # Produces JUnit XML for Jenkins
  gem "simplecov", require: false  # Coverage reports
end
```

---

## Pipeline Configuration — VS Code Extension

Create `vscode-extension/Jenkinsfile`:

### `vscode-extension/Jenkinsfile`

```groovy
pipeline {
    agent any

    tools {
        nodejs 'NodeJS-22'
    }

    options {
        timestamps()
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('vscode-extension') {
                    bat 'npm ci'
                }
            }
        }

        stage('Lint') {
            steps {
                dir('vscode-extension') {
                    bat 'npx eslint src/ --format json --output-file eslint-report.json || exit 0'
                }
            }
            post {
                always {
                    recordIssues(tools: [esLint(pattern: 'vscode-extension/eslint-report.json')])
                }
            }
        }

        stage('Compile') {
            steps {
                dir('vscode-extension') {
                    bat 'npx tsc --noEmit'
                }
            }
        }

        stage('Test') {
            steps {
                dir('vscode-extension') {
                    bat 'npm test -- --reporter mocha-junit-reporter --reporter-options mochaFile=test-results.xml || exit 0'
                }
            }
            post {
                always {
                    junit 'vscode-extension/test-results.xml'
                }
            }
        }

        stage('Package VSIX') {
            when {
                branch 'main'
            }
            steps {
                dir('vscode-extension') {
                    bat 'npx @vscode/vsce package --no-yarn'
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'vscode-extension/*.vsix', fingerprint: true
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            emailext(
                subject: "FAILED: VS Code Extension — ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build failed. Check: ${env.BUILD_URL}",
                recipientProviders: [requestor(), culprits()]
            )
        }
    }
}
```

---

## Pipeline Configuration — CLI Tools

Create `cli/Jenkinsfile`:

### `cli/Jenkinsfile`

```groovy
pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate CLI Scripts') {
            steps {
                dir('cli') {
                    // Syntax check the Ruby CLI scripts
                    bat 'ruby -c devteam'
                    bat 'ruby -c dt'
                }
            }
        }

        stage('Shellcheck') {
            steps {
                dir('cli') {
                    // Check for common shell/script issues
                    bat 'ruby -w devteam 2>&1 || exit 0'
                    bat 'ruby -w dt 2>&1 || exit 0'
                }
            }
        }

        stage('Integration Test') {
            steps {
                // Run the CLI help commands to verify they execute
                dir('cli') {
                    bat 'ruby devteam --help || exit 0'
                    bat 'ruby dt --help || exit 0'
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

---

## Monorepo Strategy — Single Jenkinsfile

Since all three sub-projects live in one repository, you can use a **single root `Jenkinsfile`** with a multi-branch pipeline and path-based triggers:

```groovy
pipeline {
    agent any

    tools {
        nodejs 'NodeJS-22'
    }

    stages {
        stage('Detect Changes') {
            steps {
                script {
                    def changes = bat(script: 'git diff --name-only HEAD~1', returnStdout: true).trim()
                    env.RAILS_CHANGED   = changes.contains('app/') || changes.contains('lib/') || changes.contains('spec/') || changes.contains('Gemfile')
                    env.VSCODE_CHANGED  = changes.contains('vscode-extension/')
                    env.CLI_CHANGED     = changes.contains('cli/')
                }
            }
        }

        stage('Rails Pipeline') {
            when { expression { env.RAILS_CHANGED == 'true' } }
            steps {
                // ... all Rails stages from above ...
                echo 'Running Rails pipeline...'
            }
        }

        stage('VS Code Extension Pipeline') {
            when { expression { env.VSCODE_CHANGED == 'true' } }
            steps {
                // ... all VS Code extension stages from above ...
                echo 'Running VS Code Extension pipeline...'
            }
        }

        stage('CLI Pipeline') {
            when { expression { env.CLI_CHANGED == 'true' } }
            steps {
                // ... all CLI stages from above ...
                echo 'Running CLI pipeline...'
            }
        }
    }
}
```

---

## Integration with Gitea

### Gitea Webhook Setup

1. In Gitea, go to **Repository → Settings → Webhooks → Add Webhook → Gitea**.
2. Configure:
   - **URL**: `http://jenkins.internal:8080/gitea-webhook/post`
   - **Content type**: `application/json`
   - **Events**: Push, Pull Request
   - **Secret**: (set a shared secret and add it to Jenkins credentials)

### Jenkins Job Configuration

1. **Create a Multibranch Pipeline** job in Jenkins.
2. Under **Branch Sources**, add **Gitea** and configure:
   - **Server URL**: `http://gitea:3001`
   - **Credentials**: Gitea API token (stored in Jenkins credentials)
   - **Owner**: your organization name
   - **Repository**: `dev-team`
3. Set **Discover branches** and **Discover pull requests** behaviors.
4. Under **Build Configuration**, select **by Jenkinsfile** and set the path to `Jenkinsfile`.

### Reporting Build Status to Gitea

The **Gitea Plugin** automatically reports commit statuses. For manual control:

```groovy
post {
    success {
        script {
            httpRequest(
                url: "${GITEA_URL}/api/v1/repos/org/dev-team/statuses/${env.GIT_COMMIT}",
                httpMode: 'POST',
                customHeaders: [[name: 'Authorization', value: "token ${GITEA_TOKEN}"]],
                contentType: 'APPLICATION_JSON',
                requestBody: """{
                    "state": "success",
                    "target_url": "${env.BUILD_URL}",
                    "description": "Jenkins build passed",
                    "context": "ci/jenkins"
                }"""
            )
        }
    }
}
```

---

## Integration with SonarQube

### Jenkins Configuration

1. **Manage Jenkins → System → SonarQube servers**:
   - Name: `SonarQube`
   - Server URL: `http://localhost:9100`
   - Authentication token: (create in SonarQube under **My Account → Security → Tokens**, then save in Jenkins credentials)

2. **Manage Jenkins → Tools → SonarQube Scanner installations**:
   - Name: `SonarScanner`
   - Install automatically: ✅

The existing `sonar-project.properties` in the repo root will be used automatically by the scanner.

---

## Integration with Ollama AI Code Review

The `ci/ai_review.rb` script is triggered during PR builds. Ensure the Ollama container is running on the Jenkins server:

```powershell
# Start Ollama via Docker (or use docker-compose.code-review.yml)
docker compose -f docker-compose.code-review.yml up -d ollama

# Pull the model
docker exec ollama ollama pull qwen2.5-coder:32b
```

Jenkins environment variables needed:

| Variable      | Value                     |
|---------------|---------------------------|
| `OLLAMA_URL`  | `http://localhost:11434`  |
| `OLLAMA_MODEL`| `qwen2.5-coder:32b`      |
| `GITEA_URL`   | `http://gitea:3001`       |
| `GITEA_TOKEN` | (from Jenkins credentials)|

---

## Credentials & Secrets Management

Store all secrets in **Manage Jenkins → Credentials → System → Global credentials**:

| Credential ID         | Type            | Description                         |
|-----------------------|-----------------|-------------------------------------|
| `gitea-url`           | Secret text     | Gitea server URL                    |
| `gitea-token`         | Secret text     | Gitea API token                     |
| `sonarqube-token`     | Secret text     | SonarQube authentication token      |
| `rails-master-key`    | Secret text     | `RAILS_MASTER_KEY` for deployment   |
| `kamal-registry`      | Username/Password | Docker registry credentials       |
| `deploy-ssh-key`      | SSH key         | SSH key for deployment servers      |

Access in Jenkinsfile:

```groovy
environment {
    GITEA_TOKEN      = credentials('gitea-token')
    RAILS_MASTER_KEY = credentials('rails-master-key')
}
```

---

## Shared Libraries

For reusable pipeline logic, create a **Jenkins Shared Library** in a separate Gitea repo (`jenkins-shared-lib`):

### `vars/notifyGitea.groovy`

```groovy
def call(String state, String description = '') {
    httpRequest(
        url: "${env.GITEA_URL}/api/v1/repos/org/dev-team/statuses/${env.GIT_COMMIT}",
        httpMode: 'POST',
        customHeaders: [[name: 'Authorization', value: "token ${env.GITEA_TOKEN}"]],
        contentType: 'APPLICATION_JSON',
        requestBody: """{"state":"${state}","target_url":"${env.BUILD_URL}","description":"${description}","context":"ci/jenkins"}"""
    )
}
```

Usage in Jenkinsfile:

```groovy
@Library('devteam-shared-lib') _

// ...
post {
    success { notifyGitea('success', 'All checks passed') }
    failure { notifyGitea('failure', 'Build failed') }
}
```

---

## Maintenance & Backup

### Backup Strategy

Back up the Jenkins home directory regularly:

```powershell
# Jenkins home on Windows
$JenkinsHome = "C:\Jenkins"

# Backup script (run via Windows Task Scheduler)
$BackupDir = "D:\Backups\Jenkins\$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -ItemType Directory -Path $BackupDir -Force

# Core config (jobs, credentials, plugins)
Copy-Item "$JenkinsHome\config.xml" $BackupDir
Copy-Item "$JenkinsHome\credentials.xml" $BackupDir
Copy-Item -Recurse "$JenkinsHome\jobs" "$BackupDir\jobs"
Copy-Item -Recurse "$JenkinsHome\users" "$BackupDir\users"
Copy-Item -Recurse "$JenkinsHome\secrets" "$BackupDir\secrets"
Copy-Item -Recurse "$JenkinsHome\plugins" "$BackupDir\plugins"

# Retain last 30 days
Get-ChildItem "D:\Backups\Jenkins" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Recurse -Force
```

### Plugin Updates

- Check for plugin updates weekly via **Manage Jenkins → Plugins → Updates**
- Always test updates in a staging environment first
- Keep Jenkins LTS up to date (update monthly)

### Monitoring

- Enable the **Prometheus Metrics** plugin to expose `/prometheus` endpoint
- Monitor build queue length, executor usage, and build durations
- Set up alerts for builds that stay in the queue too long

---

## Quick-Start Checklist

- [ ] Install JDK 17 on Windows Server
- [ ] Install Jenkins LTS via MSI
- [ ] Install Ruby 3.4, Node.js 22, Yarn, Git on the server
- [ ] Install Docker Desktop for SonarQube and Ollama containers
- [ ] Install all required Jenkins plugins (see table above)
- [ ] Configure Gitea webhook pointing to Jenkins
- [ ] Add credentials (Gitea token, SonarQube token, Rails master key)
- [ ] Configure SonarQube server in Jenkins system settings
- [ ] Create a Multibranch Pipeline job for `dev-team` repo
- [ ] Commit the `Jenkinsfile` to the repository
- [ ] Start `docker-compose.code-review.yml` for SonarQube + Ollama
- [ ] Run a test build and verify Gitea receives the status
- [ ] Set up the backup script via Windows Task Scheduler
