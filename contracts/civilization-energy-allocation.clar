;; Civilization Energy Allocation Contract
;; Manages the allocation of energy to different civilizations

(define-data-var admin principal tx-sender)

;; Data structure for civilizations
(define-map civilizations
  { civilization-id: uint }
  {
    civilization-name: (string-ascii 100),
    representative: principal,
    location: (list 3 int),
    technological-level: uint,
    energy-quota: uint,
    energy-consumed: uint,
    last-allocation: uint,
    status: (string-ascii 20)
  }
)

;; Allocation records
(define-map allocation-records
  { record-id: uint }
  {
    civilization-id: uint,
    energy-amount: uint,
    allocation-reason: (string-ascii 100),
    timestamp: uint,
    allocator: principal
  }
)

;; Counter for civilization IDs
(define-data-var next-civilization-id uint u1)
;; Counter for record IDs
(define-data-var next-record-id uint u1)

;; Register a new civilization
(define-public (register-civilization
  (civilization-name (string-ascii 100))
  (location (list 3 int))
  (technological-level uint))
  (let ((civilization-id (var-get next-civilization-id)))
    (map-set civilizations
      { civilization-id: civilization-id }
      {
        civilization-name: civilization-name,
        representative: tx-sender,
        location: location,
        technological-level: technological-level,
        energy-quota: (* technological-level u1000),
        energy-consumed: u0,
        last-allocation: block-height,
        status: "active"
      }
    )
    (var-set next-civilization-id (+ civilization-id u1))
    (ok civilization-id)
  )
)

;; Allocate energy to a civilization
(define-public (allocate-energy
  (civilization-id uint)
  (energy-amount uint)
  (allocation-reason (string-ascii 100)))
  (let (
    (civilization (default-to
      {
        civilization-name: "",
        representative: tx-sender,
        location: (list 0 0 0),
        technological-level: u0,
        energy-quota: u0,
        energy-consumed: u0,
        last-allocation: u0,
        status: ""
      }
      (map-get? civilizations { civilization-id: civilization-id })))
    (record-id (var-get next-record-id))
    (new-consumed (+ (get energy-consumed civilization) energy-amount))
    )

    ;; Record allocation
    (map-set allocation-records
      { record-id: record-id }
      {
        civilization-id: civilization-id,
        energy-amount: energy-amount,
        allocation-reason: allocation-reason,
        timestamp: block-height,
        allocator: tx-sender
      }
    )

    ;; Update civilization
    (map-set civilizations
      { civilization-id: civilization-id }
      (merge civilization {
        energy-consumed: new-consumed,
        last-allocation: block-height
      })
    )

    (var-set next-record-id (+ record-id u1))
    (ok energy-amount)
  )
)

;; Update civilization technological level
(define-public (update-tech-level (civilization-id uint) (new-tech-level uint))
  (let (
    (civilization (default-to
      {
        civilization-name: "",
        representative: tx-sender,
        location: (list 0 0 0),
        technological-level: u0,
        energy-quota: u0,
        energy-consumed: u0,
        last-allocation: u0,
        status: ""
      }
      (map-get? civilizations { civilization-id: civilization-id })))
    (new-quota (* new-tech-level u1000))
    )

    ;; Update civilization
    (map-set civilizations
      { civilization-id: civilization-id }
      (merge civilization {
        technological-level: new-tech-level,
        energy-quota: new-quota
      })
    )

    (ok new-quota)
  )
)

;; Get civilization details
(define-read-only (get-civilization (civilization-id uint))
  (map-get? civilizations { civilization-id: civilization-id })
)

;; Get allocation record
(define-read-only (get-allocation-record (record-id uint))
  (map-get? allocation-records { record-id: record-id })
)

