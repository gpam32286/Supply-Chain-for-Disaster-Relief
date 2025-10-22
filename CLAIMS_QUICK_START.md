# Supply Claims Feature - Quick Start Guide 🚑

## ✅ Status
- Contract: **COMPILED** (0 errors, clarinet check passed)
- Line Endings: **LF normalized**
- Integration: **Complete**

## 📁 Files Modified
- `contracts/Relief.clar` - Added ~340 lines of claims module code (lines 271-607)

## 🎯 Core Features at a Glance

| Function | Role | Purpose |
|----------|------|---------|
| `claim-submit` | Submitter | File loss/damage claim for supply |
| `claim-verify` | Verifier | Assess claim and record findings |
| `claim-approve` | Approver | Approve claim and set compensation |
| `claim-reject` | Approver | Reject claim with reasoning |
| `claim-cancel` | Submitter | Withdraw submitted claim |

## 🔐 Role Management
Owner-only functions to manage three roles:

```clarity
(claim-add-verifier who)          ;; Register assessor
(claim-add-approver who)          ;; Register decision-maker
(claim-add-submitter who)         ;; Register claimant

(claim-remove-verifier who)       ;; Deregister assessor
(claim-remove-approver who)       ;; Deregister decision-maker
(claim-remove-submitter who)      ;; Deregister claimant
```

## 📊 Query Functions

```clarity
(claim-get claim-id)              ;; Get full claim record
(claim-get-status claim-id)       ;; Get claim status code
(claim-get-open-by-supply sid)    ;; Check for open claim on supply
(claim-get-latest-by-supply sid)  ;; Get most recent claim for supply
```

## 🔄 Claim States

```
SUBMITTED (1)  → VERIFIED (2) → APPROVED (3) or REJECTED (4)
                                  
                                  CANCELLED (5) ← from SUBMITTED
```

## 📈 Usage Flow

### Step 1: Owner Setup
```clarity
(claim-add-submitter 'claimant-principal)
(claim-add-verifier 'verifier-principal)
(claim-add-approver 'approver-principal)
```

### Step 2: Submit Claim
```clarity
(claim-submit u1 "Supply damaged in transit" u5000)
;; Returns: (ok claim-id) where claim-id = u1
```

### Step 3: Verify Assessment
```clarity
(claim-verify u1 "Confirmed damage to 40% of items" (some u4000))
;; Verifier records findings and reassesses amount
```

### Step 4: Approve/Reject
```clarity
(claim-approve u1 u4000 "Approved for compensation")
;; OR
(claim-reject u1 "Insufficient documentation")
```

## 🛠️ Error Codes

| Code | Error | Meaning |
|------|-------|---------|
| u1001 | unauthorized | Caller lacks required role |
| u1002 | not-found | Claim ID doesn't exist |
| u1003 | invalid-supply | Supply doesn't exist |
| u1004 | duplicate | Supply already has open claim |
| u1005 | invalid-amount | Amount ≤ 0 or exceeds claimed |
| u1006 | invalid-status | Claim not in expected state |
| u1007 | not-verified | Claim hasn't been verified |

## 📡 Events Emitted

All state transitions emit events for monitoring:

```
claim_submitted   → {claim_id, supply_id, amount, by, at}
claim_verified    → {claim_id, by, at}
claim_approved    → {claim_id, supply_id, amount, by, at}
claim_rejected    → {claim_id, supply_id, by, at}
claim_cancelled   → {claim_id, supply_id, by, at}
```

## 🔍 Integration Point

The feature checks supply existence via:

```clarity
(claim-supply-exists? supply-id)
;; Returns: true if supply exists, false otherwise
```

This ensures claims can only be filed for registered supplies.

## 💾 Data Persistence

All claim data is stored in immutable maps:

- **claim-claims**: Primary claim registry with full lifecycle
- **claim-supply-open**: Deduplication lock (cleared when resolved)
- **claim-supply-latest**: Latest claim tracker
- **claim-verifiers/approvers/submitters**: Role registries

## 🚀 Next Steps

1. **Commit Changes**
   ```bash
   git add contracts/Relief.clar
   git commit -m "Claims lifecycle for damaged/lost supplies: authorization, verification, decisioning, and audit trail 🚑📜"
   ```

2. **Create PR** using templates in `GIT_COMMIT_PR_TEMPLATE.md`

3. **Deploy** to testnet/mainnet once reviewed

4. **Monitor** via event logs for claim activity

## 📚 Documentation

- **Full Spec**: See `FEATURE_IMPLEMENTATION.md`
- **Commit/PR Templates**: See `GIT_COMMIT_PR_TEMPLATE.md`
- **Complete Code**: View `contracts/Relief.clar` lines 271-607

## ✨ Key Benefits

✅ **Trustless**: On-chain verification prevents fraud  
✅ **Transparent**: All stakeholders see claim lifecycle  
✅ **Auditable**: Complete immutable history  
✅ **Flexible**: Support for assessments and revised amounts  
✅ **Secure**: Role separation and authorization checks  
✅ **Self-contained**: No breaking changes to existing code  

---

**Ready to proceed?** Review the full spec in `FEATURE_IMPLEMENTATION.md` then follow the commit guide in `GIT_COMMIT_PR_TEMPLATE.md`.
