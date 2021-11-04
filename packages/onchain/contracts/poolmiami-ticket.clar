(impl-trait .sip-09-trait.sip-09-trait)

;; PoolMiami Ticket NFT
(define-non-fungible-token PoolMiami-Ticket uint)

;; CONSTANTS
(define-constant contract-owner tx-sender)

;; Define erros
(define-constant err-not-owner (err u101))
(define-constant err-not-authorized (err u401))
(define-constant err-failed-to-transfer (err u11))
(define-constant err-metadata-frozen (err u13))
(define-constant err-mint-address-already-set (err u14))

;; Utils
(define-constant FOLDS_TWO (list true true))
(define-constant NUM_TO_CHAR (list "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"))

;; VARIABLES

;; Store the root token uri used to query metadata
(define-data-var base-token-uri (string-ascii 210) "ipfs://")

;; Store the last issues token ID
(define-data-var last-id uint u0)

;; Used to determine if metadata is frozen
(define-data-var metadata-frozen bool false)

;; Store the mint address allowed to trigger minting
(define-map mint-address bool {contract-id: principal})

;; Store the price of each mint
(define-data-var mint-price uint u100000000)

;; STORAGE

;; Track the amount of minted Tickets for a specified principal
(define-map token-count principal uint)

;; PUBLIC FUNCTIONS

;; Mint a PoolMiami Ticket and stack $MIA with CityCoins
(define-public (mint-ticket (minter principal) (amount uint))
  (let 
    (
      (next-id (+ u1 (var-get last-id)))
      (current-balance (get-balance minter))
    )
    (asserts! true err-not-owner)
    (unwrap! (stx-transfer? (var-get mint-price) tx-sender contract-owner) err-failed-to-transfer)
    (try! (nft-mint? PoolMiami-Ticket next-id minter))
    (var-set last-id next-id)
    (map-set token-count minter (+ current-balance u1))
    (print {msg: "ticket-minted", id: next-id})
    (ok next-id)
  )
)

;; SIP009: Transfer token to a specified principal
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-owner)
    (match (nft-transfer? PoolMiami-Ticket token-id sender recipient)
      success (ok success)
      error (err error)
    )
  )
)

;; Allow the contract owner to change the mint price
(define-public (set-mint-price (new-mint-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (ok (var-set mint-price new-mint-price))
  )
)

;; Allow the contract owner to change the base token uri
(define-public (set-base-token-uri (new-base-token-uri (string-ascii 210)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (asserts! (not (var-get metadata-frozen)) err-metadata-frozen)
    (ok (var-set base-token-uri new-base-token-uri))
  )
)

;; Freeze metadata, once metadata is frozen, it can't be changed later on
(define-public (freeze-metadata)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (ok (var-set metadata-frozen true))
  )
)

;; SIP009: Burn token for a specified token-id
;; TODO: Check if Ticket for token-id is burnable
;; TODO: Decrement token-count for a specified principal
;; TODO: Transfer amountStacked ($MIA) in Ticket to tx-sender
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
      err-not-authorized
    )
  )
)

;; READ-ONLY FUNCTIONS

(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? token-count account))
)

(define-read-only (get-contract-caller)
  (ok contract-caller)
)

(define-read-only (get-last-token-id)
  (ok (var-get last-id))
)

(define-read-only (get-mint-address)
  (ok (get contract-id (map-get? mint-address true)))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (as-max-len? (concat (concat (var-get base-token-uri) (concat "poolmiami_ticket_" (uint-to-string token-id))) ".json") u256))
)

;; SIP009: Get the owner of the specified token ID
(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? PoolMiami-Ticket token-id))
)

;; PRIVATE FUNCTIONS

;; Manage the Mint
(define-private (called-from-minter)
  (let 
    (
      (the-mint (unwrap! (get contract-id (map-get? mint-address true)) false))
    )
    (is-eq contract-caller the-mint)
  )
)

;; Can only be called once
(define-public (set-mint-address)
  (let 
    (
      (the-mint (map-get? mint-address true))
    )
    (asserts! (and (is-none the-mint) (map-insert mint-address true {contract-id: tx-sender})) err-mint-address-already-set)
    (ok tx-sender)
  )
)

(define-private (is-sender-owner (token-id uint))
  (let 
    (
      (owner (unwrap! (nft-get-owner? PoolMiami-Ticket token-id) false))
    )
    (or (is-eq tx-sender owner) (is-eq contract-caller owner))
  )
)

;; START - Utils to convert uint to string

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

;; END - Utils to convert uint to string
