;; StayChain - Decentralized Hotel Booking Smart Contract
;; A trustless hotel booking system on Stacks blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-booking-exists (err u104))
(define-constant err-already-checked-in (err u105))
(define-constant err-not-checked-in (err u106))
(define-constant err-invalid-input (err u107))
(define-constant max-string-length u100)
(define-constant max-location-length u200)
(define-constant max-rooms u1000)

;; Data Variables
(define-data-var next-booking-id uint u1)

;; Data Maps
(define-map bookings
    { booking-id: uint }
    {
        guest: principal,
        hotel-owner: principal,
        room-number: uint,
        check-in-date: uint,
        check-out-date: uint,
        total-amount: uint,
        deposit-paid: uint,
        status: (string-ascii 20),
        created-at: uint
    }
)

(define-map hotels
    { hotel-id: uint }
    {
        owner: principal,
        name: (string-ascii 100),
        location: (string-ascii 200),
        total-rooms: uint,
        active: bool
    }
)

(define-map room-availability
    { hotel-id: uint, room-number: uint, date: uint }
    { available: bool }
)

;; Private Functions
(define-private (is-hotel-owner (hotel-id uint) (caller principal))
    (match (map-get? hotels { hotel-id: hotel-id })
        hotel-data (is-eq (get owner hotel-data) caller)
        false
    )
)

(define-private (is-valid-string (str (string-ascii 100)))
    (and (> (len str) u0) (<= (len str) max-string-length))
)

(define-private (is-valid-location (str (string-ascii 200)))
    (and (> (len str) u0) (<= (len str) max-location-length))
)

(define-private (is-valid-booking-id (booking-id uint))
    (and (> booking-id u0) (< booking-id (var-get next-booking-id)))
)

;; Public Functions

;; Register a new hotel
(define-public (register-hotel (name (string-ascii 100)) (location (string-ascii 200)) (total-rooms uint))
    (let ((hotel-id (var-get next-booking-id)))
        (asserts! (is-valid-string name) err-invalid-input)
        (asserts! (is-valid-location location) err-invalid-input)
        (asserts! (and (> total-rooms u0) (<= total-rooms max-rooms)) err-invalid-input)
        
        (map-set hotels
            { hotel-id: hotel-id }
            {
                owner: tx-sender,
                name: name,
                location: location,
                total-rooms: total-rooms,
                active: true
            }
        )
        (var-set next-booking-id (+ hotel-id u1))
        (ok hotel-id)
    )
)

;; Create a new booking
(define-public (create-booking 
    (hotel-id uint) 
    (room-number uint) 
    (check-in-date uint) 
    (check-out-date uint) 
    (total-amount uint))
    (let (
        (booking-id (var-get next-booking-id))
        (hotel-data (unwrap! (map-get? hotels { hotel-id: hotel-id }) err-not-found))
    )
        (asserts! (> hotel-id u0) err-invalid-input)
        (asserts! (> room-number u0) err-invalid-input)
        (asserts! (> check-in-date u0) err-invalid-input)
        (asserts! (> check-out-date check-in-date) err-invalid-input)
        (asserts! (> total-amount u0) err-invalid-amount)
        (asserts! (get active hotel-data) err-not-found)
        (asserts! (<= room-number (get total-rooms hotel-data)) err-invalid-input)
        
        ;; Create the booking
        (map-set bookings
            { booking-id: booking-id }
            {
                guest: tx-sender,
                hotel-owner: (get owner hotel-data),
                room-number: room-number,
                check-in-date: check-in-date,
                check-out-date: check-out-date,
                total-amount: total-amount,
                deposit-paid: u0,
                status: "pending",
                created-at: stacks-block-height
            }
        )
        
        (var-set next-booking-id (+ booking-id u1))
        (ok booking-id)
    )
)

