# LifePilot AI — Product Vision, Mission, and Architecture Constitution

**Project:** LifePilot AI  
**Tagline:** *Your Personal Secretary*  
**Primary promise:** *Never Forget What Matters*  
**Purpose:** Permanent guide for all product, design, architecture, and implementation decisions.

---

## 1. Why LifePilot AI Exists

LifePilot AI exists because people forget important things: tasks, appointments, document locations, renewal dates, bills, repayments, birthdays, follow-ups, medicines, calls, commitments, and where valuable items were kept.

Most apps solve only one part of this problem. LifePilot must combine these needs into one intelligent digital secretary.

The user should not have to decide which module to use. The user should simply speak or type naturally, and LifePilot should understand what the information means, how it should be saved, whether it needs a reminder, and how it should be retrieved later.

---

## 2. Vision

To build a dependable digital personal secretary that reduces the burden on human memory by intelligently remembering, organising, retrieving, reminding, and following up on important matters.

LifePilot AI should eventually become a personal life operating system that helps the user manage responsibilities without requiring the user to remember everything manually.

---

## 3. Mission

LifePilot AI must:

1. Understand natural human language.
2. Accept both voice and manual typing.
3. Use one shared processing pipeline for both input methods.
4. Decide whether information is a task, reminder, memory, event, document location, financial obligation, expiry, contact, relationship, or follow-up.
5. Save information locally first.
6. Work usefully without internet.
7. Sync automatically when internet becomes available.
8. Remind proactively.
9. Speak reminders aloud when configured.
10. Retrieve previously saved information through natural questions.
11. Learn useful confirmed context over time.
12. Keep the user in control.

---

## 4. Product Identity

LifePilot AI is not merely:

- a reminder app
- a chatbot
- a notes app
- a to-do list
- a calendar
- a notification manager
- a dashboard

LifePilot AI is:

> A local-first, intelligent, proactive digital personal secretary.

Before implementing any feature, ask:

> “How would a responsible and experienced human personal secretary handle this?”

---

## 5. Core User Experience

The user should be able to say or type:

- “My bike pollution certificate expires on 2 November.”
- “I kept my original birth certificate in the blue file.”
- “Rifa’s birthday is on 25 November.”
- “I borrowed ₹25,000 from Ram Das and need to repay it in two months.”
- “What do I have today?”
- “Where is my birth certificate?”
- “When do I need to repay Ram Das?”
- “Remind me tomorrow at 8 PM to call the bank.”

LifePilot must understand the meaning, save the information correctly, and respond appropriately.

The user should not be forced to learn rigid commands.

---

## 6. Non-Negotiable Product Rules

### 6.1 One Secretary

There is only one secretary.

Voice and typing are not separate features. They are two input methods feeding the same intelligence.

```text
Voice input OR typed input
        ↓
Input normalisation
        ↓
Intent recognition
        ↓
Entity extraction
        ↓
Context lookup
        ↓
Decision making
        ↓
Storage
        ↓
Reminder scheduling
        ↓
Response
        ↓
Automatic sync queue
```

No separate command logic should exist for voice and typing.

### 6.2 Understand Meaning, Not Exact Commands

LifePilot must not depend on scattered exact-string checks.

Avoid architectures dominated by:

```dart
if (text.contains(...))
```

Deterministic parsing is acceptable inside a structured intent engine, but UI screens must not contain large command-matching chains.

### 6.3 Local-First

The essential experience must work without internet.

The local database is the immediate source of truth.

The user must be able to create reminders, save memories, retrieve document locations, check schedules, search tasks, view birthdays, view expiries, view financial obligations, and receive local notifications offline.

### 6.4 Automatic Cloud Sync

When connectivity becomes available, unsynchronised local changes should sync automatically.

The sync architecture should support:

- local IDs
- cloud IDs
- created and updated timestamps
- sync status
- retry attempts
- deletion tombstones
- conflict handling
- safe retries
- no silent data loss

### 6.5 Proactive Reminders

LifePilot must not wait for the user to open the app.

Notification modes:

- Normal
- Speak Aloud
- Silent

Support:

- global default mode
- per-reminder override
- scheduled text-to-speech
- reboot rescheduling
- duplicate prevention
- completion-aware cancellation
- future Do Not Disturb controls
- future repeat speech controls
- future voice speed controls

### 6.6 The First Screen Must Be the Secretary

When the app opens, the first screen must answer:

> “What needs my attention now?”

It should include:

- overdue work
- today’s work
- upcoming work
- important expiries
- birthdays and events
- unpaid or open financial obligations
- a visible text input
- a visible microphone button
- recent secretary conversation or response area

