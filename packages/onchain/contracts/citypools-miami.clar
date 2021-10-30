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

;;      ////    STORAGE    \\\\     ;;

;; stores ticket data
(define-map Tickets
    { id: uint }
    { 
      owner: principal,
      totalMiaLocked: uint,
      lockedCycleLength: uint,
      hasBeenSelected: bool,
      endCycle: uint,
      active: bool
    }
)
;; stores the last 305 stackers tickets
(define-map StackersTickets
    { id: uint }
    { ticketIds: (list 305 uint) }
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

(define-public (create-ticket (amount uint))
  (let
    (
      (stackerId (get-or-create-stacker-id tx-sender))
      (stacker (unwrap! (get-stacker stackerId) (err ERR-STACKER-NOT-FOUND)))
      (ticketId (unwrap! (get-last-token-id) (err ERR-TOKEN-NOT-FOUND)))
    )

    (map-set Tickets { id: ticketId } 
      { 
        owner: tx-sender,
        totalMiaLocked: amount,
        lockedCycleLength: u6,
        hasBeenSelected: false,
        endCycle: u12,
        active: false 
      }
    )

    ;; add Ticket into StackersTickets (ticketIds)
    (map-set StackersTickets { id: stackerId } 
      { ticketIds: (unwrap-panic (as-max-len? (append (default-to (list) (get-ticket-ids stackerId)) ticketId) u200)) }
    )

    (ok true)
  )
)

;;      ****    PUBLIC    ****     ;;

(define-public (claim (amount uint))
  (begin
    (try! (contract-call? .poolmiami-ticket mint-ticket tx-sender amount))
    (try! (contract-call? .citycoin-core-v1 stack-tokens amount u2))
    (ok true)
  )
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

(define-read-only (get-last-token-id)
  (contract-call? .poolmiami-ticket get-last-token-id)
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

