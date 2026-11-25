---
name: agent-ticket
description: Turn a request into a standardized task ticket in Linear for a coding or research agent to pick up. Use when the user asks to queue work, make a ticket, hand something to the agent, or says "have the agent do X", "add a task for", "ticket this", including from Discord via FlowPilot.
---

# Agent ticket writer

Turn what the user asks for into one (or a few) well-formed tickets in Linear. The agent that picks them up starts fresh with no memory, so the ticket is its whole brief.

## Configuration

Set these once in `flowpilot_state` (or edit this table for your setup):

| Key | Meaning | Example |
|---|---|---|
| `ticket_team` | Linear team | `Agents` |
| `ticket_project` | Linear project | `Agent Queue` |
| `ticket_label` | Label the agent watches | `agent-instructions` |
| `ticket_state` | Status the agent picks up from | `Agent Todo` |
| `ticket_agent_code` | Default agent | `claude-code` |
| `ticket_rules_issue` | Optional issue holding the agent's standing rules (repos, branch policy) | `ENG-7` |

If a rules issue is set, read it when you need repo details. If anything here disagrees with it, the rules issue wins.

Title pattern: `[agent instructions][<agent-code>][task] <short outcome>`. The short outcome is a plain phrase of what will exist when done, starting with the project when there is one, for example `Website: add pricing page FAQ` or `Research: 10 property managers in Austin`.

## Size: one outcome, checkable in one sitting

- Good: one feature or fix in one repo, one research batch of about 10 items, one document or draft.
- Too small: a rename or a single lookup. Fold it into something bigger or just do it in chat.
- Too big: "finish v2", "research the whole market". Split it, or write one **Plan** ticket whose output is a list of proposed tickets.
- Each ticket stands alone. If it builds on another, name that issue and what to use from it.

## Gather only what's missing

You need the outcome, where the work happens (repo, folder or "web research"), and where the result goes. Infer the rest.

- If one of those is truly unknown, ask **one** short question. Never more than two before showing a draft.
- Write any assumption under **Assumptions**.
- Never invent facts the agent would rely on (names, numbers, IDs).

## Template

```
## Outcome
One or two sentences: what exists or is true when this is finished.

## Inputs
Repo/folder paths, files, links, related tickets, facts the agent needs.

## Scope
What it may change. What it must not touch. What's out of scope.

## Assumptions
Anything inferred. (Omit if none.)

## Checks
How the agent proves it worked before finishing.

## Output
Exactly where the result goes (PR, file path, comment on this ticket).

## Finish as
Agent Review or Agent Done.
```

### Code ticket
- **Inputs:** the repo name, plus the files or areas involved.
- **Scope:** one change. If the user has uncommitted work in that repo, list those files under "must not touch".
- **Checks:** existing tests and lint, or a syntax check plus a short manual test list for the PR description.
- **Output:** a PR or a local branch, per the rules issue.
- **Finish as:** Agent Review.

### Research ticket
- **Outcome:** the decision it supports and the batch size (default 10).
- **Scope:** public sources only. Published business contact info is fine. No personal details beyond a public name and role. Research and draft only, never contact anyone.
- **Checks:** every row has a source link, and anything unverified is marked.
- **Output:** a Markdown table at `research/<topic>-<YYYY-MM-DD>.md`, plus a 3-line summary.
- **Finish as:** Agent Review.

### Writing ticket
- **Inputs:** audience, tone, length, source material.
- **Scope:** draft only. Sending, posting or publishing needs the user's explicit approval, quoted as "Approved by the user: <exact action>".
- **Finish as:** Agent Review.

### Plan ticket
- **Output:** a comment listing 3–10 proposed tickets (title and Outcome each). The agent does not create them.
- **Finish as:** Agent Review.

## Hard rules

- Never put secrets in a ticket: passwords, keys, tokens, webhook URLs or private personal data. Say "the agent will ask for it" instead.
- Never write approval for an outside action (send, post, publish, deploy, delete, spend) unless the user gave it in this conversation. Quote it.
- One outcome per ticket.

## Before creating

Check that:
1. The title matches the pattern.
2. Team, project, label and state are set.
3. A fresh agent could do it from the description alone.
4. Output and Finish as are stated.
5. Nothing secret or unapproved is in it.

Show a compact preview (title, Outcome, Output, Finish as). Create it on yes, or right away if the user already said "create it" or "queue it".

## Creating

Use the Linear connector's `save_issue` with `team`, `project`, `state`, `labels`, `title` and `description` (real newlines). For several tickets, create them one at a time in the order they should run.

Afterwards, reply with the issue ID, title and link, one line each.
