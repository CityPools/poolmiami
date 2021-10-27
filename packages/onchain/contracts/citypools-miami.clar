;;      ////    ERRORS    \\\\      ;;

(define-constant ERR_NOT_OWNER 401)
(define-constant ERR_NOT_AUTHORIZED 401)
(define-constant ERR_STACKER_NOT_FOUND 404)
(define-constant ERR_CONTRIBUTION_TOO_LOW u200)
(define-constant ERR_ROUND_NOT_FOUND u201)
(define-constant ERR_CANNOT_MINE_IF_ROUND_ACTIVE u202)
(define-constant ERR_CANNOT_MODIFY_FUNDS_OF_EXPIRED_ROUND u203)
(define-constant ERR_MINE_TOTAL_NOT_BALANCE_TOTAL u204)
(define-constant ERR_BLOCK_ALREADY_CHECKED u205)
(define-constant ERR_WAIT_100_BLOCKS_BEFORE_CHECKING u206)
(define-constant ERR_ALL_POSSIBLE_BLOCKS_CHECKED u207)
(define-constant ERR_MUST_REDEEM_ALL_WON_BLOCKS u208)
(define-constant ERR_ALL_PARTICIPANTS_PAID u209)
(define-constant ERR_MINING_NOT_STARTED u210)
(define-constant ERR_ALREADY_MINED u211)
(define-constant ERR_MUST_CHECK_ALL_MINED_BLOCKS u212)
(define-constant ERR_INVALID_AMOUNT u213)
(define-constant ERR_ID_NOT_FOUND u214)
(define-constant ERR_ID_NOT_IN_ROUND u215)
(define-constant ERR_INSUFFICIENT_BALANCE u216)

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
      endCycle: uint
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
  (match (get id (map-get? PrincipalToId { stacker: stacker })) stackerId stackerId
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

;;      ****    PUBLIC    ****     ;;

(define-public (create-ticket (owner principal) (ticket-id uint) (amount uint))
  (let
    (
      (stackerId (get-or-create-stacker-id tx-sender))
      (stacker (unwrap! (get-stacker stackerId) (err ERR_STACKER_NOT_FOUND)))
    )

    (map-set Tickets { id: ticket-id } 
      { 
        owner: owner,
        totalMiaLocked: amount,
        lockedCycleLength: u6,
        hasBeenSelected: false,
        endCycle: u12
      }
    )
    ;; add Ticket into StackersTickets (ticketIds)
    (ok true)
  )
)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_NOT_OWNER))
    (ok (var-set contract-owner new-owner))
  )
)

(define-public (transfer-stx (address principal) (amount uint))
  (as-contract (stx-transfer? amount tx-sender (as-contract tx-sender)))
)

;;      ****    READ-ONLY    ****     ;;

(define-read-only (balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-owner (index uint))
  (ok (var-get contract-owner))
)

(define-read-only (get-stacker (id uint))
    (map-get? StackersTickets { id: id })
)

(define-read-only (get-ticket (id uint))
  (map-get? Tickets { id: id })
)

(define-read-only (stx-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (stx-balance-of (address principal))
  (stx-get-balance address)
)

