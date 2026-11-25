# Credits

FlowPilot is built and maintained by [Precision Flow Systems](https://precisionflowsystems.com).

It started from the **Life Engine** recipe, which Jonathan Edwards contributed to the open-source **OB1 (Open Brain)** project by Nate B. Jones:
https://github.com/NateBJones-Projects/OB1

Since then it has been substantially reworked. Here's what changed from the original recipe:

The core loop (outside first, then the duplicate check, then memory), self-scheduling, weather, the self-improvement protocol and the prompt-injection rules come from the original recipe. FlowPilot added:

- A production runner: systemd service, tmux supervisor, crash alert to Discord, daily context reset, RAM health check
- Agent tickets: hand work to a coding or research agent through Linear, from chat
- Morning briefing additions: CRM follow-ups and quiet contacts, important dates, pipeline, Upwork messages, email, topic news
- Pending tasks with "done with X" completion, weekly commitments, and "what's next on [project]"
- Standing memories (`agent_memories`) loaded every run, plus wellness wins recalled on hard days
- A weather-aware movement nudge and a second afternoon check-in
- Lead capture into a pipeline
- Configuration moved out of the skill into a state table, Supabase shell helpers, and a consolidated schema

## Copyright

FlowPilot's own changes and additions are Copyright 2026 Precision Flow Systems LLC, under the same license as the original work.

## License notice for the original work

Copyright 2026 Nate B. Jones

This project contains portions derived from OB1 and, as the license requires for derivatives, is distributed under the same Functional Source License, Version 1.1, MIT Future License (FSL-1.1-MIT). See [LICENSE.md](LICENSE.md).

"Life Engine", "Open Brain" and "OB1" are names of the original project. They are used here only to identify where this work came from.
