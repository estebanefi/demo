# Case Routing Demo

A Salesforce DX demo project that automatically routes incoming Cases to the correct support queue based on the content of the subject and description fields.

## What It Does

When a Case is created or updated, a record-triggered Flow inspects the case subject and description for domain-specific keywords and assigns ownership to one of three queues:

| Queue               | Keywords                                             |
| ------------------- | ---------------------------------------------------- |
| **Claims Intake**   | claim, fnol, first notice, accident, loss            |
| **Billing Support** | billing, invoice, payment, charge, refund            |
| **Policy Services** | policy, endorsement, cancellation, renewal, coverage |

If no keywords match, or if keywords from multiple queues are detected, the Case defaults to **Policy Services**.

## Architecture

```
Case insert
      │
      ▼
Case_Routing_Flow (record-triggered)
      │
      ▼
CaseRoutingAction (@InvocableMethod)
      │
      ▼
CaseRoutingService (keyword classifier)
      │
      ▼
Case.OwnerId → Queue
```

- **`CaseRoutingService`** — pure Apex service that resolves a queue developer name from case subject/description keywords
- **`CaseRoutingAction`** — thin `@InvocableMethod` wrapper that exposes the service to Flows
- **`Case_Routing_Flow`** — record-triggered Flow that calls the action and updates `Case.OwnerId`
- **`Case_Creation_Screen_Flow`** — Screen Flow for manually creating Cases

## Metadata

| Type            | Location       |
| --------------- | -------------- |
| Apex classes    | `src/classes/` |
| Flows           | `src/flows/`   |
| Queues          | `src/queues/`  |
| Object metadata | `src/objects/` |

## Decision Records

Significant design decisions are documented in [`decision-records/`](decision-records/).
