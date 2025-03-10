;; Stellar Energy Harvesting Contract
;; Manages the harvesting of energy from stellar sources

(define-data-var admin principal tx-sender)

;; Data structure for stellar energy sources
(define-map stellar-sources
  { source-id: uint }
  {
    source-name: (string-ascii 100),
    harvester: principal,
    coordinates: (list 3 int),
    energy-type: (string-ascii 30),
    output-capacity: uint,
    current-output: uint,
    last-harvested: uint,
    status: (string-ascii 20)
  }
)

;; Harvesting records
(define-map harvesting-records
  { record-id: uint }
  {
    source-id: uint,
    harvester: principal,
    energy-amount: uint,
    timestamp: uint
  }
)

;; Counter for source IDs
(define-data-var next-source-id uint u1)
;; Counter for record IDs
(define-data-var next-record-id uint u1)

;; Register a new stellar energy source
(define-public (register-source
  (source-name (string-ascii 100))
  (coordinates (list 3 int))
  (energy-type (string-ascii 30))
  (output-capacity uint))
  (let ((source-id (var-get next-source-id)))
    (map-set stellar-sources
      { source-id: source-id }
      {
        source-name: source-name,
        harvester: tx-sender,
        coordinates: coordinates,
        energy-type: energy-type,
        output-capacity: output-capacity,
        current-output: u0,
        last-harvested: block-height,
        status: "active"
      }
    )
    (var-set next-source-id (+ source-id u1))
    (ok source-id)
  )
)

;; Harvest energy from a source
(define-public (harvest-energy (source-id uint) (energy-amount uint))
  (let (
    (source (default-to
      {
        source-name: "",
        harvester: tx-sender,
        coordinates: (list 0 0 0),
        energy-type: "",
        output-capacity: u0,
        current-output: u0,
        last-harvested: u0,
        status: ""
      }
      (map-get? stellar-sources { source-id: source-id })))
    (record-id (var-get next-record-id))
    (new-output (+ (get current-output source) energy-amount))
    )

    ;; Record harvesting
    (map-set harvesting-records
      { record-id: record-id }
      {
        source-id: source-id,
        harvester: tx-sender,
        energy-amount: energy-amount,
        timestamp: block-height
      }
    )

    ;; Update source
    (map-set stellar-sources
      { source-id: source-id }
      (merge source {
        current-output: new-output,
        last-harvested: block-height
      })
    )

    (var-set next-record-id (+ record-id u1))
    (ok energy-amount)
  )
)

;; Deactivate a source
(define-public (deactivate-source (source-id uint))
  (let (
    (source (default-to
      {
        source-name: "",
        harvester: tx-sender,
        coordinates: (list 0 0 0),
        energy-type: "",
        output-capacity: u0,
        current-output: u0,
        last-harvested: u0,
        status: ""
      }
      (map-get? stellar-sources { source-id: source-id })))
    )
    (map-set stellar-sources
      { source-id: source-id }
      (merge source { status: "inactive" })
    )
    (ok true)
  )
)

;; Get source details
(define-read-only (get-source (source-id uint))
  (map-get? stellar-sources { source-id: source-id })
)

;; Get harvesting record
(define-read-only (get-harvesting-record (record-id uint))
  (map-get? harvesting-records { record-id: record-id })
)

