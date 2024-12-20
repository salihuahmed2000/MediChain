;; Simple Health Records Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Define data variables
(define-data-var record-id-nonce uint u0)

;; Define data maps
(define-map health-records
  uint
  {
    patient: principal,
    data: (string-utf8 500),
    authorized: (list 5 principal)
  }
)

;; Add a new health record
(define-public (add-health-record (data (string-utf8 500)))
  (let
    (
      (new-id (+ (var-get record-id-nonce) u1))
    )
    (var-set record-id-nonce new-id)
    (ok (map-set health-records new-id
      {
        patient: tx-sender,
        data: data,
        authorized: (list tx-sender)
      }
    ))
  )
)

;; Grant access to a health record
(define-public (grant-access (record-id uint) (user principal))
  (let
    (
      (record (unwrap! (map-get? health-records record-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get patient record)) err-unauthorized)
    (ok (map-set health-records record-id
      (merge record
        { authorized: (unwrap! (as-max-len? (append (get authorized record) user) u5) err-unauthorized) }
      )
    ))
  )
)

;; Get a health record
(define-read-only (get-health-record (record-id uint))
  (let
    (
      (record (unwrap! (map-get? health-records record-id) err-not-found))
    )
    (asserts! (is-some (index-of (get authorized record) tx-sender)) err-unauthorized)
    (ok record)
  )
)

