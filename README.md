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
│   ├── skills/                    # Reusable domain skills
│   │   ├── INDEX.md
│   │   ├── dotnet-service-generator/
│   │   ├── mssql-table-scaffolder/
│   │   ├── infrastructure/
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

- **dotnet-service-generator**: Scaffolds .NET service modules with observability and DI conventions
- **mssql-table-scaffolder**: Generates MSSQL tables or migration scripts following enterprise conventions
- **infrastructure**: Docker and Kubernetes patterns for .NET services
- **observability**: SLIs, dashboard templates, alert conventions, and OpenTelemetry patterns
- **plantuml-sequence-diagram-generator**: Generates professional PlantUML sequence diagrams

See [.github/skills/INDEX.md](.github/skills/INDEX.md) for detailed skill documentation.

## Getting Started

### For AI Assistants

1. **GitHub Copilot**: Automatically reads `.github/copilot-instructions.md`
2. **Claude**: Reference `CLAUDE.md` which points to the main instructions
3. **Gemini**: Reference `GEMINI.md` which points to the main instructions

### For Developers

1. Clone this repository as a template for AI-assisted projects
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
