(define-trait sip-09-trait
  (
      ;; Return the last token id
      (get-last-token-id () (response uint uint)) 
     
      ;; Return the URI representing the metadata associated to the NFT
      (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
     
      ;; Return the owner of the given token id
      (get-owner (uint) (response (optional principal) uint))
     
      ;; Transfer given token id from the sender to a new principal
      (transfer (uint principal principal) (response bool uint))
  )  
)