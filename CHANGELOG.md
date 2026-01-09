# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-09

### Added

#### Commands
- `/kas:done` - Complete session, push all changes
- `/kas:save` - Snapshot session for later continuation
- `/kas:next` - Find next available beads issue
- `/kas:merge` - Merge PR to main

#### Agents
- `task-splitter` - Decompose implementation plans into beads issues
- `plan-reviewer` - Review plans for security gaps and design issues
- `code-reviewer` - Ruthless code review channeling Linus Torvalds
- `browser-automation` - Web testing and automation via Claude-in-Chrome
- `project-reality-manager` - Validate claimed task completions

#### Skills
- `browser` - Browser automation skill with subagent delegation pattern

#### Hooks
- SessionStart hook for automatic beads daemon startup

#### Documentation
- Generic CLAUDE.md with workflow instructions
- README with installation and usage
- MIT License
