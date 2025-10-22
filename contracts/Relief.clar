(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-supply-delivered (err u106))
(define-constant err-supply-lost (err u107))

(define-constant status-registered u0)
(define-constant status-in-transit u1)
(define-constant status-at-checkpoint u2)
(define-constant status-delivered u3)
(define-constant status-lost u4)
(define-constant status-verified u5)

(define-map supplies 
    { supply-id: uint }
    {
        name: (string-ascii 50),
        category: (string-ascii 20),
        quantity: uint,
        unit: (string-ascii 10),
        source: principal,
        destination: (string-ascii 100),
        current-status: uint,
        current-location: (string-ascii 100),
        created-at: uint,
        updated-at: uint,
        verified: bool
    }
)

(define-map supply-history
    { supply-id: uint, sequence: uint }
    {
        status: uint,
        location: (string-ascii 100),
        timestamp: uint,
        updated-by: principal,
        notes: (string-ascii 200)
    }
)

(define-map authorized-operators principal bool)
(define-map supply-verifications
    { supply-id: uint }
    {
        verified-by: principal,
        verified-at: uint,
        verification-notes: (string-ascii 200)
    }
)

(define-data-var next-supply-id uint u1)
(define-data-var total-supplies uint u0)
(define-data-var total-delivered uint u0)

(define-public (add-operator (operator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-operators operator true)
        (ok true)
    )
)

(define-public (remove-operator (operator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-delete authorized-operators operator)
        (ok true)
    )
)

(define-public (register-supply
    (name (string-ascii 50))
    (category (string-ascii 20))
    (quantity uint)
    (unit (string-ascii 10))
    (destination (string-ascii 100))
    (initial-location (string-ascii 100))
)
    (let
        (
            (supply-id (var-get next-supply-id))
            (current-height burn-block-height)
        )
        (asserts! (> (len name) u0) err-invalid-input)
        (asserts! (> quantity u0) err-invalid-input)
        (asserts! (is-none (map-get? supplies { supply-id: supply-id })) err-already-exists)
        
        (map-set supplies 
            { supply-id: supply-id }
            {
                name: name,
                category: category,
                quantity: quantity,
                unit: unit,
                source: tx-sender,
                destination: destination,
                current-status: status-registered,
                current-location: initial-location,
                created-at: current-height,
                updated-at: current-height,
                verified: false
            }
        )
        
        (map-set supply-history
            { supply-id: supply-id, sequence: u0 }
            {
                status: status-registered,
                location: initial-location,
                timestamp: current-height,
                updated-by: tx-sender,
                notes: "Supply registered"
            }
        )
        
        (var-set next-supply-id (+ supply-id u1))
        (var-set total-supplies (+ (var-get total-supplies) u1))
        (ok supply-id)
    )
)

(define-public (update-supply-status
    (supply-id uint)
    (new-status uint)
    (new-location (string-ascii 100))
    (notes (string-ascii 200))
)
    (let
        (
            (supply-data (unwrap! (map-get? supplies { supply-id: supply-id }) err-not-found))
            (current-height burn-block-height)
            (history-sequence (get-next-history-sequence supply-id))
        )
        (asserts! (or (is-eq tx-sender contract-owner)
                     (is-eq tx-sender (get source supply-data))
                     (default-to false (map-get? authorized-operators tx-sender))) err-unauthorized)
        (asserts! (<= new-status status-verified) err-invalid-status)
        (asserts! (< (get current-status supply-data) status-delivered) err-supply-delivered)
        
        (map-set supplies
            { supply-id: supply-id }
            (merge supply-data {
                current-status: new-status,
                current-location: new-location,
                updated-at: current-height
            })
        )
        
        (map-set supply-history
            { supply-id: supply-id, sequence: history-sequence }
            {
                status: new-status,
                location: new-location,
                timestamp: current-height,
                updated-by: tx-sender,
                notes: notes
            }
        )
        
        (if (is-eq new-status status-delivered)
            (var-set total-delivered (+ (var-get total-delivered) u1))
            true
        )
        
        (ok true)
    )
)

