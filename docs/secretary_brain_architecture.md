# LifePilot AI Secretary Brain Architecture

LifePilot AI is organized around a single Secretary Brain pipeline. Voice and typed input are only capture methods; both must send raw user text to the same processing layer before any screen decides what to do.

```text
User
  ↓
Voice OR Typing
  ↓
InputNormalizer
  ↓
IntentEngine
  ↓
Entity Extraction
  ↓
DecisionEngine
  ↓
SecretaryAction
  ↓
SecretaryScreen Action Executor
  ↓
UI + Voice Response
```

## Layer responsibilities

- `InputNormalizer` makes voice and typed phrases comparable by lowercasing, normalizing apostrophes, removing unnecessary punctuation, collapsing whitespace, and correcting common recognition variants.
- `IntentEngine` recognizes meaning and returns an `IntentResult` with intent, confidence, entities, response, and action metadata.
- `DecisionEngine` performs intent-level decisions that should not live in UI widgets, such as creating a reminder when enough entities are present.
- `SecretaryScreen` is the action executor for app navigation and screen-bound effects. It does not detect commands.
- Feature screens such as Smart Tasks receive explicit action state, for example a preselected filter.

## Version 1 intents

- `VIEW_SCHEDULE` opens Smart Tasks with `Today`, `Tomorrow`, `Upcoming`, `Completed`, `Missed`, or `All` preselected.
- `CREATE_REMINDER` extracts reminder title, date scope, time text, and a placeholder priority field.
- `OPEN_TASKS` opens Smart Tasks without forcing an additional user choice.
- `DELETE_TASKS` extracts deletion scope for completed, missed, or all tasks.
- `HELP` explains what the secretary can currently do.

## Expansion points

Future LifePilot features should add new intent enum values, entity extractors, decision handlers, and action payloads instead of adding command checks to screens. Calendar, weather, documents, password manager, gadgets, maps, holiday planning, finance, OCR, calls, messages, and AI memory can all plug into this same flow.
