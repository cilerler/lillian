# AI Agent Templates

A comprehensive AI agent workflow system with specialized roles, skills, and instructions for building complex software systems using AI-assisted development.

## Overview

This repository provides a structured framework for AI-assisted software development through specialized agent roles. It defines a workflow where different AI agents handle specific phases of development, from planning to implementation to documentation.

## Features

- **🤖 Specialized Agent Roles**: 8 distinct agents (Planner, Architect, Designer, DBA, Developer, Reviewer, Tester, Documenter)
- **📋 Structured Workflow**: Clear transitions and responsibilities between agents
- **🎯 Domain-Specific Skills**: Reusable skills for common engineering tasks
- **📚 Technology-Specific Instructions**: Guidelines for Blazor, C#, SQL, Infrastructure, and Testing
- **🔄 Multi-AI Support**: Compatible with GitHub Copilot, Claude, and Gemini

### AI Assistant Compatibility Matrix

| Feature | GitHub Copilot | Google Antigravity | Claude Code |
|---------|---------------|-------------------|-------------|
| **Skills** | `.github/skills/` | `.agent/skills/` | `.claude/skills/` |
| **System Rules** | `.github/copilot-instructions.md` | `.agent/rules/` | `.claude/rules/` |
| **Agent Prompt** | None / Custom | `.agent/prompts/` | `CLAUDE.md` (Root) |
| **Config** | `.vscode/settings.json` | `.agent/config.json` | `.claude/config.json` |

## Usage in Your Repositories

This repository is designed as a shared AI instructions base. Add it to your code repositories as a submodule (private) or local clone (public), then symlink the contents into place.

### Private Repositories (Git Submodule)

Symlinks are committed and shared with all contributors.

```pwsh
git submodule add -b main https://github.com/cilerler/melis.git ".ai";
```

After cloning:

Pull updates

```pwsh
git submodule update --remote .ai;
```

### Public Repositories (Local Clone)

Nothing is committed. Each developer runs the setup locally.

```pwsh
git clone https://github.com/cilerler/melis.git ".ai";

# Exclude from git tracking (local-only, never committed)
@"

# AI instructions base
.ai/
CLAUDE.md
AGENTS.md
GEMINI.md
.claude/
.agent/
.github/agents
.github/instructions
.github/skills
.github/prompts
.github/copilot-instructions.md
.github/CONTRIBUTING.md
"@ | Add-Content -Path ".\.git\info\exclude";
```

Pull updates:

```pwsh
cd .ai; git pull; cd ..;
```

### Create Symlinks

Run once after either setup above:

```pwsh
# Create required directories
New-Item -ItemType Directory -Force -Path ".\.github";
New-Item -ItemType Directory -Force -Path ".\.claude";
New-Item -ItemType Directory -Force -Path ".\.agent";

# Symlink .github content
New-Item -ItemType SymbolicLink -Path ".\.github\skills" -Target (Resolve-Path ".\.ai\.github\skills").Path;
New-Item -ItemType SymbolicLink -Path ".\.github\agents" -Target (Resolve-Path ".\.ai\.github\agents").Path;
New-Item -ItemType SymbolicLink -Path ".\.github\instructions" -Target (Resolve-Path ".\.ai\.github\instructions").Path;
New-Item -ItemType SymbolicLink -Path ".\.github\prompts" -Target (Resolve-Path ".\.ai\.github\prompts").Path;
New-Item -ItemType SymbolicLink -Path ".\.github\copilot-instructions.md" -Target (Resolve-Path ".\.ai\.github\copilot-instructions.md").Path;
New-Item -ItemType SymbolicLink -Path ".\.github\CONTRIBUTING.md" -Target (Resolve-Path ".\.ai\.github\CONTRIBUTING.md").Path;

# Symlink root-level AI entry points
New-Item -ItemType SymbolicLink -Path ".\CLAUDE.md" -Target (Resolve-Path ".\.ai\CLAUDE.md").Path;
New-Item -ItemType SymbolicLink -Path ".\AGENTS.md" -Target (Resolve-Path ".\.ai\AGENTS.md").Path;
New-Item -ItemType SymbolicLink -Path ".\GEMINI.md" -Target (Resolve-Path ".\.ai\GEMINI.md").Path;

# Symlink skills for Claude and Google Antigravity
New-Item -ItemType SymbolicLink -Path ".\.claude\skills" -Target (Resolve-Path ".\.ai\.github\skills").Path;
New-Item -ItemType SymbolicLink -Path ".\.agent\skills" -Target (Resolve-Path ".\.ai\.github\skills").Path;
```

