;; Yield Tracking Contract
;; Monitors return rates

;; Define contract owner
(define-data-var contract-owner principal tx-sender)

;; Store protocol yields
(define-map protocol-yields
  { protocol: principal }
  {
    apy: uint,
    last-updated: uint
  }
)

;; Store user yields
(define-map user-yields
  { user: principal }
  {
    total-yield: uint,
    last-updated: uint
  }
)

;; Error codes
(define-constant ERR-UNAUTHORIZED u1)

;; Update the APY for a protocol (only callable by contract owner)
(define-public (update-protocol-apy (protocol principal) (new-apy uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-UNAUTHORIZED))

    (ok (map-set protocol-yields
      { protocol: protocol }
      {
        apy: new-apy,
        last-updated: block-height
      }
    ))
  )
)

;; Get the APY for a protocol
(define-read-only (get-protocol-apy (protocol principal))
  (map-get? protocol-yields { protocol: protocol })
)

;; Record yield for a user
(define-public (record-user-yield (user principal) (yield-amount uint))
  (let (
    (current-data (map-get? user-yields { user: user }))
    (current-yield (default-to u0 (get total-yield current-data)))
  )
    (ok (map-set user-yields
      { user: user }
      {
        total-yield: (+ current-yield yield-amount),
        last-updated: block-height
      }
    ))
  )
)

;; Get yield for a user
(define-read-only (get-user-yield (user principal))
  (map-get? user-yields { user: user })
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)
