(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-data (err u102))
(define-constant err-glacier-not-found (err u103))
(define-constant err-measurement-not-found (err u104))
(define-constant err-already-exists (err u105))

(define-data-var next-glacier-id uint u1)
(define-data-var next-measurement-id uint u1)

(define-map authorized-sources principal bool)
(define-map glaciers 
    uint 
    {
        name: (string-ascii 100),
        location: (string-ascii 100),
        initial-area: uint,
        initial-thickness: uint,
        created-at: uint,
        created-by: principal,
        active: bool
    }
)

(define-map measurements
    uint
    {
        glacier-id: uint,
        area: uint,
        thickness: uint,
        volume-lost: uint,
        temperature: int,
        recorded-at: uint,
        data-source: (string-ascii 50),
        verified: bool,
        recorded-by: principal
    }
)

(define-map glacier-latest-measurement uint uint)
(define-map source-measurement-count principal uint)

(define-public (authorize-source (source principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set authorized-sources source true))
    )
)

(define-public (revoke-source (source principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-delete authorized-sources source))
    )
)

(define-public (register-glacier (name (string-ascii 100)) (location (string-ascii 100)) (initial-area uint) (initial-thickness uint))
    (let 
        (
            (glacier-id (var-get next-glacier-id))
        )
        (asserts! (> (len name) u0) err-invalid-data)
        (asserts! (> (len location) u0) err-invalid-data)
        (asserts! (> initial-area u0) err-invalid-data)
        (asserts! (> initial-thickness u0) err-invalid-data)
        
        (map-set glaciers glacier-id
            {
                name: name,
                location: location,
                initial-area: initial-area,
                initial-thickness: initial-thickness,
                created-at: stacks-block-height,
                created-by: tx-sender,
                active: true
            }
        )
        (var-set next-glacier-id (+ glacier-id u1))
        (ok glacier-id)
    )
)

(define-public (deactivate-glacier (glacier-id uint))
    (let
        (
            (glacier-data (unwrap! (map-get? glaciers glacier-id) err-glacier-not-found))
        )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get created-by glacier-data))) err-not-authorized)
        (map-set glaciers glacier-id (merge glacier-data { active: false }))
        (ok true)
    )
)

(define-public (record-measurement 
    (glacier-id uint) 
    (area uint) 
    (thickness uint) 
    (volume-lost uint) 
    (temperature int)
    (data-source (string-ascii 50))
)
    (let
        (
            (measurement-id (var-get next-measurement-id))
            (glacier-data (unwrap! (map-get? glaciers glacier-id) err-glacier-not-found))
            (current-count (default-to u0 (map-get? source-measurement-count tx-sender)))
        )
        (asserts! (default-to false (map-get? authorized-sources tx-sender)) err-not-authorized)
        (asserts! (get active glacier-data) err-invalid-data)
        (asserts! (> area u0) err-invalid-data)
        (asserts! (> thickness u0) err-invalid-data)
        (asserts! (> (len data-source) u0) err-invalid-data)
        
        (map-set measurements measurement-id
            {
                glacier-id: glacier-id,
                area: area,
                thickness: thickness,
                volume-lost: volume-lost,
                temperature: temperature,
                recorded-at: stacks-block-height,
                data-source: data-source,
                verified: false,
                recorded-by: tx-sender
            }
        )
        (map-set glacier-latest-measurement glacier-id measurement-id)
        (map-set source-measurement-count tx-sender (+ current-count u1))
        (var-set next-measurement-id (+ measurement-id u1))
        (ok measurement-id)
    )
)

