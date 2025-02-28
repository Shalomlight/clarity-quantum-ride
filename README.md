# QuantumRide
A decentralized ride-sharing application built on the Stacks blockchain using Clarity smart contracts.

## Features
- Register as a driver or passenger
- Create and accept ride requests 
- Process payments via cryptocurrency
- Rating system for drivers and passengers
- Dispute resolution mechanisms

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Register as a driver
(contract-call? .quantum-ride register-driver 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "John Doe" "ABC123")

;; Create a ride request
(contract-call? .quantum-ride create-ride-request 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u100 "Start Location" "End Location")

;; Accept a ride request
(contract-call? .quantum-ride accept-ride 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