### Setup Notes

- If your repo already has `.github/CONTRIBUTING.md` or `.github/copilot-instructions.md`, skip those symlinks and keep your project-specific files
- `.claude/settings.local.json` is project-specific — copy and customize per project rather than symlinking

### Managing Symlinks

**List all symlinks** (recursively, including hidden items):

```pwsh
Get-ChildItem -Recurse -Force | Where-Object {$_.LinkType};
```

**Remove a symlink** (does not delete the target — omit `-Recurse` to avoid accidentally deleting target contents):

```pwsh
# File symlink
Remove-Item -Path ".\CLAUDE.md";

# Directory symlink
Remove-Item -Path ".\.github\agents";
```

> **Reference:** [New-Item (Microsoft.PowerShell.Management)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-item) · [about_Symbolic_Links](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_symbolic_links)

---

## Agent Workflow

The system follows a sequential workflow where each agent performs specific tasks and hands off to the next:

```
User Request → Planner → Architect → [Designer/DBA/Documenter (optional)] → 
Developer → Reviewer → [Tester → Reviewer (optional)] → 
[Documenter (optional)] → Complete
```

### Available Agents

| Agent | Purpose | Output |
|-------|---------|--------|
| **Planner** | Analyzes requests and creates actionable plans | Plan with acceptance criteria |
| **Architect** | Designs system architecture and technical specifications | Technical design, observability requirements |
| **Designer** | Creates UI/UX mockups and component designs | HTML/Tailwind mockups |
| **DBA** | Designs database schemas and migration strategies | Schema design, migrations, indexes |
| **Developer** | Implements code, infrastructure, and observability | Code, Docker, K8s, dashboards, runbooks |
| **Reviewer** | Reviews implementation against standards | PASS/FAIL verdict with feedback |
| **Tester** | Creates test cases and implements tests | Test cases, unit/integration tests |
| **Documenter** | Produces technical documentation | RFCs, ADRs, runbooks, SOPs |

### Workflow Rules

- ✅ All agent transitions require **explicit human approval**
- ✅ Each agent outputs and **stops** - user decides when to proceed
- ✅ Agents must read their specific definition from `.github/agents/<role>.agent.md`
- ✅ After 3 consecutive FAIL verdicts from Reviewer, **escalate to user**

## Repository Structure

```
root/
├── .github/
│   ├── agents/                    # Agent role definitions
│   │   ├── planner.agent.md
│   │   ├── architect.agent.md
│   │   ├── designer.agent.md
│   │   ├── dba.agent.md
│   │   ├── developer.agent.md
│   │   ├── reviewer.agent.md
│   │   ├── tester.agent.md
│   │   └── documenter.agent.md
│   ├── instructions/              # Technology-specific guidelines
│   │   ├── blazor.instructions.md
│   │   ├── csharp.instructions.md
│   │   ├── infrastructure.instructions.md
│   │   ├── sql.instructions.md
│   │   └── tests.instructions.md
│   ├── prompts/                   # Agent invocation prompts
│   │   ├── add-grafana-dashboard.prompt.md
│   │   ├── add-tests.prompt.md
│   │   ├── code-review.prompt.md
│   │   ├── my-code-review-comprehensive.prompt.md
│   │   ├── my-code-review-requirements.prompt.md
│   │   ├── my-repo-analysis.prompt.md
│   │   ├── new-service.prompt.md
│   │   ├── scaffold-table.prompt.md
│   │   ├── sequence-plantuml-diagram.prompt.md
│   │   └── update-docs.prompt.md
│   ├── skills/                    # Reusable domain skills
│   │   ├── INDEX.md
│   │   ├── documentation-generator/
│   │   ├── dotnet-service-generator/
│   │   ├── infrastructure/
│   │   ├── mssql-table-scaffolder/
│   │   ├── observability/
│   │   └── plantuml-sequence-diagram-generator/
│   ├── CONTRIBUTING.md            # Engineering standards (source of truth)
│   └── copilot-instructions.md    # Main workflow definition
├── AGENTS.md                      # Agent instructions entry point
├── CLAUDE.md                      # Claude-specific instructions
├── GEMINI.md                      # Gemini-specific instructions
└── LICENSE                        # MIT License
```

