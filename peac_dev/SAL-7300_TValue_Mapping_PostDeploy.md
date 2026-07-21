# Post-Deployment Steps — Disable TValue Outbound Field Mappings

**Tickets:** SAL-7300 (# Required Adv. Payments), SAL-7385 (Total Financed Amount / Equipment Cost)

## Why this is needed

The TValue managed package syncs values between its internal quote fields and our
Salesforce fields via **TValue Template Field** records (`tval__TValue_Template_Field__c`).
When a mapping has **Outbound enabled**, TValue writes its internal value *back onto*
our Salesforce field — overwriting whatever our own automation set.

This is what breaks:

- **SAL-7300:** Our `saveCompany` code correctly stamps `Opportunity.Required_Adv_Payments__c`
  from the Quote, but the Outbound mapping `Opportunity.required_adv_payments__c ↔ numAdvancedPayments`
  overwrites it back to 0 (runs as *Automated Process* after conversion). `Down_Payment__c`
  and `Buydown__c` have **no** TValue mapping, which is why only Advance Payments breaks.
- **SAL-7385:** Same mechanism overwrote `Quote.Total_Financed_Amount__c` (gross $100k → net $95k).

**These are managed-package *data* records, not metadata.** They cannot be moved by a
source/metadata deploy. They must be changed **manually in each org** (or via the data
script below). Record IDs differ per org — always locate records by their field values,
never by the sandbox IDs in this doc.

## Records to change (disable Outbound, keep Inbound)

Locate each by **Parent Template + Object + Source Field + TValue Field**:

| # | Ticket | Parent Template | Object.Source Field | TValue Field | Action |
|---|--------|-----------------|---------------------|--------------|--------|
| 1 | SAL-7300 | 0004 | `Opportunity.required_adv_payments__c` | `numAdvancedPayments` | Outbound → **False** |
| 2 | SAL-7385 | 0007 | `Quote.total_financed_amount__c` | `quoteAmount` | Outbound → **False** |
| 3 | SAL-7385 | 0008 | `Quote.Total_Financed_Amount__c` | `quoteAmount` | Outbound → **False** |
| 4 | SAL-7385 | 0004 | `Opportunity.equipment_cost__c` | `quoteAmount` | Outbound → **False** |
| 5 | SAL-7385 | 0005 | `Opportunity.equipment_cost__c` | `quoteAmount` | Outbound → **False** |

> Leave **Inbound = True** on all of them. Inbound lets the Salesforce value feed *into*
> TValue for the calculation; only Outbound (TValue writing back) causes the overwrite.
> If your org already has the SAL-7385 Apex restore workaround deployed, disabling Outbound
> on #2–#5 makes that workaround redundant (harmless to leave in place).

## Method A — TValue Setup UI (recommended for one org at a time)

1. Open the **TValue Setup** tab (or **TValue Templates**).
2. Open the parent template (e.g. **0004**).
3. Find the template-field row matching the **Object.Source Field ↔ TValue Field** in the table above.
4. Edit → uncheck **Outbound** → keep **Inbound** checked → Save.
5. Repeat for every row in the table that exists in that org.

## Method B — Execute Anonymous (faster, repeatable per org)

Paste into Developer Console (or VS Code) → Execute Anonymous, in each higher org.
Finds records by value (not ID), so it's portable across orgs. Safe to re-run — an
already-fixed org just returns 0 matches.

```apex
// SAL-7300 / SAL-7385 — disable Outbound on the TValue mappings that overwrite our
// own field writes (Required Adv. Payments, Total Financed Amount, Equipment Cost).
List<tval__TValue_Template_Field__c> toFix = [
    SELECT Id, tval__Parent_Template__r.Name, tval__Object_API_Name__c,
           tval__Source_Field__c, tval__TValue_Field_API__c,
           tval__Inbound__c, tval__Outbound__c
    FROM tval__TValue_Template_Field__c
    WHERE tval__Outbound__c = true
      AND (
        (tval__Object_API_Name__c = 'Opportunity' AND tval__Source_Field__c = 'required_adv_payments__c' AND tval__TValue_Field_API__c = 'numAdvancedPayments')
        OR (tval__Source_Field__c IN ('total_financed_amount__c','Total_Financed_Amount__c') AND tval__TValue_Field_API__c = 'quoteAmount')
        OR (tval__Object_API_Name__c = 'Opportunity' AND tval__Source_Field__c = 'equipment_cost__c' AND tval__TValue_Field_API__c = 'quoteAmount')
      )
];

System.debug('Found ' + toFix.size() + ' record(s) to fix:');
for (tval__TValue_Template_Field__c f : toFix) {
    System.debug(f.Id + ' | Template=' + f.tval__Parent_Template__r.Name
        + ' | ' + f.tval__Object_API_Name__c + '.' + f.tval__Source_Field__c
        + ' <-> ' + f.tval__TValue_Field_API__c
        + ' | Inbound=' + f.tval__Inbound__c + ' Outbound=' + f.tval__Outbound__c);
    f.tval__Outbound__c = false; // only flag being changed — Inbound is left untouched
}

if (!toFix.isEmpty()) {
    update toFix;
    System.debug('Updated ' + toFix.size() + ' record(s) — Outbound set to false.');
} else {
    System.debug('Nothing to update — already fixed, or templates not present in this org.');
}

// Re-query to confirm the flip landed
for (tval__TValue_Template_Field__c f : [
    SELECT Id, tval__Parent_Template__r.Name, tval__Object_API_Name__c,
           tval__Source_Field__c, tval__TValue_Field_API__c,
           tval__Inbound__c, tval__Outbound__c
    FROM tval__TValue_Template_Field__c
    WHERE Id IN :toFix
]) {
    System.debug('VERIFY ' + f.Id + ' | Template=' + f.tval__Parent_Template__r.Name
        + ' | ' + f.tval__Object_API_Name__c + '.' + f.tval__Source_Field__c
        + ' <-> ' + f.tval__TValue_Field_API__c
        + ' | Inbound=' + f.tval__Inbound__c + ' Outbound=' + f.tval__Outbound__c);
}
```

## Validation (per org, after the change)

1. Confirm flags flipped:
   ```bash
   sf data query -o <ORG_ALIAS> --query "SELECT tval__Parent_Template__r.Name, tval__Object_API_Name__c, tval__Source_Field__c, tval__TValue_Field_API__c, tval__Inbound__c, tval__Outbound__c FROM tval__TValue_Template_Field__c WHERE tval__Source_Field__c IN ('required_adv_payments__c','total_financed_amount__c','Total_Financed_Amount__c','equipment_cost__c')"
   ```
   Expect `Outbound__c = false`, `Inbound__c = true` on the 5 rows.
2. Functional test: create a New Quote with **Advance Payments = 2**, a **Down Payment**, a
   **Buy Down**, and gross **Equipment Cost / Financed Amount**; run through Quick App → Convert.
3. On the resulting Opportunity confirm: **# Required Adv. Payments = 2** (persists, does not
   revert to 0 after the *Automated Process* update), Down Payment / Buydown correct, and
   Equipment Cost / Total Financed Amount stay **gross** (not the net-of-down-payment value).

## Rollout order

Apply + validate in each org before promoting: **QA → Staging/Full → Production**, aligned
with the SAL-7300 / SAL-7385 Apex deployments.

## Important note on direction semantics

This doc assumes **Outbound = TValue writes back onto the Salesforce field** (the overwrite
direction), consistent with the SAL-7385 finding. Before bulk-applying in a new org, disable
Outbound on **one** record (the SAL-7300 row #1), run the functional test, and confirm the
value now persists. If it does, proceed with the rest. If behavior is unexpected, re-check
the Inbound/Outbound semantics in that org's TValue version before continuing.