(define-public (verify-supply
    (supply-id uint)
    (verification-notes (string-ascii 200))
)
    (let
        (
            (supply-data (unwrap! (map-get? supplies { supply-id: supply-id }) err-not-found))
            (current-height burn-block-height)
        )
        (asserts! (or (is-eq tx-sender contract-owner)
                     (default-to false (map-get? authorized-operators tx-sender))) err-unauthorized)
        (asserts! (>= (get current-status supply-data) status-delivered) err-invalid-status)
        
        (map-set supplies
            { supply-id: supply-id }
            (merge supply-data {
                verified: true,
                updated-at: current-height
            })
        )
        
        (map-set supply-verifications
            { supply-id: supply-id }
            {
                verified-by: tx-sender,
                verified-at: current-height,
                verification-notes: verification-notes
            }
        )
        
        (ok true)
    )
)

(define-read-only (get-supply (supply-id uint))
    (map-get? supplies { supply-id: supply-id })
)

(define-read-only (get-supply-history (supply-id uint) (sequence uint))
    (map-get? supply-history { supply-id: supply-id, sequence: sequence })
)

(define-read-only (get-supply-verification (supply-id uint))
    (map-get? supply-verifications { supply-id: supply-id })
)

(define-read-only (is-authorized-operator (operator principal))
    (default-to false (map-get? authorized-operators operator))
)

(define-read-only (get-contract-stats)
    {
        total-supplies: (var-get total-supplies),
        total-delivered: (var-get total-delivered),
        next-supply-id: (var-get next-supply-id),
        contract-owner: contract-owner
    }
)

(define-read-only (get-supplies-by-status (status uint))
    (filter check-supply-status (enumerate-supplies))
)

(define-private (get-next-history-sequence (supply-id uint))
    (let ((current-seq (default-to u0 (get-last-sequence supply-id))))
        (+ current-seq u1)
    )
)

(define-private (get-last-sequence (supply-id uint))
    (fold check-sequence (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9) (some u0))
)

(define-private (check-sequence (seq uint) (last-found (optional uint)))
    (if (is-some (map-get? supply-history { supply-id: u1, sequence: seq }))
        (some seq)
        last-found
    )
)

(define-private (enumerate-supplies)
    (map get-supply-id-tuple (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10))
)

(define-private (get-supply-id-tuple (id uint))
    { supply-id: id }
)

(define-private (check-supply-status (supply-tuple { supply-id: uint }))
    (let ((supply-data (map-get? supplies supply-tuple)))
        (if (is-some supply-data)
            (is-eq (get current-status (unwrap-panic supply-data)) status-delivered)
            false
        )
    )
)

(define-constant claim-err-unauthorized (err u1001))
(define-constant claim-err-not-found (err u1002))
(define-constant claim-err-invalid-supply (err u1003))
(define-constant claim-err-duplicate (err u1004))
(define-constant claim-err-invalid-amount (err u1005))
(define-constant claim-err-invalid-status (err u1006))
(define-constant claim-err-not-verified (err u1007))

(define-constant claim-status-submitted u1)
(define-constant claim-status-verified u2)
(define-constant claim-status-approved u3)
(define-constant claim-status-rejected u4)
(define-constant claim-status-cancelled u5)

(define-data-var claim-next-id uint u1)

(define-map claim-claims
  {id: uint}
  {
    supply-id: uint,
    claimant: principal,
    reason: (string-utf8 256),
    claimed-amount: uint,
    verifier: (optional principal),
    assessment-notes: (optional (string-utf8 256)),
    assessment-amount: (optional uint),
    approved-amount: (optional uint),
    approver: (optional principal),
    decision-notes: (optional (string-utf8 256)),
    status: uint,
    submitted-at: uint,
    verified-at: (optional uint),
    decided-at: (optional uint)
  }
)

(define-map claim-supply-open {supply-id: uint} {claim-id: uint})
(define-map claim-supply-latest {supply-id: uint} {claim-id: uint})
(define-map claim-verifiers {principal: principal} {enabled: bool})
(define-map claim-approvers {principal: principal} {enabled: bool})
(define-map claim-submitters {principal: principal} {enabled: bool})

(define-read-only (claim-is-owner (who principal))
  (is-eq who contract-owner)
)

(define-read-only (claim-is-verifier? (who principal))
  (or (claim-is-owner who) (is-some (map-get? claim-verifiers {principal: who})))
)

(define-read-only (claim-is-approver? (who principal))
  (or (claim-is-owner who) (is-some (map-get? claim-approvers {principal: who})))
)

(define-read-only (claim-is-submitter? (who principal))
  (or (claim-is-owner who) (is-some (map-get? claim-submitters {principal: who})))
)

(define-read-only (claim-supply-exists? (supply-id uint))
  (is-some (map-get? supplies {supply-id: supply-id}))
)

