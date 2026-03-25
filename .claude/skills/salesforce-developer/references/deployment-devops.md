# Deployment & Package Structure

---

## SFDX Project Layout

```
my-salesforce-project/
├── .forceignore
├── .gitignore
├── sfdx-project.json
├── config/
│   └── project-scratch-def.json
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/          # Apex classes (.cls + .cls-meta.xml)
│           ├── triggers/         # Apex triggers (.trigger + .trigger-meta.xml)
│           ├── objects/          # Custom objects and fields
│           ├── flows/
│           ├── permissionsets/
│           └── staticresources/
├── scripts/
│   └── apex/                    # Anonymous Apex scripts
└── manifest/
    └── package.xml
```

---

## sfdx-project.json

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "MyPackage",
      "versionName": "ver 1.0",
      "versionNumber": "1.0.0.NEXT",
      "definitionFile": "config/project-scratch-def.json"
    }
  ],
  "name": "my-salesforce-project",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "59.0"
}
```

---

## .forceignore

```
**/profiles/**
**/settings/**
**/*-meta.xml.bak
.sfdx/
.sf/
*.log
.DS_Store
**/test-data/**
```

---

## package.xml

Consult the [Metadata API Types reference](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_types_list.htm) for valid `<name>` values.

### Explicit manifest (recommended for production)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>AccountService</members>
        <members>AccountTriggerHandler</members>
        <members>AccountServiceTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>AccountTrigger</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>Account.External_System_Id__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Integration_Log__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Account_Manager</members>
        <name>PermissionSet</name>
    </types>
    <version>59.0</version>
</Package>
```

### Wildcard retrieval (dev/scratch only)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>*</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomObject</name>
    </types>
    <version>59.0</version>
</Package>
```

---

## SF CLI — Deploy & Retrieve

```bash
# Deploy source (all)
sf project deploy start --target-org myprod

# Deploy specific directory
sf project deploy start --target-org myprod --source-dir force-app/main/default/classes

# Deploy via manifest
sf project deploy start --target-org myprod --manifest manifest/package.xml --test-level RunLocalTests

# Validate only (no changes committed)
sf project deploy validate --target-org myprod --manifest manifest/package.xml --test-level RunLocalTests

# Quick deploy after successful validation
sf project deploy quick --job-id 0Af...

# Retrieve specific component
sf project retrieve start --target-org myprod --metadata ApexClass:AccountService

# Retrieve via manifest
sf project retrieve start --target-org myprod --manifest manifest/package.xml

# Generate package.xml from org
sf project generate manifest --from-org myprod --output-dir manifest

# Run tests
sf apex run test --target-org myprod --test-level RunLocalTests --code-coverage --result-format human --wait 10
```

---

## When to Use

- **Explicit package.xml** — production deployments; never use wildcards in prod
- **Wildcard package.xml** — initial retrieval from a sandbox or scratch org
- **Source directory deploy** — targeted class/trigger deploys during development
- **Validate before deploy** — always validate in production before committing the deployment
