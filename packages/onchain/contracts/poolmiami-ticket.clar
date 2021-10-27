(impl-trait .sip-09-trait.sip-09-trait)

;; Ticket NFT
(define-non-fungible-token poolmiami-ticket uint)

;; constants
(define-constant ERR_NOT_OWNER u101)
(define-constant ERR_NOT_AUTHORIZED u401)

;; contracts

;; variables
(define-data-var contract-owner principal tx-sender)
(define-data-var block-counter uint u0)
(define-data-var block-index uint u0)
(define-data-var cost-per-message uint u25000)
(define-data-var token-uri (string-ascii 256) "")
(define-data-var token-block-uri (string-ascii 256) "")
(define-data-var creator-address principal 'SP3ZMEFW7VH796ZQAH1JMAJT4WC4VPEZZFB6W5CAD)
(define-data-var rotation uint u1)

;; public functions
(define-public (mint)
  (ok true)
)

(define-public (burn (index uint))
  (ok true)
)

(define-public (transfer (index uint) (owner principal) (recipient principal))
  (if (and (is-owner index owner) (is-owner index tx-sender))
    (match (nft-transfer? poolmiami-ticket index owner recipient)
      success (ok true)
      error (err error)
    )
    (err ERR_NOT_AUTHORIZED)
  )
)

(define-read-only (get-last-token-id)
  (ok (var-get block-counter))
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

(define-public (set-token-block-uri (value (string-ascii 256)))
  (if (is-eq tx-sender (var-get contract-owner))
    (ok (var-set token-block-uri value))
    (err ERR_NOT_AUTHORIZED)
  )
)

(define-public (set-creator-address (address principal))
  (if (or
    (is-eq tx-sender (var-get contract-owner))
    (is-eq tx-sender (var-get creator-address))
  )
    (ok (var-set creator-address address))
    (err ERR_NOT_AUTHORIZED)
  )
)

(define-read-only (get-token-uri (id uint))
  (if (not (is-eq id u0))
    (ok (some (var-get token-block-uri)))
    (ok (some (var-get token-uri)))
  )
)

(define-read-only (get-owner (index uint))
  (ok (nft-get-owner? poolmiami-ticket index))
)

(define-read-only (stx-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (stx-balance-of (address principal))
  (stx-get-balance address)
)

;; private functions

(define-private (is-owner (index uint) (user principal))
  (is-eq user (unwrap! (nft-get-owner? poolmiami-ticket index) false))
)

;; initialize
(var-set token-block-uri "ipfs://")
(var-set token-uri "ipfs://")
