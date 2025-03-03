;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-state (err u101))
(define-constant err-not-found (err u102))
(define-constant err-already-registered (err u103))

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
(define-public (register-passenger (passenger principal) (name (string-ascii 50)))
  (if (is-none (map-get? passengers passenger))
    (ok (map-set passengers passenger { 
      name: name, 
      rating: u0,
      total-rides: u0
    }))
    err-already-registered
  )
)

(define-public (register-driver (driver principal) (name (string-ascii 50)) (license (string-ascii 20)))
  (if (is-none (map-get? drivers driver))
    (ok (map-set drivers driver { 
      name: name, 
      license: license,
      rating: u0,
      total-rides: u0
    }))
    err-already-registered
  )
)

(define-public (create-ride-request 
  (passenger principal) 
  (fare uint)
  (pickup (string-ascii 100))
  (destination (string-ascii 100))
)
  (let ((request-id (var-get ride-counter)))
    (asserts! (is-some (map-get? passengers passenger)) err-unauthorized)
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
    (asserts! (is-some (map-get? drivers driver)) err-unauthorized)
    (asserts! (is-eq (get status request) "PENDING") err-invalid-state)
    (ok (map-set ride-requests request-id 
      (merge request { 
        driver: (some driver),
        status: "ACCEPTED"
      })
    ))
  )
)

(define-public (complete-ride (request-id uint))
  (let (
    (request (unwrap! (map-get? ride-requests request-id) err-not-found))
    (driver (unwrap! (get driver request) err-invalid-state))
  )
    (asserts! (is-eq tx-sender driver) err-unauthorized)
    (asserts! (is-eq (get status request) "ACCEPTED") err-invalid-state)
    
    ;; Update ride counts
    (match (map-get? drivers driver)
      driver-data (map-set drivers driver 
        (merge driver-data { total-rides: (+ (get total-rides driver-data) u1) }))
      true
    )
    (match (map-get? passengers (get passenger request))
      passenger-data (map-set passengers (get passenger request)
        (merge passenger-data { total-rides: (+ (get total-rides passenger-data) u1) }))
      true
    )
    
    (ok (map-set ride-requests request-id 
      (merge request { status: "COMPLETED" })
    ))
  )
)

;; Read only functions
(define-read-only (get-driver-info (driver principal))
  (ok (map-get? drivers driver))
)

(define-read-only (get-passenger-info (passenger principal))
  (ok (map-get? passengers passenger))
)

(define-read-only (get-ride-request (request-id uint))
  (ok (map-get? ride-requests request-id))
)
