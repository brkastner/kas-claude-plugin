---
description: Review code changes using kas-code-reviewer agent
---

Launch the kas-code-reviewer agent to review recent code changes.

## Workflow

1. **Identify scope to review**
   ```bash
   git status
   git diff --stat
   ```

2. **Launch kas-code-reviewer agent**
   Use the Task tool to invoke the kas-code-reviewer agent.

3. **Summarize findings**
   After agent returns, provide a concise summary of:
   - Overall assessment (APPROVED / NEEDS CHANGES / REJECTED)
   - Critical issues (severity 91-100)
   - High priority issues (severity 71-90)
   - Positive observations

4. **Wait for user approval**
   Do NOT apply fixes automatically. Summarize and ask for approval.
