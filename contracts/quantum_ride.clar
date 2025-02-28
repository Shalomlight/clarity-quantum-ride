;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-state (err u101))
(define-constant err-not-found (err u102))

;; Data variables
(define-map drivers 
  principal 
  { name: (string-ascii 50), license: (string-ascii 20), rating: uint, total-rides: uint }
)

(define-map passengers
  principal
  { name: (string-ascii 50), rating: uint, total-rides: uint }
)

(define-map ride-requests
  uint 
  {
    passenger: principal,
    driver: (optional principal),
    pickup: (string-ascii 100),
    destination: (string-ascii 100),
    fare: uint,
    status: (string-ascii 20)
  }
)

(define-data-var ride-counter uint u0)

;; Public functions
(define-public (register-driver (driver principal) (name (string-ascii 50)) (license (string-ascii 20)))
  (if (is-none (map-get? drivers driver))
    (ok (map-set drivers driver { 
      name: name, 
      license: license,
      rating: u0,
      total-rides: u0
    }))
    err-unauthorized
  )
)

(define-public (create-ride-request 
  (passenger principal) 
  (fare uint)
  (pickup (string-ascii 100))
  (destination (string-ascii 100))
)
  (let ((request-id (var-get ride-counter)))
    (map-set ride-requests request-id {
      passenger: passenger,
      driver: none,
      pickup: pickup,
      destination: destination,
      fare: fare,
      status: "PENDING"
    })
    (var-set ride-counter (+ request-id u1))
    (ok request-id)
  )
)

(define-public (accept-ride (driver principal) (request-id uint))
  (let ((request (unwrap! (map-get? ride-requests request-id) err-not-found)))
    (if (and 
      (is-some (map-get? drivers driver))
      (is-eq (get status request) "PENDING")
    )
      (ok (map-set ride-requests request-id 
        (merge request { 
          driver: (some driver),
          status: "ACCEPTED"
        })
      ))
      err-invalid-state
    )
  )
)

(define-public (complete-ride (request-id uint))
  (let (
    (request (unwrap! (map-get? ride-requests request-id) err-not-found))
    (driver (unwrap! (get driver request) err-invalid-state))
  )
    (if (is-eq (get status request) "ACCEPTED")
      (ok (map-set ride-requests request-id 
        (merge request { status: "COMPLETED" })
      ))
      err-invalid-state
    )
  )
)

;; Read only functions
(define-read-only (get-driver-info (driver principal))
  (ok (map-get? drivers driver))
)

(define-read-only (get-ride-request (request-id uint))
  (ok (map-get? ride-requests request-id))
)