(define-private (claim-next-id-internal)
  (let ((id (var-get claim-next-id)))
    (begin
      (var-set claim-next-id (+ id u1))
      id
    )
  )
)

(define-public (claim-add-verifier (who principal))
  (if (claim-is-owner tx-sender)
      (begin (map-set claim-verifiers {principal: who} {enabled: true}) (ok true))
      claim-err-unauthorized
  )
)

(define-public (claim-remove-verifier (who principal))
  (if (claim-is-owner tx-sender)
      (begin (map-delete claim-verifiers {principal: who}) (ok true))
      claim-err-unauthorized
  )
)

(define-public (claim-add-approver (who principal))
  (if (claim-is-owner tx-sender)
      (begin (map-set claim-approvers {principal: who} {enabled: true}) (ok true))
      claim-err-unauthorized
  )
)

(define-public (claim-remove-approver (who principal))
  (if (claim-is-owner tx-sender)
      (begin (map-delete claim-approvers {principal: who}) (ok true))
      claim-err-unauthorized
  )
)

(define-public (claim-add-submitter (who principal))
  (if (claim-is-owner tx-sender)
      (begin (map-set claim-submitters {principal: who} {enabled: true}) (ok true))
      claim-err-unauthorized
  )
)

(define-public (claim-remove-submitter (who principal))
  (if (claim-is-owner tx-sender)
      (begin (map-delete claim-submitters {principal: who}) (ok true))
      claim-err-unauthorized
  )
)

(define-public (claim-submit (supply-id uint) (reason (string-utf8 256)) (amount uint))
  (begin
    (if (not (claim-supply-exists? supply-id))
        claim-err-invalid-supply
        (if (not (> amount u0))
            claim-err-invalid-amount
            (if (not (claim-is-submitter? tx-sender))
                claim-err-unauthorized
                (let ((existing (map-get? claim-supply-open {supply-id: supply-id})))
                  (if (is-some existing)
                      claim-err-duplicate
                      (let ((id (claim-next-id-internal)))
                        (begin
                          (map-set claim-claims {id: id}
                            {
                              supply-id: supply-id,
                              claimant: tx-sender,
                              reason: reason,
                              claimed-amount: amount,
                              verifier: none,
                              assessment-notes: none,
                              assessment-amount: none,
                              approved-amount: none,
                              approver: none,
                              decision-notes: none,
                              status: claim-status-submitted,
                              submitted-at: burn-block-height,
                              verified-at: none,
                              decided-at: none
                            }
                          )
                          (map-set claim-supply-open {supply-id: supply-id} {claim-id: id})
                          (map-set claim-supply-latest {supply-id: supply-id} {claim-id: id})
                          (print {event: "claim_submitted", claim_id: id, supply_id: supply-id, amount: amount, by: tx-sender, at: burn-block-height})
                          (ok id)
                        )
                      )
                  )
                )
            )
        )
    )
  )
)

(define-public (claim-verify (claim-id uint) (notes (string-utf8 256)) (assessed-amount (optional uint)))
  (begin
    (if (not (claim-is-verifier? tx-sender))
        claim-err-unauthorized
        (match (map-get? claim-claims {id: claim-id})
          claim
          (if (is-eq (get status claim) claim-status-submitted)
              (begin
                (map-set claim-claims {id: claim-id}
                  {
                    supply-id: (get supply-id claim),
                    claimant: (get claimant claim),
                    reason: (get reason claim),
                    claimed-amount: (get claimed-amount claim),
                    verifier: (some tx-sender),
                    assessment-notes: (some notes),
                    assessment-amount: assessed-amount,
                    approved-amount: (get approved-amount claim),
                    approver: (get approver claim),
                    decision-notes: (get decision-notes claim),
                    status: claim-status-verified,
                    submitted-at: (get submitted-at claim),
                    verified-at: (some burn-block-height),
                    decided-at: (get decided-at claim)
                  }
                )
                (print {event: "claim_verified", claim_id: claim-id, by: tx-sender, at: burn-block-height})
                (ok true)
              )
              claim-err-invalid-status
          )
          claim-err-not-found
        )
    )
  )
)

