;; Fee Optimization Contract
;; Minimizes transaction costs

;; Define contract owner
(define-data-var contract-owner principal tx-sender)

;; Store gas price estimate
(define-data-var gas-price-estimate uint u10)

;; Store gas price history
(define-map gas-price-history
  { block-height: uint }
  { price: uint }
)

;; Store user fee settings
(define-map user-fee-settings
  { user: principal }
  {
    max-fee: uint,
    priority-level: uint
  }
)

;; Error codes
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-INVALID-PRIORITY u2)

;; Update gas price estimate
(define-public (update-gas-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-UNAUTHORIZED))

    ;; Record history
    (map-set gas-price-history
      { block-height: block-height }
      { price: new-price }
    )

    ;; Update current estimate
    (ok (var-set gas-price-estimate new-price))
  )
)

;; Set fee settings for a user
(define-public (set-fee-settings (max-fee uint) (priority-level uint))
  (begin
    (asserts! (is-eq tx-sender contract-caller) (err ERR-UNAUTHORIZED))
    (asserts! (<= priority-level u3) (err ERR-INVALID-PRIORITY))

    (ok (map-set user-fee-settings
      { user: tx-sender }
      {
        max-fee: max-fee,
        priority-level: priority-level
      }
    ))
  )
)

;; Calculate optimal gas price based on user settings
(define-read-only (calculate-optimal-fee (user principal))
  (let (
    (current-gas-price (var-get gas-price-estimate))
    (user-settings (default-to
      { max-fee: u100, priority-level: u1 }
      (map-get? user-fee-settings { user: user })
    ))
    (priority-multiplier (+ u10 (* u5 (get priority-level user-settings))))
    (calculated-fee (/ (* current-gas-price priority-multiplier) u100))
  )
    ;; Implement min function manually since Clarity doesn't have min
    (if (<= calculated-fee (get max-fee user-settings))
        calculated-fee
        (get max-fee user-settings))
  )
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)
