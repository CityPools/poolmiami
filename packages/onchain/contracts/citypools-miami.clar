;;      ////    ERRORS    \\\\      ;;

(define-constant err-not-owner u401)
(define-constant err-not-authorized u401)
(define-constant err-stacker-not-found u404)
(define-constant err-ticket-not-found u201)
(define-constant err-already-redeemed u209)
(define-constant err-invalid-amount u213)
(define-constant err-id-not-found u214)
(define-constant err-insufficient-balance u216)

;; filter vars
(define-data-var stacker-id-tip uint u0)

;;      ////    VARIABLES    \\\\     ;;

(define-data-var contract-owner principal tx-sender)
(define-data-var creator-address principal tx-sender)
(define-data-var mint-price-in-mia uint u305)
(define-data-var percent-of-mint-to-stack uint u700000)
(define-data-var percent-of-mint-to-dao uint u300000)
(define-data-var contract-stacking-stats uint u0)

;;      ////    CONFIG    \\\\      ;;
(define-constant default-cycle-length u1)

;;      ////    STORAGE    \\\\     ;;

;; stores ticket data
(define-map Tickets
    { id: uint }
    { 
      stacker: principal,
      amountStacked: uint, 
      activeStackingCycle: uint,
      hasClaimed: bool,
      cycleWon: (optional uint)
    }
)
;; stores the last 305 stackers tickets
(define-map StackersTickets
    { id: uint }
    { ticketIds: (list 305 uint) }
)

;; stores the amount of MIA stacked through CityPools
(define-map StackingStatsAtCycle
  { cycle: uint }
  {
    poolStackingContribution: uint,
    contractStackingContribution: uint
  }
)

;; lookup table to get principle from id
(define-map IdToPrincipal
    { id: uint }
    { stacker: principal}
)

;; lookup table to get id from principle
(define-map PrincipalToId
    { stacker: principal}
    { id: uint }
)

;;      ****    PRIVATE    ****     ;;

(define-private (get-or-create-stacker-id (stacker principal))
  (match 
    (get id (map-get? PrincipalToId { stacker: stacker })) stackerId stackerId
    (let
      ((newId (+ u1 (var-get stacker-id-tip))))
      (map-set StackersTickets { id: newId } { ticketIds: (list) })
      (map-set IdToPrincipal { id: newId } { stacker: stacker })
      (map-set PrincipalToId { stacker: stacker } { id: newId })
      (var-set stacker-id-tip newId)
      newId
    )
  )
)

(define-private (create-ticket (ticket-id uint) (amount uint))
  (let
    (
      (stackerId (get-or-create-stacker-id tx-sender))
      (stacker (unwrap! (get-stacker stackerId) (err err-stacker-not-found)))
      (currentCycle (default-to u0 (contract-call? .citycoin-core-v1 get-reward-cycle block-height)))
      (amountStackedByContract (/ (* (var-get mint-price-in-mia) (var-get percent-of-mint-to-stack)) u1000))
      (currentStackedAmount 
        (default-to u0
          (get poolStackingContribution 
            (map-get? StackingStatsAtCycle { cycle: currentCycle })
          )
        )
      )
      (currentContractStackedAmount 
        (default-to u0
          (get contractStackingContribution 
            (map-get? StackingStatsAtCycle { cycle: currentCycle })
          )
        )
      )
    )

    (map-set Tickets { id: ticket-id } 
      { 
        stacker: tx-sender,
        amountStacked: amount,
        activeStackingCycle: (+ currentCycle default-cycle-length),
        hasClaimed: false,
        cycleWon: none
      }
    )

    (map-set StackersTickets { id: stackerId } 
      { ticketIds: (unwrap-panic (as-max-len? (append (default-to (list) (get-ticket-ids stackerId)) ticket-id) u200)) }
    )

    (map-set StackingStatsAtCycle { cycle: currentCycle }
      { 
        poolStackingContribution: (+ currentStackedAmount amount), 
        contractStackingContribution: (+ currentContractStackedAmount amountStackedByContract) 
      }
    )
    
    (ok true)
  )
)

(define-private (is-stacking-winner-and-can-claim (stacker principal) (cycle uint) (testCanClaim bool))
  (let
    (
      (stackerId (principal-to-id stacker))
    )
    (asserts! (is-eq tx-sender stacker) (err err-not-owner))
    (print stackerId)
    (ok true)
  )
)

;;      ****    PUBLIC    ****     ;;

(define-public (claim (amount uint))
  (let
    (
      (tokenId (try! (contract-call? .poolmiami-ticket mint-ticket tx-sender amount)))
      (amountStackedByContract (/ (* (var-get mint-price-in-mia) (var-get percent-of-mint-to-stack)) u1000))
      (amountAllocatedToDAO (/ (* (var-get mint-price-in-mia) (var-get percent-of-mint-to-dao)) u1000))
    )
    (begin
      (try! (contract-call? .citycoin-token transfer amount tx-sender (as-contract tx-sender) (some 0x11))) ;; transfer desired stacked amount to contract for stacking
      (try! (contract-call? .citycoin-token transfer amountStackedByContract tx-sender (as-contract tx-sender) (some 0x11))) ;; transfer 70% of the mint fee for contract's stacking contribution
      (try! (contract-call? .citycoin-token transfer amountAllocatedToDAO tx-sender .citypools-dao (some 0x11))) ;; transfer 30% of the mint fee to PoolMiami DAO
      (try! (as-contract (contract-call? .citycoin-core-v1 stack-tokens amount default-cycle-length)))
      (try! (create-ticket tokenId amount))
      (ok true)
    )
  )
)

(define-public (claim-reward (cycle uint))
  (ok true)
)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err err-not-owner))
    (ok (var-set contract-owner new-owner))
  )
)

;;      ****    READ-ONLY    ****     ;;

(define-read-only (get-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-stacker (id uint))
  (map-get? StackersTickets { id: id })
)

(define-read-only (get-ticket (id uint))
  (map-get? Tickets { id: id })
)

(define-read-only (get-ticket-ids (id uint))
  (get ticketIds (map-get? StackersTickets { id: id }))
)

(define-read-only (principal-to-id (stacker principal))
  (get id (map-get? PrincipalToId { stacker: stacker }))
)

(define-read-only (id-to-principal (id uint))
  (get stacker (map-get? IdToPrincipal { id: id }))
)

(define-read-only (is-stacking-winner (stacker principal) (cycle uint))
  (is-stacking-winner-and-can-claim stacker cycle false)
)

(define-read-only (can-claim-stacking-reward (stacker principal) (cycle uint))
  (is-stacking-winner-and-can-claim stacker cycle true)
)

