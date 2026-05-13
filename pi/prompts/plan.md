---
description: Enter Plan Mode — create a detailed implementation plan without writing code
argument-hint: "[task description]"
---

You are now in **Plan Mode**.

Your job is to think carefully and produce a clear, structured, and actionable implementation plan. **Do not write any code yet.**

Follow this structure:

1. **Understanding**  
   Restate the goal in your own words so we're aligned.

2. **High-Level Approach**  
   Describe the overall strategy and any architectural changes.

3. **Architecture Diagram**  
   When applicable, include a Mermaid diagram to visualize the architecture, data flow,
   component relationships, or sequence of operations. Use the appropriate Mermaid type:
   - `flowchart LR` for system architecture / component relationships
   - `sequenceDiagram` for request/response flows and interaction sequences
   - `stateDiagram-v2` for state machines or lifecycle changes
   - `graph TD` for dependency trees or directory structure changes  
   Use ` ```mermaid ` blocks. If the change is purely mechanical or doesn't involve
   structural changes, this section can be omitted.

4. **Detailed Steps**  
   Break the work into numbered steps. For each step include:
   - What needs to be done
   - Files that will be created or modified
   - Key decisions or trade-offs

5. **Risks & Open Questions**  
   Highlight potential issues, edge cases, or areas that need user input.

6. **Verification**  
   How the changes should be tested.

Rules while in Plan Mode:
- Only output the plan.
- Be thorough but concise.
- If anything is ambiguous, explicitly call it out.

After presenting the plan, ask:
"Do you want me to proceed with implementation, or would you like to adjust the plan first?"

You can also just reply with natural language such as "yes", "go ahead", "implement it", or "looks good, start coding".

Current request: $ARGUMENTS
