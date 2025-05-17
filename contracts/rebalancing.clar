;; Rebalancing Contract
;; Adjusts positions for optimal returns

;; Store rebalance settings
(define-map rebalance-settings
  { user: principal }
  {
    auto-rebalance: bool,
    threshold-percentage: uint,
    last-rebalanced: uint
  }
)

;; Error codes
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-INVALID-THRESHOLD u2)

;; Set rebalance settings for a user
(define-public (set-rebalance-settings (auto-rebalance bool) (threshold-percentage uint))
  (begin
    (asserts! (is-eq tx-sender contract-caller) (err ERR-UNAUTHORIZED))
    (asserts! (<= threshold-percentage u100) (err ERR-INVALID-THRESHOLD))

    (ok (map-set rebalance-settings
      { user: tx-sender }
      {
        auto-rebalance: auto-rebalance,
        threshold-percentage: threshold-percentage,
        last-rebalanced: block-height
      }
    ))
  )
)

;; Trigger manual rebalance
(define-public (rebalance)
  (let (
    (settings (default-to
      { auto-rebalance: false, threshold-percentage: u0, last-rebalanced: u0 }
      (map-get? rebalance-settings { user: tx-sender })
    ))
  )
    (asserts! (is-eq tx-sender contract-caller) (err ERR-UNAUTHORIZED))

    ;; Update the last rebalanced time
    (ok (map-set rebalance-settings
      { user: tx-sender }
      (merge settings { last-rebalanced: block-height })
    ))
  )
)

;; Check if rebalance is needed for a user
(define-read-only (is-rebalance-needed (user principal))
  (let (
    (settings (default-to
      { auto-rebalance: false, threshold-percentage: u0, last-rebalanced: u0 }
      (map-get? rebalance-settings { user: user })
    ))
  )
    ;; Check if 24 hours passed (144 blocks)
    (> (- block-height (get last-rebalanced settings)) u144)
  )
)

;; Get rebalance settings for a user
(define-read-only (get-rebalance-settings (user principal))
  (map-get? rebalance-settings { user: user })
)
