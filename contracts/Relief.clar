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