## Available Skills

The repository includes production-ready skills for common engineering tasks:

- **documentation-generator**: Templates for ADRs, RFCs, design docs, runbooks, postmortems, SOPs, and more
- **dotnet-service-generator**: Scaffolds .NET service modules with observability and DI conventions
- **infrastructure**: Docker and Kubernetes patterns for .NET services
- **mssql-table-scaffolder**: Generates MSSQL tables or migration scripts following enterprise conventions
- **observability**: SLIs, dashboard templates, alert conventions, and OpenTelemetry patterns
- **plantuml-sequence-diagram-generator**: Generates professional PlantUML sequence diagrams

See [.github/skills/INDEX.md](.github/skills/INDEX.md) for detailed skill documentation.

## Getting Started

### For AI Assistants

1. **GitHub Copilot**: Automatically reads `.github/copilot-instructions.md`
2. **Claude**: Reference `CLAUDE.md` which points to the main instructions
3. **Gemini**: Reference `GEMINI.md` which points to the main instructions

### For Developers

1. Add this repository to your project (see [Usage in Your Repositories](#usage-in-your-repositories))
2. Review `.github/CONTRIBUTING.md` for engineering standards
3. Customize agent roles in `.github/agents/` as needed
4. Add project-specific skills to `.github/skills/`
5. Update technology instructions in `.github/instructions/` for your stack

### Using the Workflow

1. **Start with a request**: Describe what you need to build
2. **Invoke Planner**: Get a structured plan with acceptance criteria
3. **Invoke Architect**: Receive technical design and architecture
4. **Invoke specialized agents**: Designer for UI, DBA for database changes
5. **Invoke Developer**: Implement the solution
6. **Invoke Reviewer**: Get quality feedback and validation
7. **Invoke Tester** (if needed): Add comprehensive test coverage
8. **Invoke Documenter** (if needed): Produce documentation

## Source of Truth

| Document | Purpose |
|----------|---------|
| [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) | Engineering standards (authoritative) |
| [.github/skills/INDEX.md](.github/skills/INDEX.md) | Skill routing and library references |
| [.github/agents/*.agent.md](.github/agents/) | Role definitions and behaviors |

In case of conflict, `.github/CONTRIBUTING.md` takes precedence.

## Key Principles

- **No automatic handoffs**: Every agent transition requires human interaction
- **Output and stop**: Agents complete their work and wait for user direction
- **Quality gates**: Reviewer enforces standards at multiple checkpoints
- **Separation of concerns**: Each agent has a single, well-defined responsibility
- **Observability first**: Developer handles both code and operational concerns
- **Documentation as code**: Technical documentation is version-controlled and reviewed

## Contributing

This is a template repository. Fork it and customize for your organization's needs. Update:

- Engineering standards in `.github/CONTRIBUTING.md`
- Agent behaviors in `.github/agents/`
- Technology-specific instructions in `.github/instructions/`
- Skills library in `.github/skills/`

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Cengiz Ilerler ([@cilerler](https://github.com/cilerler))

---

**Note**: This repository provides the framework and templates. The actual agent behavior depends on the AI assistant being used and how it interprets the provided instructions.
