// Auto-generated SuiStrategy contract configuration
// Generated on: Wed Jan 22 2025 17:33:44 GMT-0800 (PST)

// Contract deployment details
const SUISTRATEGY_CONFIG = {
    packageId: '0x245c6267e522786d2d66e96b4a1b30b9686f9f725b8106555a2dab6128a863f8',
    network: 'testnet',
    treasury: '0x8aced0f41479e8492bbf23eb0ddf1f68994d3ab5e0c6efd51371f8b6a6597725',
    adminCap: '0xaf2d0f08f7b7570780794edb9c283ee3e88bb646331dad0ca406e3e50ed8c453'
};

// Set up CONTRACT_CONFIG for backward compatibility
const CONTRACT_CONFIG = {
    packageId: SUISTRATEGY_CONFIG.packageId,
    network: SUISTRATEGY_CONFIG.network,
    rpcUrl: 'https://fullnode.testnet.sui.io:443'
};

// Configure the frontend to use this contract
if (typeof window.setSuiStrategyContract === 'function') {
    window.setSuiStrategyContract(SUISTRATEGY_CONFIG.packageId);
}

// Make config available globally for debugging
window.SUISTRATEGY_CONFIG = SUISTRATEGY_CONFIG;
window.CONTRACT_CONFIG = CONTRACT_CONFIG;

console.log('🎉 SuiStrategy contract configured!');
console.log('📦 Package ID:', SUISTRATEGY_CONFIG.packageId);
console.log('🏦 Treasury:', SUISTRATEGY_CONFIG.treasury);
console.log('🔑 Admin Cap:', SUISTRATEGY_CONFIG.adminCap);
console.log('🌐 Network:', SUISTRATEGY_CONFIG.network);

// Available functions for testing:
console.log('Available test functions:');
console.log('- window.SUISTRATEGY_CONFIG: View all contract addresses');
console.log('- Check browser console for wallet connection status');