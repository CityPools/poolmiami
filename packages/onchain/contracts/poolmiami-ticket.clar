(impl-trait .sip-09-trait.sip-09-trait)

;; Ticket NFT
(define-non-fungible-token poolmiami-ticket uint)

;; Storage
(define-map token-count principal uint)

;; constants
(define-constant IPFS_ROOT "ipfs://xyz/")
(define-constant ERR_NOT_OWNER u101)
(define-constant ERR_NOT_AUTHORIZED u401)

;; contracts

;; variables
(define-data-var last-id uint u0)
(define-data-var last-block uint block-height)
(define-data-var last-vrf (buff 64) 0x00)

(define-data-var contract-owner principal tx-sender)
(define-data-var token-uri (string-ascii 256) "")
(define-data-var creator-address principal tx-sender)
(define-data-var rotation uint u1)

;; public functions
(define-public (mint)
  (let 
    (
      (next-id (+ u1 (var-get last-id)))
      (current-balance (get-balance tx-sender))
    )
    (try! (nft-mint? poolmiami-ticket next-id tx-sender))
    (var-set last-id next-id)
    (map-set token-count tx-sender (+ current-balance u1))
    (print (var-get last-id))
    (ok true)
  )
)

(define-public (burn (token-id uint))
  (let
    (
      (current-balance (get-balance tx-sender))
    )
    (if (is-sender-owner token-id)
      (begin
        (try! (nft-burn? poolmiami-ticket token-id tx-sender))
        (map-set token-count tx-sender (- current-balance u1))
        (ok true)
      )
      (err ERR_NOT_AUTHORIZED)
    )
  )
)

(define-public (transfer (token-id uint) (from principal) (to principal))
  (if (is-eq tx-sender to)
    (match (nft-transfer? poolmiami-ticket token-id from to)
        success (ok success)
        error (err error)
    )
    (err u500)
  )
)

(define-read-only (get-last-token-id)
  (ok (var-get last-id))
)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-token-uri (value (string-ascii 256)))
  (if (is-eq tx-sender (var-get contract-owner))
    (ok (var-set token-uri value))
    (err ERR_NOT_AUTHORIZED)
  )
)

(define-read-only (get-token-uri (token-id uint))
  (ok (as-max-len? (concat (concat IPFS_ROOT (concat "poolmiami_ticket_" (uint-to-string token-id))) ".json") u256))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? poolmiami-ticket token-id))
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
      (owner (unwrap! (nft-get-owner? poolmiami-ticket token-id) false))
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

;; initialize
(var-set token-uri "ipfs://")
