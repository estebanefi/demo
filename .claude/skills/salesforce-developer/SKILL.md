
# Salesforce Developer

## SF CLI

Use `sf` CLI for all org operations. Key commands:
- `sf project deploy start --target-org <alias>` — deploy source
- `sf project retrieve start --target-org <alias>` — retrieve metadata
- `sf apex run test --target-org <alias> --code-coverage` — run tests
- `sf apex run --target-org <alias> --file <script.apex>` — execute anonymous Apex
- `sf data query --target-org <alias> --query "<SOQL>"` — query data

## Core Workflow

1. **Analyze** — Understand business needs, data model, governor limits, scalability
2. **Design** — Choose declarative vs programmatic, plan bulkification
3. **Implement** — Write Apex and SOQL with best practices from reference guides below
4. **Validate** — Verify SOQL/DML counts, heap size, and CPU time stay within platform limits
5. **Test** — 90%+ coverage, bulk scenarios (200-record batches)
6. **Deploy** — Salesforce DX, package structure, manifest

## Reference Guides

Load on demand based on the task:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Apex Development | `references/apex-development.md` | Classes, triggers, async, batch |
| SOQL/SOSL | `references/soql-sosl.md` | Query optimization, relationships |
| Deployment & Package Structure | `references/deployment-devops.md` | SFDX project layout, package.xml, SF CLI deploy/retrieve |
| Metadata API Types | https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_types_list.htm | Metadata type names for package.xml and deploy/retrieve |

## Constraints

### MUST DO
- Bulkify Apex — collect IDs/records before loops, query/DML outside loops
- 90%+ test coverage including 200-record bulk scenarios
- Selective SOQL with indexed fields
- Proper error handling; use `Database.update(scope, false)` for partial success
- Async processing (batch, queueable, future) for long-running work
- Source-driven development with SFDX package structure

### MUST NOT DO
- SOQL/DML inside loops
- Hard-code IDs or credentials
- Recursive triggers without safeguards
- Skip FLS/sharing rule checks
- Use deprecated APIs

## Key Patterns

### Bulkified Trigger

```apex
trigger AccountTrigger on Account (before insert, before update) {
    AccountTriggerHandler.handleBeforeInsert(Trigger.new);
}

public class AccountTriggerHandler {
    public static void handleBeforeInsert(List<Account> newAccounts) {
        Set<Id> parentIds = new Set<Id>();
        for (Account acc : newAccounts) {
            if (acc.ParentId != null) parentIds.add(acc.ParentId);
        }
        Map<Id, Account> parentMap = new Map<Id, Account>(
            [SELECT Id, Name FROM Account WHERE Id IN :parentIds]
        );
        for (Account acc : newAccounts) {
            if (acc.ParentId != null && parentMap.containsKey(acc.ParentId)) {
                acc.Description = 'Child of: ' + parentMap.get(acc.ParentId).Name;
            }
        }
    }
}
```

### Batch Apex

```apex
public class ContactBatchUpdate implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Email FROM Contact WHERE Email = null]);
    }
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        for (Contact c : scope) c.Email = 'unknown@example.com';
        Database.update(scope, false);
    }
    public void finish(Database.BatchableContext bc) {}
}
```

### Test Class

```apex
@IsTest
private class AccountTriggerHandlerTest {
    @TestSetup
    static void makeData() {
        Account parent = new Account(Name = 'Parent Co');
        insert parent;
        insert new Account(Name = 'Child Co', ParentId = parent.Id);
    }

    @IsTest
    static void testBulkInsert() {
        Account parent = [SELECT Id FROM Account WHERE Name = 'Parent Co' LIMIT 1];
        List<Account> children = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            children.add(new Account(Name = 'Child ' + i, ParentId = parent.Id));
        }
        Test.startTest();
        insert children;
        Test.stopTest();
        List<Account> updated = [SELECT Description FROM Account WHERE ParentId = :parent.Id];
        System.assert(updated[0].Description.startsWith('Child of:'));
    }
}
```

### SOQL Best Practices

```apex
// Selective — indexed fields in WHERE
List<Opportunity> opps = [
    SELECT Id, Name, Amount, StageName
    FROM Opportunity
    WHERE AccountId IN :accountIds AND CloseDate >= :Date.today()
    ORDER BY CloseDate ASC LIMIT 200
];

// Relationship query to avoid extra SOQL
List<Account> accounts = [
    SELECT Id, Name, (SELECT Id, LastName, Email FROM Contacts WHERE Email != null)
    FROM Account WHERE Id IN :accountIds
];
```
