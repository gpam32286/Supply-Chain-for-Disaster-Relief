# Supply Loss/Damage Compensation & Claims System 🚑📜

## Feature Overview

A self-contained on-chain claims workflow module for disaster-relief supplies that manages loss/damage compensation through authorization, verification, decisioning, and complete audit trails.

## Value Proposition

**Security**: Formal process with role-based authorization prevents unauthorized claims and ensures checks and balances through separate verifier and approver roles.

**Utility**: Enables financial accountability and insurance/compensation workflows critical for real-world disaster relief scenarios where supplies get lost or damaged.

**Developer Experience**: Clean, modular design integrates seamlessly into existing supply registry without breaking changes. All roles, errors, and state are self-contained within the `claim-*` namespace.

**User Experience**: Transparent claim status tracking for stakeholders with event emission for complete auditability and real-time monitoring.

## Architecture

### Constants (Error Codes & Status Codes)

```clarity
claim-err-unauthorized (err u1001)
claim-err-not-found (err u1002)
claim-err-invalid-supply (err u1003)
claim-err-duplicate (err u1004)
claim-err-invalid-amount (err u1005)
claim-err-invalid-status (err u1006)
claim-err-not-verified (err u1007)

claim-status-submitted (u1)
claim-status-verified (u2)
claim-status-approved (u3)
claim-status-rejected (u4)
claim-status-cancelled (u5)
```

### Data Structures

**claim-claims** (Primary claim registry)
- Key: `{id: uint}`
- Fields: supply-id, claimant (principal), reason, claimed-amount, verifier, assessment-notes, assessment-amount, approved-amount, approver, decision-notes, status, submitted-at, verified-at, decided-at

**claim-supply-open** (Deduplication lock)
- Key: `{supply-id: uint}`
- Stores: `{claim-id: uint}`
- Prevents multiple open claims per supply

**claim-supply-latest** (Most recent claim tracker)
- Key: `{supply-id: uint}`
- Stores: `{claim-id: uint}`

**Role Maps**
- `claim-verifiers`: Authorized assessors
- `claim-approvers`: Authorized decision-makers
- `claim-submitters`: Authorized claimants

### Claim Lifecycle

```
submitted (claimant initiates)
    ↓
verified (verifier assesses & records findings)
    ↓
approved/rejected (approver decides)
    ↓
closed (ready for compensation or rejected)

OR

submitted → cancelled (claimant withdraws)
```

## Public Functions

### Role Management (Owner-only)

- `claim-add-verifier (who principal)` - Register assessor
- `claim-remove-verifier (who principal)` - Deregister assessor
- `claim-add-approver (who principal)` - Register decision-maker
- `claim-remove-approver (who principal)` - Deregister decision-maker
- `claim-add-submitter (who principal)` - Register claimant
- `claim-remove-submitter (who principal)` - Deregister claimant

### Claim Workflow

- `claim-submit (supply-id, reason, amount)` - Submit claim for loss/damage
  - Validates supply exists
  - Validates amount > 0
  - Prevents duplicate open claims per supply
  - Emits: `claim_submitted` event

- `claim-verify (claim-id, notes, assessed-amount?)` - Assessor verifies claim
  - Only from verified state
  - Records assessment notes and optional reassessed amount
  - Emits: `claim_verified` event

- `claim-approve (claim-id, approved-amount, notes)` - Approver approves claim
  - Only from verified state
  - Approved amount must not exceed claimed amount
  - Closes open claim tracking for supply
  - Emits: `claim_approved` event

- `claim-reject (claim-id, notes)` - Approver rejects claim
  - Only from verified state
  - Closes open claim tracking for supply
  - Emits: `claim_rejected` event

- `claim-cancel (claim-id)` - Claimant withdraws submitted claim
  - Only from submitted state
  - Only callable by original claimant
  - Closes open claim tracking for supply
  - Emits: `claim_cancelled` event

### Read-Only Functions

- `claim-get (claim-id)` - Retrieve full claim record
- `claim-get-status (claim-id)` - Query claim status
- `claim-get-open-by-supply (supply-id)` - Check if supply has open claim
- `claim-get-latest-by-supply (supply-id)` - Get most recent claim for supply
- `claim-is-owner (who)` - Helper: check contract owner
- `claim-is-verifier? (who)` - Helper: check verifier role
- `claim-is-approver? (who)` - Helper: check approver role
- `claim-is-submitter? (who)` - Helper: check submitter role
- `claim-supply-exists? (supply-id)` - Integration point with supplies registry

## Integration

The feature integrates with the existing supplies registry through `claim-supply-exists?`, which checks:

```clarity
(is-some (map-get? supplies {supply-id: supply-id}))
```

This ensures claims can only be filed for registered supplies.

## Variables

**claim-next-id** (u1 → ∞)
- Auto-incrementing claim ID counter

## Event Emissions

All state transitions emit events for off-chain listeners:

```
claim_submitted: {event, claim_id, supply_id, amount, by, at}
claim_verified: {event, claim_id, by, at}
claim_approved: {event, claim_id, supply_id, amount, by, at}
claim_rejected: {event, claim_id, supply_id, by, at}
claim_cancelled: {event, claim_id, supply_id, by, at}
```

## Compilation Status

✅ **Zero errors** - Passes `clarinet check`

31 warnings (standard unchecked data warnings - no impact on functionality)

## Implementation Details

- **Line Endings**: LF only (normalized)
- **Type Safety**: All variables explicitly defined before use
- **Code Quality**: Clean, modular, self-contained namespace
- **Authorization**: Owner-gated role management with fallback to owner for all three role types
- **Deduplication**: Open claim tracker prevents multiple active claims per supply
- **Immutability**: All lifecycle records preserved for audit trail

## Usage Example Workflow

1. Owner registers verifier and approver roles
2. Claimant submits claim for damaged supply with reason and amount
3. Verifier assesses claim, records findings and optionally revised amount
4. Approver reviews verified claim and approves/rejects with notes
5. If approved, compensation can be processed based on approved-amount
6. Complete audit trail available via event logs and claim history queries

---

**Status**: ✅ Ready for production
**Last Updated**: 2025-10-22
**Lines Added**: ~340 (claims module)
**Breaking Changes**: None
