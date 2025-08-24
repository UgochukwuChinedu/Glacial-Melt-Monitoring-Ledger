A blockchain-based system for transparent tracking and accountability of global glacier melt data using Clarity smart contracts on Stacks.

## 🌍 Problem

Lack of transparent global accountability for glacial melting threatens climate action and environmental monitoring efforts.

## ✅ Solution

Blockchain technology to create immutable, timestamped records of remote-sensed glacier melt data with public accountability.

## 🚀 Features

- 📊 **Immutable Records**: All glacier measurements are permanently stored on-chain
- 🔐 **Authorized Data Sources**: Only verified sources can submit measurements  
- ⏰ **Timestamped Data**: Each measurement includes block height timestamps
- 📈 **Melt Rate Calculations**: Automatic volume loss and melt rate analytics
- 🔍 **Public Dashboard Data**: All records publicly queryable for transparency
- ✅ **Data Verification**: Owner can verify measurements for accuracy
- 🌡️ **Temperature Tracking**: Environmental conditions recorded with measurements

## 🛠️ Usage

### Register a New Glacier

```clarity
(contract-call? .Glacial-Melt-Monitoring-Ledger register-glacier 
    "Antarctic Peninsula Glacier" 
    "Antarctica -67.5, -68.0" 
    u500000 
    u150)
```

### Authorize Data Source

```clarity
(contract-call? .Glacial-Melt-Monitoring-Ledger authorize-source 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

### Record Measurement

```clarity
(contract-call? .Glacial-Melt-Monitoring-Ledger record-measurement 
    u1 
    u480000 
    u145 
    u300000 
    -15 
    "Landsat-8")
```

### Get Glacier Information

```clarity
(contract-call? .Glacial-Melt-Monitoring-Ledger get-glacier u1)
```

### Calculate Melt Rate

```clarity
(contract-call? .Glacial-Melt-Monitoring-Ledger calculate-melt-rate u1)
```

## 📋 Contract Functions

### Public Functions

- `authorize-source(principal)` - Authorize data source (owner only)
- `revoke-source(principal)` - Revoke data source authorization (owner only)
- `register-glacier(name, location, initial-area, initial-thickness)` - Register new glacier
- `deactivate-glacier(glacier-id)` - Deactivate glacier monitoring
- `record-measurement(glacier-id, area, thickness, volume-lost, temperature, data-source)` - Submit measurement
- `verify-measurement(measurement-id)` - Verify measurement accuracy (owner only)
- `batch-verify-measurements(measurement-ids)` - Verify multiple measurements (owner only)

### Read-Only Functions  

- `get-glacier(glacier-id)` - Get glacier information
- `get-measurement(measurement-id)` - Get specific measurement
- `get-latest-measurement(glacier-id)` - Get most recent measurement for glacier
- `is-authorized-source(principal)` - Check if source is authorized
- `get-source-measurement-count(principal)` - Get count of measurements by source
- `get-contract-stats()` - Get contract statistics
- `calculate-melt-rate(glacier-id)` - Calculate glacier melt rate and volume loss

## 🏗️ Setup

1. **Install Clarinet**
   ```bash
   npm install -g @hirosystems/clarinet-cli
   ```

2. **Initialize Project**
   ```bash
   clarinet new glacial-monitoring
   cd glacial-monitoring
   ```

3. **Deploy Contract**
   ```bash
   clarinet deploy --testnet
   ```

4. **Run Tests**
   ```bash
   npm test
   ```

## 🧪 Testing

The contract includes comprehensive validation:
- ✅ Input validation for all measurements
- ✅ Authorization checks for data sources  
- ✅ Glacier existence verification
- ✅ Owner-only functions protection
- ✅ Data integrity constraints

## 🌐 Deployment

Deploy to Stacks testnet or mainnet using Clarinet deployment tools:

```bash
clarinet integrate
clarinet deploy --network testnet
```

## 📊 Data Structure

### Glacier Record
- Name and location
- Initial area and thickness measurements
- Creation timestamp and creator
- Active status

### Measurement Record  
- Glacier ID reference
- Current area, thickness, volume lost
- Temperature reading
- Data source identifier
- Verification status
- Recording timestamp and recorder

## 🔒 Security

- Owner-only administrative functions
- Authorized source validation
- Input sanitization and bounds checking
- Immutable record storage
- No external dependencies

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality  
4. Run `clarinet check` for validation
5. Submit pull request

## 📄 License

MIT License - feel free to use for climate monitoring initiatives.

## 🌟 Impact

This system enables transparent climate accountability by providing:
- 📍 Verifiable glacier monitoring data
- 🔍 Public access to environmental records  
- 📈 Historical trend analysis capabilities
- 🌍 Global collaborative climate tracking
- ⚡ Real-time environmental change documentation
