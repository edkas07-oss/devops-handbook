# Development

## Overview

Bagian ini menjelaskan workflow pengembangan source dan content Personal Site.
Hugo digunakan hanya pada development dan CI; NGINX runtime hanya menerima
hasil static build.

## Repository Responsibilities

```text
personal-site/
├── content/                 Hugo content
├── layouts/                 template override
├── static/                  static assets
├── themes/                  Hugo theme submodule
├── hugo.toml                Hugo configuration
├── Jenkinsfile              CI pipeline
├── Jenkinsfile.cd           CD pipeline
└── deployment/
    ├── CONFIG               shared non-secret configuration
    └── deploy.sh            application runtime launcher
```

## Development Workflow

```text
Create or update content
        ↓
Run local Hugo server
        ↓
Review page and assets
        ↓
Commit and push to Gitea
        ↓
Jenkins CI builds immutable artifact
```

## Local Development

1. Clone repository and initialize submodules.

    ```bash
    git clone <personal-site-repository-url>
    cd personal-site
    git submodule update --init --recursive
    ```

2. Run Hugo development server.

    ```bash
    hugo server --buildDrafts
    ```

3. Open the local URL displayed by Hugo and review the changes.

4. Validate a production-style build.

    ```bash
    hugo --minify
    test -s public/index.html
    ```

The generated `public/` directory is build output and should not become the
source of truth. CI generates a clean build for every release candidate.

## Content Development

- Store publishable pages and articles under `content/`.
- Keep filenames and front matter consistent with the Hugo content model.
- Store files that must be copied directly under `static/`.
- Use layout overrides only when theme configuration is insufficient.
- Review internal links, images, metadata, and responsive rendering before push.

## Source Control Workflow

- Keep source, content, pipeline definitions, and deployment configuration in
  the same repository so a change can be traced to a commit.
- Do not store MinIO passwords or other secrets in the repository.
- Commit the Hugo theme reference when the submodule revision changes.
- Use CI output—not a manually generated archive—as the deployment artifact.

## Related Pages

- [Development Environment Setup](setup.md)
- [CI/CD](../ci-cd/index.md)
- [Engineering Journal — Continuous Integration](../engineering-journal/continuous-integration/index.md)