;; Pay deposit for booking
(define-public (pay-deposit (booking-id uint) (amount uint))
    (let (
        (booking-data (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
    )
        (asserts! (is-valid-booking-id booking-id) err-invalid-input)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-eq tx-sender (get guest booking-data)) err-unauthorized)
        (asserts! (is-eq (get status booking-data) "pending") err-unauthorized)
        
        ;; Transfer STX as deposit
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update booking with deposit
        (map-set bookings
            { booking-id: booking-id }
            (merge booking-data {
                deposit-paid: amount,
                status: "confirmed"
            })
        )
        (ok true)
    )
)

;; Check-in guest
(define-public (check-in-guest (booking-id uint))
    (let (
        (booking-data (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
    )
        (asserts! (is-valid-booking-id booking-id) err-invalid-input)
        (asserts! (is-eq tx-sender (get hotel-owner booking-data)) err-unauthorized)
        (asserts! (is-eq (get status booking-data) "confirmed") err-unauthorized)
        
        (map-set bookings
            { booking-id: booking-id }
            (merge booking-data { status: "checked-in" })
        )
        (ok true)
    )
)

;; Check-out guest and process payment
(define-public (check-out-guest (booking-id uint))
    (let (
        (booking-data (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
        (remaining-amount (- (get total-amount booking-data) (get deposit-paid booking-data)))
    )
        (asserts! (is-valid-booking-id booking-id) err-invalid-input)
        (asserts! (is-eq tx-sender (get hotel-owner booking-data)) err-unauthorized)
        (asserts! (is-eq (get status booking-data) "checked-in") err-not-checked-in)
        
        ;; Transfer remaining payment to hotel owner
        (if (> remaining-amount u0)
            (try! (as-contract (stx-transfer? remaining-amount tx-sender (get hotel-owner booking-data))))
            true
        )
        
        ;; Transfer deposit to hotel owner
        (try! (as-contract (stx-transfer? (get deposit-paid booking-data) tx-sender (get hotel-owner booking-data))))
        
        (map-set bookings
            { booking-id: booking-id }
            (merge booking-data { status: "completed" })
        )
        (ok true)
    )
)

;; Cancel booking (guest can cancel before check-in)
(define-public (cancel-booking (booking-id uint))
    (let (
        (booking-data (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
    )
        (asserts! (is-valid-booking-id booking-id) err-invalid-input)
        (asserts! (is-eq tx-sender (get guest booking-data)) err-unauthorized)
        (asserts! (is-eq (get status booking-data) "confirmed") err-unauthorized)
        
        ;; Refund 50% of deposit (hotel keeps 50% as cancellation fee)
        (let ((refund-amount (/ (get deposit-paid booking-data) u2)))
            (if (> refund-amount u0)
                (try! (as-contract (stx-transfer? refund-amount tx-sender (get guest booking-data))))
                true
            )
        )
        
        (map-set bookings
            { booking-id: booking-id }
            (merge booking-data { status: "cancelled" })
        )
        (ok true)
    )
)

;; Read-only functions

;; Get booking details
(define-read-only (get-booking (booking-id uint))
    (if (is-valid-booking-id booking-id)
        (map-get? bookings { booking-id: booking-id })
        none
    )
)

;; Get hotel details
(define-read-only (get-hotel (hotel-id uint))
    (if (> hotel-id u0)
        (map-get? hotels { hotel-id: hotel-id })
        none
    )
)

;; Get booking status
(define-read-only (get-booking-status (booking-id uint))
    (if (is-valid-booking-id booking-id)
        (match (map-get? bookings { booking-id: booking-id })
            booking-data (ok (get status booking-data))
            err-not-found
        )
        err-invalid-input
    )
)

;; Check if user has active booking
(define-read-only (has-active-booking (guest principal))
    (let ((current-booking-id (var-get next-booking-id)))
        (fold check-user-bookings (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) false)
    )
)

(define-private (check-user-bookings (booking-id uint) (has-booking bool))
    (if has-booking
        true
        (match (map-get? bookings { booking-id: booking-id })
            booking-data 
                (and 
                    (is-eq (get guest booking-data) tx-sender)
                    (or (is-eq (get status booking-data) "confirmed")
                        (is-eq (get status booking-data) "checked-in"))
                )
            false
        )
    )
)