---
name: workspace-productivity
description: Productivity and memory system across Google Workspace (Gemini Spark) and Markdown/local task environments (other LLMs). Initializes folders and documents, syncs tasks, triages stale items, and maintains a two-tier memory system for decoding workplace shorthand.
type: guidance
applies_to:
  - All agents
mandatory: conditional
mandatory_when:
  - The user wants to initialize the productivity system in Google Drive for the first time
  - The user wants to sync, update, or triage their task list
  - The user wants to perform a comprehensive scan of Workspace activities
triggers:
  - workspace productivity
  - sync tasks
  - triage tasks
  - initialize productivity
  - memory system
note: System initializes a Google Drive workspace or updates an existing one with current tasks and memory system.
summary: Initializes folders and documents, syncs tasks, triages stale items, and maintains a two-tier memory system for decoding workplace shorthand.
---

# Workspace Productivity

A cloud-integrated productivity and memory system hosted on Google Drive using Google Docs. It decodes workplace shorthand, acronyms, and nicknames, syncs and triages tasks from external sources (Gmail and Google Tasks), and maintains your context.

## When to Use

Use this skill when you want to:

- Initialize the productivity system in Google Drive for the first time.
- Sync, update, or triage your task list.
- View, search, or update your working memory, project context, or contacts.
- Perform a comprehensive scan of Workspace activities (emails, calendar, drive docs) to find untracked action items or new context.

## System Architecture

All files live in Google Drive under the parent folder **"Workspace Productivity"**:

```
Workspace Productivity/
├── TASKS (Google Doc)          - Active, Waiting On, Someday, and Done tasks
├── WORKING_MEMORY (Google Doc) - Hot cache (~30 key people, terms, active projects, preferences)
└── memory/ (Folder)
    ├── glossary (Google Doc)   - Full decoder ring (every acronym, term, nickname, project)
    ├── people/ (Folder)        - Individual profile Google Docs
    ├── projects/ (Folder)      - Project detail Google Docs
    └── context/ (Folder)
        └── company (Google Doc)- Teams, tools, and processes
```

## Modules

### Module 1: System Initialization (Start Command)

This command sets up the Google Drive workspace and performs the initial memory bootstrap.

#### 1. Check and Create Structure

Search Google Drive for the parent folder named "Workspace Productivity". If it does not exist, create it in your root directory.

Check for and create any missing folders or Google Docs inside it:

- **TASKS** (Google Doc) - Created with the standard template (see Module 4).
- **WORKING_MEMORY** (Google Doc) - Created for active context.
- **memory** (Folder) - Created inside the parent folder.
  - **glossary** (Google Doc) - Created inside memory/.
  - **people** (Folder) - Created inside memory/.
  - **projects** (Folder) - Created inside memory/.
  - **context** (Folder) - Created inside memory/.
    - **company** (Google Doc) - Created inside context/.

Provide direct Google Drive links (extracted from tool results) for each of these items to the user.

#### 2. Memory Bootstrap (First Run Only)

If WORKING_MEMORY is empty, perform the bootstrap:

1. Ask the user where they keep their existing todos (e.g. Asana, Notion, a local file, or a list).
2. Scan the provided task list for shorthand (nicknames, acronyms, abbreviations, project codenames, jargon).
3. Interactively decode these terms with the user (e.g., "I see 'PSR' in your task list. What does it stand for?").
4. Offer to run a comprehensive scan of recent Gmail, Calendar, and Drive activity to auto-detect more contacts, projects, and terms.
5. Populate the WORKING_MEMORY, glossary, and profile documents with high-confidence findings.

---

### Module 2: System Update (Update Command)

Keep your task list and memory current. Can be run in Default or Comprehensive mode.

#### 1. Default Mode

1. Load the current task state by reading the **TASKS** Google Doc.
2. Sync tasks from external sources:
   - Google Tasks: Retrieve uncompleted tasks using tasks_tool_agent:list_tasks.
   - Gmail: Search for recent email action items.
3. Compare external tasks against the **TASKS** Google Doc:
   - External task found, not in TASKS -> Offer to add to the Active section.
   - Found and matches (fuzzy title match) -> Skip.
   - In TASKS, not in external -> Flag as potentially stale or local-only.
   - Completed externally -> Offer to mark completed in the Done section.
4. Triage stale items: Review Active tasks in **TASKS** and flag overdue tasks, tasks in Active for 30+ days, or tasks with no context. Offer to mark completed, reschedule, or move to Someday.
5. Decode tasks for memory gaps: Check all task descriptions against **WORKING_MEMORY** and **glossary** docs. For unknown terms or contacts, prompt the user and save their clarifications to the appropriate memory files.
6. Extract context enrichment: Extract links, status changes, relationships, or deadlines from tasks and update corresponding project or people documents.

#### 2. Comprehensive Mode (--comprehensive)

Perform everything in Default Mode, plus a deep scan of recent activity:

1. Scan recent Gmail threads, Calendar events, and modified Google Drive documents.
2. Flag potential untracked tasks (e.g., "I will review the API spec this week" mentioned in an email) and ask if the user wants them added to **TASKS**.
3. Suggest new memories: Surface people, projects, or terms frequently mentioned in your activity that are not in your memory documents.

---

### Module 3: Memory Management

The memory system decodes shorthand so requests make sense immediately.

#### 1. Lookup Flow

When a user query contains shorthand (e.g., "ask Greg about the PSR"):

1. Read **WORKING_MEMORY** Google Doc (using docs_agent:call or read tools).
2. If not found, search the **glossary** Google Doc.
3. If not found, check for files in the **people/** or **projects/** folders.
4. If still not found, ask the user and update the memory system.

#### 2. File Formats

- **WORKING_MEMORY (Hot Cache):** Keep under ~80 lines. Contains Me, Key People (top ~30 contacts), Key Terms (most common acronyms), Active Projects, and Preferences.
- **glossary (Full Glossary):** Table formatting containing all acronyms, terms, nicknames, and project codenames.
- **people/{name} (Individual Doc):** Contains contact's full name, role, team, communication preferences, and context/notes.
- **projects/{name} (Individual Doc):** Contains project codename, alternative names, status, key stakeholders, and context/timeline.

---

### Module 4: Task Management

Tasks are tracked in a single, shared **TASKS** Google Doc.

#### 1. Format and Template

When creating a new **TASKS** Google Doc, use this layout:

```markdown
# Tasks

## Active

## Waiting On

## Someday

## Done
```

Task format:
- - [ ] **Task title** - context, for whom, due date
- Sub-bullets for details.
- Completed: - [x] ~~Task~~ (date)

#### 2. Interaction

- **Viewing Tasks:** Read TASKS Doc and summarize Active and Waiting On sections. Highlight overdue or urgent items.
- **Adding a Task:** Append to the Active section.
- **Completing a Task:** Find the task, change [ ] to [x], wrap title in ~~, add the completion date, and move to the Done section.
- **Extracting Tasks:** Identify commitments in conversation/emails and ask before adding them.

---

## Gotchas

- **Always use Google Docs:** Do not write local .md files or try to write plain-text/markdown files directly to Google Drive since their contents cannot be natively updated.
- **Always preserve formatting:** When modifying files using docs_agent:call, make targeted updates and preserve existing headers, tables, and lists.
- **Never auto-add:** Never add tasks, contacts, or project definitions to the memory system without user confirmation.
- **Keep WORKING_MEMORY lean:** Regularly demote completed projects or inactive contacts to deep memory (the memory/ folders) and keep WORKING_MEMORY focused on current hot context.
