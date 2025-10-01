# 🚨 Relief - Supply Chain for Disaster Relief 📦

## 🌟 Overview

Relief is a blockchain-based supply chain tracking system built on Stacks that ensures complete transparency and accountability for humanitarian supplies from source to disaster zones. Every package, medication, food item, and essential supply is tracked on-chain with immutable records.

## 🎯 Features

### 🔐 Core Functions
- **📝 Supply Registration**: Register new humanitarian supplies with detailed metadata
- **📍 Real-time Tracking**: Update supply location and status throughout the journey
- **✅ Verification System**: Verify delivered supplies by authorized personnel
- **👥 Access Control**: Multi-role authorization (Owner, Operators, Verifiers)
- **📊 Transparency Dashboard**: Query supply history and current status
- **⏱️ Timestamp Records**: Immutable blockchain timestamps for all events

### 🏷️ Supply Status Levels
- `0` - **Registered**: Supply entered into the system
- `1` - **In Transit**: Supply is being transported
- `2` - **At Checkpoint**: Supply reached a checkpoint or waypoint
- `3` - **Delivered**: Supply successfully delivered to destination
- `4` - **Lost**: Supply reported as lost or missing
- `5` - **Verified**: Supply delivery confirmed by authorized verifier

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) for testing
- [Stacks CLI](https://docs.stacks.co/command-line-interface) (optional)

### 📋 Installation

```bash
# Clone the repository
git clone https://github.com/your-org/Supply-Chain-for-Disaster-Relief.git
cd Supply-Chain-for-Disaster-Relief

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

### 🎮 Usage Examples

#### Register a New Supply
```bash
clarinet console
>>> (contract-call? .Relief register-supply "Medical Supplies" "Medicine" u100 "boxes" "Haiti Relief Center" "Warehouse A")
```

#### Update Supply Status
```bash
>>> (contract-call? .Relief update-supply-status u1 u1 "En route to Port-au-Prince" "Loaded onto truck #456")
```

#### Verify Delivered Supply
```bash
>>> (contract-call? .Relief verify-supply u1 "Supplies verified and distributed to local clinic")
```

#### Query Supply Information
```bash
>>> (contract-call? .Relief get-supply u1)
>>> (contract-call? .Relief get-supply-history u1 u0)
>>> (contract-call? .Relief get-contract-stats)
```

## 🏗️ Contract Architecture

### 📊 Data Structures

**Supplies Map:**
```clarity
{
  supply-id: uint,
  name: string-ascii,
  category: string-ascii,
  quantity: uint,
  unit: string-ascii,
  source: principal,
  destination: string-ascii,
  current-status: uint,
  current-location: string-ascii,
  created-at: uint,
  updated-at: uint,
  verified: bool
}
```

**Supply History:**
```clarity
{
  supply-id: uint,
  sequence: uint,
  status: uint,
  location: string-ascii,
  timestamp: uint,
  updated-by: principal,
  notes: string-ascii
}
```

### 🔒 Access Control
- **Contract Owner**: Can add/remove operators, full access
- **Authorized Operators**: Can update supply status and verify supplies
- **Supply Source**: Original registrar can update their supplies

## 🧪 Testing

```bash
# Run all tests
npm test

# Run specific test file
npm test -- Relief.test.ts

# Check test coverage
npm run test:coverage
```

## 🚀 Deployment

### Testnet Deployment
```bash
# Configure your testnet account
stacks-cli auth

# Deploy to testnet
clarinet deployments apply --deployment testnet
```

### Mainnet Deployment
```bash
# Deploy to mainnet (requires mainnet STX)
clarinet deployments apply --deployment mainnet
```

## 📖 API Reference

### Public Functions

#### `register-supply`
Registers a new supply in the tracking system.

**Parameters:**
- `name`: Supply name (max 50 chars)
- `category`: Supply category (max 20 chars) 
- `quantity`: Amount of supplies
- `unit`: Unit of measurement (max 10 chars)
- `destination`: Final destination (max 100 chars)
- `initial-location`: Starting location (max 100 chars)

**Returns:** `(ok supply-id)` or error code

#### `update-supply-status`
Updates the status and location of a supply.

**Parameters:**
- `supply-id`: ID of the supply to update
- `new-status`: New status code (0-5)
- `new-location`: Current location (max 100 chars)
- `notes`: Update notes (max 200 chars)

**Returns:** `(ok true)` or error code

#### `verify-supply`
Marks a delivered supply as verified by authorized personnel.

**Parameters:**
- `supply-id`: ID of the supply to verify
- `verification-notes`: Verification notes (max 200 chars)

**Returns:** `(ok true)` or error code

### Read-Only Functions

#### `get-supply`
Returns complete supply information.

#### `get-supply-history` 
Returns historical record for a supply at specific sequence.

#### `get-supply-verification`
Returns verification details for a supply.

#### `get-contract-stats`
Returns contract statistics (total supplies, delivered count, etc.).

## 🛠️ Error Codes

- `u100` - Owner only operation
- `u101` - Supply not found
- `u102` - Supply already exists
- `u103` - Invalid status
- `u104` - Unauthorized access
- `u105` - Invalid input
- `u106` - Supply already delivered
- `u107` - Supply lost

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on [Stacks](https://stacks.co/) blockchain
- Powered by [Clarinet](https://github.com/hirosystems/clarinet)
- Inspired by the need for transparency in humanitarian aid

## 📞 Support

For questions and support:
- Open an issue on GitHub
- Join our community Discord
- Email: support@reliefchain.org

---

**🌍 Making humanitarian aid transparent, one supply at a time.**

