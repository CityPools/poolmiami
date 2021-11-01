(impl-trait .sip-09-trait.sip-09-trait)

;; Ticket NFT
(define-non-fungible-token PoolMiami-Ticket uint)

;; Storage
(define-map token-count principal uint)
(define-map RecentMints { owner: principal }
    { lastMinted: uint }
)

;; constants
(define-constant IPFS_ROOT "ipfs://xyz/")
(define-constant ERR_NOT_OWNER u101)
(define-constant ERR_NOT_AUTHORIZED u401)

;; contracts

;; variables
(define-data-var last-id uint u0)

(define-data-var contract-owner principal tx-sender)
(define-data-var creator-address principal tx-sender)

;; public functions
(define-public (mint-ticket (minter principal) (amount uint))
  (let 
    (
      (next-id (+ u1 (var-get last-id)))
      (current-balance (get-balance minter))
    )
    (try! (nft-mint? PoolMiami-Ticket next-id minter))
    (var-set last-id next-id)
    (map-set token-count minter (+ current-balance u1))
    ;; TODO: create ability to call back into citypools-miami contract by using a trait
    ;; (try! (contract-call? .citypools-miami create-ticket next-id amount))
    (print {msg: "ticket-minted", id: next-id})
    (ok next-id)
  )
)

(define-public (burn (token-id uint) (minter principal))
  (let
    (
      (current-balance (get-balance minter))
    )
    (if (is-sender-owner token-id)
      (begin
        (try! (nft-burn? PoolMiami-Ticket token-id minter))
        (map-set token-count minter (- current-balance u1))
        (print {msg: "ticket-burned", id: token-id})
        (ok true)
      )
      (err ERR_NOT_AUTHORIZED)
    )
  )
)

(define-public (transfer (token-id uint) (from principal) (to principal))
  (if (is-eq tx-sender to)
    (match (nft-transfer? PoolMiami-Ticket token-id from to)
        success (ok success)
        error (err error)
    )
    (err u500)
  )
)

(define-read-only (get-last-token-id)
  (ok (var-get last-id))
)

(define-read-only (get-last-minted-by-owner (owner principal))
  (default-to u0 (get lastMinted (map-get? RecentMints { owner: owner })))
)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (as-max-len? (concat (concat IPFS_ROOT (concat "poolmiami_ticket_" (uint-to-string token-id))) ".json") u256))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? PoolMiami-Ticket token-id))
)

(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? token-count account))
)

(define-read-only (get-balance-of (address principal))
  (stx-get-balance address)
)

;; private functions

(define-private (is-sender-owner (token-id uint))
  (let 
    (
      (owner (unwrap! (nft-get-owner? PoolMiami-Ticket token-id) false))
    )
    (or (is-eq tx-sender owner) (is-eq contract-caller owner))
  )
)

(define-constant FOLDS_TWO (list true true))

(define-constant NUM_TO_CHAR (list "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"))

(define-private (concat-uint (ignore bool) (input { dec: uint, data: (string-ascii 3) }))
  (let 
    (
      (last-val (get dec input))
    )
    (if (is-eq last-val u0)
      {
          dec: last-val,
          data: (get data input)
      }
      (if (< last-val u10)
        {
            dec: u0,
            data: (concat-num-to-string last-val (get data input))
        }
        {
            dec: (/ last-val u10),
            data: (concat-num-to-string (mod last-val u10) (get data input))
        }
      )
    )
  )
)

(define-private (concat-num-to-string (num uint) (right (string-ascii 3)))
    (unwrap-panic (as-max-len? (concat (unwrap-panic (element-at NUM_TO_CHAR num)) right) u3))
)

(define-private (uint-to-string (num uint))
  (if (is-eq num u0)
      (unwrap-panic (as-max-len? "0" u3))
      (get data (fold concat-uint FOLDS_TWO { dec: num, data: ""}))
  )
)
