# TN-001 — Define Diagnostic MVP Architecture and Contract

| Field | Value |
| --- | --- |
| Status | Completed |
| Activity Type | Discovery, Assessment, and Documentation |
| Record Type | Live with resumed execution |
| Project | Tomcat Monitoring |
| Phase | Diagnostic MVP Pilot |
| Activity Date | 2026-08-30 through 2026-08-31 |
| Recorded Date | 2026-08-31 |
| Owner | Project owner |
| Working Mode | Write — documentation only |
| Authorization Status | Approved |
| Approved By | Project owner |
| Approval Date | 2026-08-30; resumed and commit requested 2026-08-31 |

## 🎯 Objective

Revalidate the incomplete Diagnostic MVP brainstorming package and actual
repositories, then establish a repository-native Decision Gate for a
`TomcatDown`-only pilot before any implementation or runtime change.

## 🌍 Background

The brainstorming index claimed a consolidated handoff but referenced missing
specifications and ADR drafts. Repository discovery had also found no
Diagnostic Service, SQLite state, canonical result, restricted collector, or
`TomcatDown` rule. The project owner fixed the pilot boundary: application
health may support `TomcatDown`, while application-health and high-heap
diagnostic rules, Integration Bridge, TrueSight, and remediation remain
deferred or disabled.

Work was interrupted by a session limit after the first contract files were
created. On 2026-08-31 the project owner explicitly requested the work and
local commit to be repeated. Read-only revalidation found only those expected
untracked files and no overlapping user change.

## 📚 Scope

Approved work includes repository and documentation discovery, accepted
decision documentation, seven ADRs, Diagnostic MVP contracts, navigation,
current-state consolidation, validation, and a local commit.

It excludes source/configuration implementation, repository creation, image
build, container/network/volume change, deployment, runtime test, cleanup,
push, TrueSight activation, and automatic remediation.

## 🔍 Findings

1. `tomcat`, `tomcat-monitoring`, and `devops-handbook` worktrees were clean at
   initial discovery; `brainstorming` is not a Git repository.
2. The authoritative package lacked the NFR, `TomcatDown` rule, status and
   confidence, result, notification, integration specifications, and all seven
   draft ADR files. The feature specification existed only with suffix `-1`.
3. Actual Prometheus uses job `tomcat-jmx-exporter`, a 30-second interval,
   10-second timeout, and target `tomcat-jmx-exporter:9404`.
4. Actual Alertmanager routes all existing alerts directly to Mailpit.
5. Three application-health monitoring rules exist, but no `TomcatDown` rule,
   diagnostic webhook route, service, SQLite, canonical result, allowlist, or
   restricted collector exists.
6. Existing ADR numbering ends at `TM-ADR-0005`.
7. The prior Engineering Journal phase ends at TN-036 and is explicitly closed;
   Diagnostic MVP therefore requires a new phase.

## ⚖️ Accepted Decisions

- Only `TomcatDown` enters diagnostic routing.
- Canonical identity is `environment + host + tomcat_instance`; the first lab
  value is `lab + edkas-pc1 + tomcat-jmx-exporter`.
- The initial rule is `up{job="tomcat-jmx-exporter"} == 0` for two minutes.
- A new `tomcat-diagnostic-service` repository owns service source and image
  lifecycle; `tomcat-monitoring` owns integration and deployment configuration.
- A separate `tomcat-diagnostic-event-collector` repository owns a rootless
  host service that writes a normalized bounded spool.
- Webhook uses strict TLS, bearer authentication, an internal-only endpoint,
  and durable SQLite acceptance before `202`.
- SQLite is automatic, restart-persistent, targets 100 MiB, and has a 250 MiB
  hard acceptance boundary.
- Diagnostic Service owns `TomcatDown` firing, material update, failed/partial,
  and resolved Mailpit messages from one canonical result.
- Integration Bridge and TrueSight perform no work while disabled.
- No automatic remediation is present.

## 🏛️ Documentation Result

Repository-native contracts now live under
`docs/projects/tomcat-monitoring/diagnostic-mvp/`. Seven decisions are recorded
as `TM-ADR-0006` through `TM-ADR-0012`. Project pages distinguish accepted
design from implemented and verified current state.

The missing brainstorming drafts were not reconstructed or modified. The new
documents are based on the explicit accepted Decision Gate and surviving
evidence.

## ⏳ Open Questions

Open implementation and lab inputs are maintained in the Diagnostic MVP gap
register. Each question identifies its owner, closure evidence, and blocking
gate. No open item authorizes silent implementation choices.

## 💻 Commands Executed

### Initial read-only discovery

```bash
pwd
rg --files -g 'AGENTS.md' -g '!**/.git/**' /home/eddywiyatno/source/brainstorming /home/eddywiyatno/git/tomcat-monitoring /home/eddywiyatno/git/devops-handbook /home/eddywiyatno/git/tomcat
sed -n '1,300p' AGENTS.md
git status --short --branch
rg --files
git ls-files
find . -maxdepth 3 -type f -not -path './.git/*' -print
rg -n -i 'TomcatDown|ApplicationHealth|Mailpit|Alertmanager|Diagnostic|SQLite|collector|TrueSight|Integration Bridge|up\{|alert:' . -g '!**/.git/**'
```

Relevant authoritative and current-state documents were read with bounded
`sed -n` ranges. Missing package files were checked with exact `test -e` loops,
and related files were located with `find` and `rg`.

### Resumed documentation activity

```bash
git status --short --branch
git diff --stat
find docs/projects/tomcat-monitoring/diagnostic-mvp docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot -maxdepth 2 -type f -print
mkdir -p docs/projects/tomcat-monitoring/diagnostic-mvp docs/projects/tomcat-monitoring/engineering-journal/diagnostic-mvp-pilot
```

Manual documentation edits were applied with the repository-approved patch
interface. Validation commands and their actual results are recorded in the
Verification section after execution.

```bash
git diff --check
command -v mkdocs
python3 -c '<read-only Markdown local-link checker>'
```

## ✅ Verification

Expected result: documentation and navigation are internally consistent,
contain no whitespace errors or broken local links, render through the
available MkDocs interface, and change only approved files.

Actual result:

- `git diff --check` passed in `devops-handbook` and `tomcat-monitoring`.
- The read-only checker inspected 21 affected Markdown files and reported
  `broken_links=0`.
- `mkdocs` is not installed or available on `PATH`; render validation is
  therefore **Not verified**, and no dependency was installed.
- Scope review found only approved handbook documentation and the approved
  `tomcat-monitoring/README.md` change.

No source, configuration, image, container, volume, network, or runtime
verification is claimed.

## 📌 Result

The documentation-only architecture gate is completed. Diagnostic MVP remains
unimplemented and unverified at runtime. A separate implementation plan and
authorization are required before source, configuration, repository, image, or
runtime work begins.

## 🔗 References

- [Diagnostic MVP](../../diagnostic-mvp/index.md)
- [Requirements Traceability](../../diagnostic-mvp/requirements-traceability.md)
- [Gap Register](../../diagnostic-mvp/gap-register.md)
- [Tomcat Monitoring ADR](../../../../adr/tomcat-monitoring/index.md)