(define-public (claim-approve (claim-id uint) (approved-amount uint) (notes (string-utf8 256)))
  (begin
    (if (not (claim-is-approver? tx-sender))
        claim-err-unauthorized
        (match (map-get? claim-claims {id: claim-id})
          claim
          (if (is-eq (get status claim) claim-status-verified)
              (if (> approved-amount (get claimed-amount claim))
                  claim-err-invalid-amount
                  (begin
                    (map-set claim-claims {id: claim-id}
                      {
                        supply-id: (get supply-id claim),
                        claimant: (get claimant claim),
                        reason: (get reason claim),
                        claimed-amount: (get claimed-amount claim),
                        verifier: (get verifier claim),
                        assessment-notes: (get assessment-notes claim),
                        assessment-amount: (get assessment-amount claim),
                        approved-amount: (some approved-amount),
                        approver: (some tx-sender),
                        decision-notes: (some notes),
                        status: claim-status-approved,
                        submitted-at: (get submitted-at claim),
                        verified-at: (get verified-at claim),
                        decided-at: (some burn-block-height)
                      }
                    )
                    (let ((sid (get supply-id claim)))
                      (begin
                        (map-delete claim-supply-open {supply-id: sid})
                        (print {event: "claim_approved", claim_id: claim-id, supply_id: sid, amount: approved-amount, by: tx-sender, at: burn-block-height})
                        (ok true)
                      )
                    )
                  )
              )
              claim-err-not-verified
          )
          claim-err-not-found
        )
    )
  )
)

(define-public (claim-reject (claim-id uint) (notes (string-utf8 256)))
  (begin
    (if (not (claim-is-approver? tx-sender))
        claim-err-unauthorized
        (match (map-get? claim-claims {id: claim-id})
          claim
          (if (is-eq (get status claim) claim-status-verified)
              (begin
                (map-set claim-claims {id: claim-id}
                  {
                    supply-id: (get supply-id claim),
                    claimant: (get claimant claim),
                    reason: (get reason claim),
                    claimed-amount: (get claimed-amount claim),
                    verifier: (get verifier claim),
                    assessment-notes: (get assessment-notes claim),
                    assessment-amount: (get assessment-amount claim),
                    approved-amount: none,
                    approver: (some tx-sender),
                    decision-notes: (some notes),
                    status: claim-status-rejected,
                    submitted-at: (get submitted-at claim),
                    verified-at: (get verified-at claim),
                    decided-at: (some burn-block-height)
                  }
                )
                (let ((sid (get supply-id claim)))
                  (begin
                    (map-delete claim-supply-open {supply-id: sid})
                    (print {event: "claim_rejected", claim_id: claim-id, supply_id: sid, by: tx-sender, at: burn-block-height})
                    (ok true)
                  )
                )
              )
              claim-err-not-verified
          )
          claim-err-not-found
        )
    )
  )
)

(define-public (claim-cancel (claim-id uint))
  (match (map-get? claim-claims {id: claim-id})
    claim
    (if (and (is-eq (get status claim) claim-status-submitted) (is-eq (get claimant claim) tx-sender))
        (begin
          (map-set claim-claims {id: claim-id}
            {
              supply-id: (get supply-id claim),
              claimant: (get claimant claim),
              reason: (get reason claim),
              claimed-amount: (get claimed-amount claim),
              verifier: (get verifier claim),
              assessment-notes: (get assessment-notes claim),
              assessment-amount: (get assessment-amount claim),
              approved-amount: (get approved-amount claim),
              approver: (get approver claim),
              decision-notes: (get decision-notes claim),
              status: claim-status-cancelled,
              submitted-at: (get submitted-at claim),
              verified-at: (get verified-at claim),
              decided-at: (some burn-block-height)
            }
          )
          (let ((sid (get supply-id claim)))
            (begin
              (map-delete claim-supply-open {supply-id: sid})
              (print {event: "claim_cancelled", claim_id: claim-id, supply_id: sid, by: tx-sender, at: burn-block-height})
              (ok true)
            )
          )
        )
        claim-err-invalid-status
    )
    claim-err-not-found
  )
)

(define-read-only (claim-get (claim-id uint))
  (map-get? claim-claims {id: claim-id})
)

(define-read-only (claim-get-status (claim-id uint))
  (match (map-get? claim-claims {id: claim-id})
    claim (ok (get status claim))
    claim-err-not-found
  )
)

(define-read-only (claim-get-open-by-supply (supply-id uint))
  (map-get? claim-supply-open {supply-id: supply-id})
)

(define-read-only (claim-get-latest-by-supply (supply-id uint))
  (map-get? claim-supply-latest {supply-id: supply-id})
)