(define-public (verify-measurement (measurement-id uint))
    (let
        (
            (measurement-data (unwrap! (map-get? measurements measurement-id) err-measurement-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set measurements measurement-id (merge measurement-data { verified: true }))
        (ok true)
    )
)

(define-public (batch-verify-measurements (measurement-ids (list 20 uint)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map verify-single-measurement measurement-ids))
    )
)

(define-private (verify-single-measurement (measurement-id uint))
    (match (map-get? measurements measurement-id)
        measurement-data (map-set measurements measurement-id (merge measurement-data { verified: true }))
        false
    )
)

(define-read-only (get-glacier (glacier-id uint))
    (map-get? glaciers glacier-id)
)

(define-read-only (get-measurement (measurement-id uint))
    (map-get? measurements measurement-id)
)

(define-read-only (get-latest-measurement (glacier-id uint))
    (match (map-get? glacier-latest-measurement glacier-id)
        latest-id (map-get? measurements latest-id)
        none
    )
)

(define-read-only (is-authorized-source (source principal))
    (default-to false (map-get? authorized-sources source))
)

(define-read-only (get-source-measurement-count (source principal))
    (default-to u0 (map-get? source-measurement-count source))
)

(define-read-only (get-contract-stats)
    (ok 
        {
            total-glaciers: (- (var-get next-glacier-id) u1),
            total-measurements: (- (var-get next-measurement-id) u1),
            contract-owner: contract-owner
        }
    )
)

(define-read-only (calculate-melt-rate (glacier-id uint))
    (let
        (
            (glacier-data (unwrap! (map-get? glaciers glacier-id) err-glacier-not-found))
            (latest-measurement-id (unwrap! (map-get? glacier-latest-measurement glacier-id) err-measurement-not-found))
            (latest-measurement (unwrap! (map-get? measurements latest-measurement-id) err-measurement-not-found))
        )
        (let
            (
                (initial-volume (* (get initial-area glacier-data) (get initial-thickness glacier-data)))
                (current-volume (* (get area latest-measurement) (get thickness latest-measurement)))
                (volume-change (if (>= initial-volume current-volume) (- initial-volume current-volume) u0))
                (time-span (- (get recorded-at latest-measurement) (get created-at glacier-data)))
            )
            (ok
                {
                    glacier-id: glacier-id,
                    initial-volume: initial-volume,
                    current-volume: current-volume,
                    volume-lost: volume-change,
                    time-span: time-span,
                    melt-rate: (if (> time-span u0) (/ volume-change time-span) u0)
                }
            )
        )
    )
)

(define-read-only (get-glacier-history (glacier-id uint) (limit uint))
    (let
        (
            (glacier-exists (is-some (map-get? glaciers glacier-id)))
        )
        (asserts! glacier-exists err-glacier-not-found)
        (ok glacier-id)
    )
)

(define-public (update-glacier (glacier-id uint) (new-name (string-ascii 100)) (new-location (string-ascii 100)))
    (let
        (
            (glacier-data (unwrap! (map-get? glaciers glacier-id) err-glacier-not-found))
        )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get created-by glacier-data))) err-not-authorized)
        (asserts! (get active glacier-data) err-invalid-data)
        (asserts! (> (len new-name) u0) err-invalid-data)
        (asserts! (> (len new-location) u0) err-invalid-data)
        (map-set glaciers glacier-id (merge glacier-data { name: new-name, location: new-location }))
        (ok true)
    )
)

(define-public (emergency-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok true)
    )
)

(define-read-only (get-measurement-by-glacier-and-time (glacier-id uint) (start-block uint) (end-block uint))
    (ok
        {
            glacier-id: glacier-id,
            start-block: start-block,
            end-block: end-block,
            query-processed: true
        }
    )
)

(define-private (is-active-id (id uint))
    (match (map-get? glaciers id)
        some-data (and (< id (var-get next-glacier-id)) (get active some-data))
        false
    )
)

(define-read-only (get-active-glacier-ids)
    (filter is-active-id (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31 u32 u33 u34 u35 u36 u37 u38 u39 u40 u41 u42 u43 u44 u45 u46 u47 u48 u49 u50 u51 u52 u53 u54 u55 u56 u57 u58 u59 u60 u61 u62 u63 u64 u65 u66 u67 u68 u69 u70 u71 u72 u73 u74 u75 u76 u77 u78 u79 u80 u81 u82 u83 u84 u85 u86 u87 u88 u89 u90 u91 u92 u93 u94 u95 u96 u97 u98 u99 u100))
)

(begin
    (map-set authorized-sources contract-owner true)
    (print "Glacial Melt Monitoring Ledger initialized")
)
