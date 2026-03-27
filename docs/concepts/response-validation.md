# Response Validation

Response validation allows applications to register validators that evaluate the agent's final response before it is returned. If a validator rejects the response, feedback is re-injected into the conversation loop so the agent can rewrite it.

## Key Concepts

- **SDK provides the mechanism, application provides the intelligence.** The SDK does not know what "self-critique" means — it only knows that registered validators return `nil` (approved) or a `String` (feedback for rewriting).
- **Fail-open:** If a validator raises an exception, the response is considered approved. This prevents validator failures from blocking the conversation.
- **First-feedback-wins:** If multiple validators are registered, the first one that returns feedback causes rejection. Remaining validators are not called.

## Usage

### Registering a Validator

```ruby
runner = Agents::Runner.with_agents(agent)
  .on_response_validate do |output, agent_name, context_wrapper|
    # Return nil to approve, or a String with feedback to reject
    if output.include?("placeholder")
      "Please provide a specific answer instead of a placeholder."
    end
  end
```

### Validator Contract

Validators receive three arguments:

| Argument | Type | Description |
|----------|------|-------------|
| `output` | `String` | The agent's final response content |
| `agent_name` | `String` | Name of the agent that produced the response |
| `context_wrapper` | `RunContext` | Full execution context |

Return values:

| Return | Meaning |
|--------|---------|
| `nil` | Response approved — return to caller |
| `String` | Response rejected — feedback is injected via `chat.ask(feedback)` and the loop continues |

### Configuration

```ruby
# max_validation_retries controls how many times a response can be rewritten
# Default is 2. After exhausting retries, the response is returned as-is (fail-open).
result = runner.run("Hello", max_validation_retries: 3)
```

### Observability

`RunResult` includes a `validation_retries` field:

```ruby
result = runner.run("Hello")
result.validation_retries  # => 0 (no rewrites) or N (rewritten N times)
result.was_rewritten?      # => true if validation_retries > 0
```

## Execution Flow

1. Agent produces a final response (no tool calls, no handoff)
2. SDK calls `evaluate_response_validators(output, agent_name, context_wrapper)`
3. If all validators return `nil` → response is approved, returned as `RunResult`
4. If any validator returns a feedback string → feedback is injected via `chat.ask(feedback)`
5. The agent sees the feedback as a user message and rewrites its response
6. Steps 1-5 repeat until approved or `max_validation_retries` is exhausted
7. If max retries exhausted → response is returned as-is (fail-open)