Dashboard cards may exist, but they must not replace the secretary interaction.

---

## 7. Secretary Intelligence Model

### 7.1 Understand

Determine:

- user intent
- subject
- people
- amount
- date
- time
- location
- action
- status
- recurrence
- urgency
- confidence

### 7.2 Remember

Possible memory types:

- task
- reminder
- event
- birthday
- anniversary
- expiry
- document location
- item location
- person
- relationship
- financial obligation
- loan taken
- loan given
- follow-up
- appointment
- general memory note

### 7.3 Think

Decide:

- whether a reminder is required
- when reminders should occur
- whether recurrence is needed
- whether clarification is necessary
- whether the information updates an existing record
- whether a related person already exists
- whether a conflict or duplicate exists

### 7.4 Act

Possible actions:

- save locally
- create a task
- schedule notification
- schedule spoken reminder
- answer a question
- open a filtered screen
- update an existing record
- mark a task complete
- ask one clarification question
- queue cloud sync

### 7.5 Learn

Learning means safely storing and reusing confirmed structured context.

Useful learned context may include people, aliases, relationships, recurring preferences, frequent locations, repeated reminder styles, linked events, and repeated obligations.

---

## 8. Life Memory

LifePilot should maintain a unified Life Memory.

A Life Memory entry may include:

- unique ID
- original user statement
- interpreted title
- type
- description
- linked person
- linked memory
- location
- amount
- currency
- event date
- due date
- reminder date
- recurrence
- status
- priority
- confidence
- created timestamp
- updated timestamp
- notification mode
- sync status

Examples:

- Rifa → person
- Rifa’s birthday → yearly event
- Ram Das → lender
- ₹25,000 loan → obligation linked to Ram Das
- birth certificate → stored in blue file
- bike pollution certificate → expiry with renewal reminders

---

## 9. Mandatory Behaviour Examples

### 9.1 Expiry

Input:

> “My bike pollution certificate expires on 2 November.”

Expected behaviour:

- classify as expiry
- identify subject and date
- save locally
- schedule useful advance reminders
- avoid inventing the wrong year
- ask if the year is genuinely ambiguous

### 9.2 Document Location

Input:

> “I kept my original birth certificate in the blue file.”

Expected behaviour:

- classify as document location
- save item and location
- do not create an unnecessary timed reminder

Later:

> “Where is my birth certificate?”

Expected response:

> “Your original birth certificate is in the blue file.”

This must work offline.

### 9.3 Birthday

Input:

> “Rifa’s birthday is on 25 November.”

Expected behaviour:

- identify Rifa
- link to an existing person when possible
- save yearly birthday
- schedule advance reminders
- avoid duplicate person records

### 9.4 Loan

Input:

> “I borrowed ₹25,000 from Ram Das and need to repay it in two months.”

Expected behaviour:

- classify as loan taken
- identify lender and amount
- calculate due date
- mark status open
- save locally
- schedule reminders
- answer later questions

### 9.5 Schedule

Input examples:

- “Show my schedule.”
- “What do I have today?”
- “What is today’s schedule?”
- “Am I busy tomorrow?”
- “Show tomorrow’s work.”
- “What is coming up this week?”
- “What did I miss?”

Expected behaviour:

- understand requested period or status
- provide a useful summary
- open the correct filtered view when appropriate
- do not open the entire list for every query

### 9.6 Reminder Creation

Input:

> “Remind me tomorrow at 8 PM to call the bank.”

Expected behaviour:

- classify as reminder creation
- extract action, date, and time
- save locally
- schedule notification
- do not confuse it with schedule viewing

---

## 10. Clarification Policy

LifePilot should avoid confidently saving wrong information.

Ask one concise clarification question only when required.

Examples:

- “Which month does it expire?”
- “Who did you give ₹5,000 to?”
- “When should I remind you?”

Do not ask unnecessary questions when the meaning is sufficiently clear.

---

## 11. Secretary Communication Style

Preferred:

- “You have three tasks today.”
- “Tomorrow is currently free.”
- “I’ve saved Rifa’s birthday.”
- “Your birth certificate is in the blue file.”
- “I’ll remind you before the repayment date.”

Avoid robotic wording such as:

- “Command executed.”
- “Intent matched.”
- “Operation successful.”

---

## 12. Home Screen Principles

The home screen should include:

### Priority information

- overdue
- due today
- upcoming
- expiries soon
- birthdays/events
- open loans or obligations

### Secretary interaction

- conversation or response area
- manual text field
- send button
- prominent microphone button
- visible listening state

### Navigation

- Smart Tasks
- Memory
- Documents
- Contacts
- Finance
- Settings
- future modules

The layout must remain responsive and must not overflow on smaller screens.

