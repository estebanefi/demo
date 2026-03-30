# ADR-001: Case Routing Design

**Status:** Accepted
**Date:** 2026-03-29

---

## Context

Cases arrive through multiple channels — web-to-case, email-to-case, a screen Flow, and direct API integrations. Regardless of channel, every Case must be automatically routed to one of three queues (Claims Intake, Billing Support, Policy Services) immediately on creation.

---

## Decisions

### 1. After-save Flow, not before-save

The routing Flow uses `RecordAfterSave` triggering.

Before-save is technically viable for the current keyword-matching implementation. After-save was chosen for forward-looking reasons:

- **Routing complexity.** The number of keyword decisions required — across three queues, multiple keywords each, with ambiguity handling — is already at the edge of what before-save flows handle cleanly. As routing rules grow, before-save imposes tighter constraints on what can execute in-transaction.
- **Einstein Prompt Templates.** The keyword classifier is a placeholder. The intended evolution is to replace `CaseRoutingService` with an Einstein Prompt Template that sends the case text to an LLM and returns a queue name. Prompt Template invocations are not supported in before-save flows. Choosing after-save now avoids having to restructure the entire Flow when that migration happens.
- **Future-proofing as a principle.** Any routing enhancement that requires a callout, a SOQL lookup on a related record, or an async handoff is incompatible with before-save. After-save is the correct foundation for a component that is expected to grow in capability.

**Trade-off accepted:** Every Case insert costs one additional DML statement. Cases are not created in bulk volumes where this would approach governor limits.

---

### 2. Apex invocable + service class, not native Flow decisions

The keyword classification lives in `CaseRoutingService` (Apex), exposed to the Flow via `CaseRoutingAction` (`@InvocableMethod`), rather than native Flow Decision elements.

**Why not native Flow:**

- Matching keywords across three queues in Flow would require dozens of Decision elements — one branch per keyword. Every new keyword means a Flow deployment.
- Flow has no native `String.containsAny()` equivalent; replicating it requires nested formulas that are unreadable and untestable.
- Apex is unit-testable with full assertion coverage. The 20+ unit tests in `CaseRoutingServiceTest` could not exist if the logic lived in Flow.
- The service is deliberately decoupled from the invocation layer so the classification strategy can be replaced (e.g. an Einstein/AI call) without touching the Flow.

---

### 3. Only Subject and Description are used for routing

The routing service receives only `Subject` and `Description`, ignoring all other Case fields.

**Why:** These are the only two fields guaranteed to be populated across every channel:

| Channel           | Subject              | Description          | Other fields                   |
| ----------------- | -------------------- | -------------------- | ------------------------------ |
| Email-to-Case     | Email subject line   | Email body           | SuppliedEmail, SuppliedName    |
| Web-to-Case       | Form field           | Form field           | SuppliedCompany, SuppliedPhone |
| Screen Flow       | Explicitly collected | Explicitly collected | Varies                         |
| API / integration | Required by schema   | Optional but common  | Arbitrary                      |

Fields like `Origin`, `Priority`, `SuppliedEmail`, and `ContactId` are channel-specific and may be null at the time the routing Flow fires. Routing decisions based on nullable fields would require fallback logic per channel, increasing fragility.

**Assumption:** The subject and description together contain enough signal to classify the intent of any inbound case. If a case carries no matching keywords in either field, it defaults to Policy Services as the catch-all queue.

---

### 4. Routing fires on Case creation only, not updates

The record-triggered Flow uses `recordTriggerType: Create`. Updates to existing Cases do not re-trigger routing.

**Why:** Queue assignment is a one-time classification decision made at case intake. Re-routing on every save would override intentional agent re-assignments (e.g., an agent in Policy Services manually moving a case to Claims Intake). The initial routing is the automation's job; subsequent ownership changes are a human decision.

**If re-routing on update is ever needed**, a separate "re-route" Flow scoped to a specific field change (e.g., a `Re_Route__c` checkbox) would be the correct approach — not broadening this Flow's trigger.

---

## Consequences

- Routing keywords are maintained in `CaseRoutingService` — a code change and deployment is required to add or remove keywords. In a production implementation, keywords should be externalized to Custom Metadata records (e.g. `Queue_Routing_Keyword__mdt`) so admins can manage routing rules without a code deployment. For this demo, hardcoding is acceptable.
- Cases with ambiguous or empty subjects/descriptions always land in Policy Services. Agents in that queue are expected to re-route edge cases manually.
- The `CaseRoutingAction` invocable is a stable contract between the Flow and the service. Either side can evolve independently as long as the `subject`/`description` inputs and `queueDeveloperName` output remain in place.
