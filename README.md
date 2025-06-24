# StayChain 🏨

A decentralized hotel booking platform built on the Stacks blockchain using Clarity smart contracts.

## Overview

StayChain revolutionizes the hospitality industry by creating a trustless, transparent booking system that eliminates intermediaries and reduces fees for both hotels and guests. Built on Bitcoin's security through Stacks blockchain.

## Features

- **Trustless Bookings**: Smart contract-based reservations with automatic escrow
- **Deposit Management**: Secure deposit handling with automatic refunds
- **Hotel Registration**: Decentralized hotel onboarding system  
- **Check-in/Check-out**: Automated payment processing upon completion
- **Cancellation Policy**: Built-in cancellation fees and refund mechanisms
- **Transparent Pricing**: No hidden fees, all costs on-chain

## Smart Contract Functions

### Public Functions

- `register-hotel(name, location, total-rooms)` - Register a new hotel
- `create-booking(hotel-id, room-number, check-in-date, check-out-date, total-amount)` - Create a booking
- `pay-deposit(booking-id, amount)` - Pay booking deposit
- `check-in-guest(booking-id)` - Hotel owner checks in guest
- `check-out-guest(booking-id)` - Complete stay and process payment
- `cancel-booking(booking-id)` - Cancel booking with 50% deposit refund

### Read-Only Functions

- `get-booking(booking-id)` - Retrieve booking details
- `get-hotel(hotel-id)` - Get hotel information
- `get-booking-status(booking-id)` - Check booking status
- `has-active-booking(guest)` - Verify if user has active bookings

## Installation

1. Install Clarinet:
   ```bash
   curl -L https://github.com/hirosystems/clarinet/releases/download/v2.0.0/clarinet-linux-x64.tar.gz | tar xz
   ```

2. Clone the repository:
   ```bash
   git clone <repository-url>
   cd staychain
   ```

3. Check contract syntax:
   ```bash
   clarinet check
   ```

4. Run tests:
   ```bash
   clarinet test
   ```

## Usage Example

```clarity
;; Register a hotel
(contract-call? .staychain register-hotel "Grand Bitcoin Hotel" "New York, NY" u100)

;; Create a booking
(contract-call? .staychain create-booking u1 u201 u20240101 u20240103 u1000000)

;; Pay deposit
(contract-call? .staychain pay-deposit u1 u500000)
```

## Contract Architecture

- **Hotels Map**: Stores hotel registration data
- **Bookings Map**: Manages all booking information
- **Room Availability**: Tracks room status by date
- **Escrow System**: Automatic STX handling for deposits and payments

## Security Features

- Owner-only hotel management functions
- Guest authorization for booking operations
- Deposit escrow with smart contract custody
- Automatic refund mechanisms
- Input validation and error handling

## Booking Lifecycle

1. **Pending** → Guest creates booking
2. **Confirmed** → Guest pays deposit
3. **Checked-in** → Hotel confirms guest arrival
4. **Completed** → Hotel processes checkout and payment
5. **Cancelled** → Guest cancels with partial refund

## Development

This project uses:
- **Stacks Blockchain** for settlement
- **Clarity Smart Contracts** for business logic
- **STX Token** for payments and deposits
- **Clarinet** for testing and development

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make meaningful changes following competition guidelines
4. Submit a pull request with clear description

## License

MIT License - see LICENSE file for details

## Roadmap

- [ ] Multi-token payment support
- [ ] Reputation system for hotels and guests
- [ ] Dynamic pricing based on demand
- [ ] Integration with existing booking platforms
- [ ] Mobile app development