;;      ////    ERRORS    \\\\      ;;

(define-constant ERR-NOT-OWNER u401)
(define-constant ERR-NOT-AUTHORIZED u401)
(define-constant ERR-STACKER-NOT-FOUND u404)
(define-constant ERR-TOKEN-NOT-FOUND u405)
(define-constant ERR-TICKET-NOT-FOUND u201)
(define-constant ERR-BLOCK-ALREADY-CHECKED u205)
(define-constant ERR-WAIT-100-BLOCKS-BEFORE-CHECKING u206)
(define-constant ERR-ALL-POSSIBLE-BLOCKS-CHECKED u207)
(define-constant ERR-ALL-WINNERS-PAID u209)
(define-constant ERR-INVALID-AMOUNT u213)
(define-constant ERR-ID-NOT-FOUND u214)
(define-constant ERR-ID-NOT-IN-TICKET u215)
(define-constant ERR-INSUFFICIENT-BALANCE u216)

;; filter vars
(define-data-var stackerIdTip uint u0)
(define-data-var idToRemove uint u0)

;;      ////    VARIABLES    \\\\     ;;

(define-data-var contract-owner principal tx-sender)
(define-data-var creator-address principal tx-sender)

;;      ////    CONFIG    \\\\      ;;

(define-constant mintFee u1000000)
(define-constant minContribution u10000000)
(define-constant defaultCycle u6)

;;      ////    STORAGE    \\\\     ;;

;; stores ticket data
(define-map Tickets
    { id: uint }
    { 
      stacker: principal,
      amountStacked: uint,
      hasClaimed: bool,
      isWinner: bool,
      endCycle: uint
    }
)
;; stores the last 305 stackers tickets
(define-map StackersTickets
    { id: uint }
    { ticketIds: (list 305 uint) }
)

;; stores the amount of MIA stacked through CityPools
(define-map StackingStatsAtCycle
  uint
  {
    amountStacked: uint
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
      ((newId (+ u1 (var-get stackerIdTip))))
      (map-set StackersTickets { id: newId } { ticketIds: (list) })
      (map-set IdToPrincipal { id: newId } { stacker: stacker })
      (map-set PrincipalToId { stacker: stacker } { id: newId })
      (var-set stackerIdTip newId)
      newId
    )
  )
)

(define-public (create-ticket (ticket-id uint) (amount uint))
  (let
    (
      (stackerId (get-or-create-stacker-id tx-sender))
      (stacker (unwrap! (get-stacker stackerId) (err ERR-STACKER-NOT-FOUND)))
      (currentCycle (default-to u0 (contract-call? .citycoin-core-v1 get-reward-cycle block-height)))
      (currentStackedAmount 
        (default-to u0
          (get amountStacked 
            (map-get? StackingStatsAtCycle currentCycle)
          )
        )
      )
    )

    (map-set Tickets { id: ticket-id } 
      { 
        stacker: tx-sender,
        amountStacked: amount,
        hasClaimed: false,
        isWinner: false,
        endCycle: u12
      }
    )

    (map-set StackersTickets { id: stackerId } 
      { ticketIds: (unwrap-panic (as-max-len? (append (default-to (list) (get-ticket-ids stackerId)) ticket-id) u200)) }
    )

    (map-set StackingStatsAtCycle currentCycle
      { amountStacked: (+ currentStackedAmount amount) }
    )
    
    (ok true)
  )
)

(define-private (is-stacking-winner-and-can-claim (stacker principal) (cycle uint) (testCanClaim bool))
  (let
    (
      (stackerId (principal-to-id stacker))
    )
    (asserts! (is-eq tx-sender stacker) (err ERR-NOT-OWNER))
    (print stackerId)
    (ok true)
  )
)

;;      ****    PUBLIC    ****     ;;

(define-public (claim (amount uint))
  (let
    (
      (tokenId (try! (contract-call? .poolmiami-ticket mint-ticket tx-sender amount)))
    )
    (try! (create-ticket tokenId amount))
    (try! (as-contract (contract-call? .citycoin-core-v1 stack-tokens amount defaultCycle)))
    (ok true)
  )
)

(define-public (claim-reward (cycle uint))
  (ok true)
)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-OWNER))
    (ok (var-set contract-owner new-owner))
  )
)

(define-public (transfer-stx (address principal) (amount uint))
  (as-contract (stx-transfer? amount tx-sender (as-contract tx-sender)))
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