---

## 13. Task and Reminder Management

Smart Tasks should support:

- all
- today
- tomorrow
- upcoming
- missed
- completed
- search
- sorting
- multi-select
- delete selected
- delete completed
- delete missed
- delete all

All destructive actions must:

- show confirmation
- show record count
- cancel associated notifications
- update the screen immediately
- preserve unrelated memory records
- sync deletions safely

---

## 14. Offline Intelligence Strategy

### Layer 1 — Deterministic local understanding

Handle common intents, dates, times, money, relative durations, birthdays, reminders, expiries, loans, locations, and schedule requests locally.

### Layer 2 — Local context retrieval

Use structured fields, aliases, linked people, recent conversation context, normalised token matching, and local search.

### Layer 3 — Optional online intelligence

Online intelligence may enhance understanding when available, but must not be required for essential use.

Sensitive information must not be sent externally without a clear privacy design and consent.

---

## 15. Suggested Architecture

Suggested components:

- `SecretaryBrain`
- `InputNormalizer`
- `IntentRecognizer`
- `EntityExtractor`
- `DateTimeInterpreter`
- `ContextResolver`
- `SecretaryDecisionEngine`
- `SecretaryActionExecutor`
- `LifeMemoryRepository`
- `ReminderScheduler`
- `SpokenReminderService`
- `SyncService`

UI screens must not own business logic.

---

## 16. Data Safety

LifePilot handles personal information.

Therefore:

- local storage should be protected
- passwords and highly sensitive records need stronger security
- cloud sync should be authenticated
- logs must avoid exposing sensitive data
- deletion should be deliberate
- migrations must preserve existing data
- failures must not silently discard information

---

## 17. Product Development Rules

### Preserve Working Features

Before every change:

- inspect the current repository
- identify working behaviour
- avoid breaking voice
- avoid breaking typing
- avoid breaking reminders
- avoid breaking notifications
- avoid replacing the secretary with a normal dashboard

### One Milestone at a Time

Each task must define:

- current problem
- required outcome
- scope
- acceptance criteria
- features that must not break

### Architecture Before Patches

Prefer reusable services, typed models, clear responsibilities, and testable decision logic.

Avoid temporary UI-level conditions, duplicated storage, duplicated voice/text logic, and scattered exact-string checks.

### No False Claims

A feature is complete only when:

- it compiles
- tests pass
- analyser errors are resolved
- the user flow is manually verified

---

## 18. Codex Working Rules

Every Codex task should begin with:

```text
Read and follow /docs/LIFEPILOT_VISION.md before making any changes.

Preserve all existing working functionality.

Implement only the milestone described below.

Do not redesign unrelated screens or architecture.
```

Every Codex task should end with:

```text
Run dart format, flutter test, and flutter analyze.

Do not claim completion if any required feature is incomplete.

Report:
1. Files changed
2. Behaviour changed
3. Architecture changed
4. Existing features that may be affected
5. Manual tests required
6. Known limitations
```

---

## 19. Roadmap

### Milestone 1 — Unified Task Architecture
One task/reminder model, one storage path, notification integration, Smart Tasks integration.

### Milestone 2 — Secretary Brain Core
Shared voice and typing pipeline, intent recognition, entity extraction, date interpretation, action dispatching.

### Milestone 3 — Life Memory
Document locations, item locations, birthdays, expiries, people, relationships, recall questions.

### Milestone 4 — Proactive Voice Reminders
Normal, Speak Aloud, Silent, reboot handling, permission handling, duplicate protection.

### Milestone 5 — Financial Memory
Loans taken, loans given, bills, repayments, due-date reminders, status tracking.

### Milestone 6 — Follow-Up Intelligence
Pending calls, promised actions, unresolved matters, recurring follow-ups, escalation reminders.

### Milestone 7 — Daily Briefing
Overdue, today, upcoming, expiry alerts, birthdays, financial obligations, spoken briefing.

### Milestone 8 — Documents and Personal Records
Document metadata, storage location, renewal dates, future OCR, secure handling.

### Milestone 9 — Travel and Context
Weather, maps, directions, travel timing, calendar conflict awareness.

### Milestone 10 — LifePilot AI Release
Stability, onboarding, privacy controls, backup, sync, testing, release preparation.

---

## 20. Final Product Rule

LifePilot must not wait for the user to remember everything.

It must:

- remember for the user
- retrieve information when asked
- understand natural language
- remind proactively
- speak when necessary
- organise responsibilities
- learn confirmed context
- work offline
- sync safely
- remain dependable

LifePilot AI must always remain a personal secretary first.

Every feature, screen, service, and architectural decision must support that identity.
