#!/bin/bash

# SuiStrategy Contract Deployment Script
echo "🚀 Deploying SuiStrategy Contract..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if sui CLI is installed
if ! command -v sui &> /dev/null; then
    echo -e "${RED}❌ Sui CLI not found. Please install it first.${NC}"
    echo "Visit: https://docs.sui.io/guides/developer/getting-started/sui-install"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Move.toml" ]; then
    echo -e "${RED}❌ Move.toml not found. Please run this script from the contracts directory.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Checking Sui environment...${NC}"

# Check active environment
ACTIVE_ENV=$(sui client active-env 2>/dev/null || echo "none")
echo -e "${YELLOW}Current environment: ${ACTIVE_ENV}${NC}"

# Start local Sui network if needed
if [ "$ACTIVE_ENV" = "localnet" ] || [ "$ACTIVE_ENV" = "none" ]; then
    echo -e "${BLUE}🌐 Setting up local Sui network...${NC}"
    
    # Kill any existing sui processes
    pkill -f "sui start" 2>/dev/null || true
    pkill -f "sui-node" 2>/dev/null || true
    
    # Add localnet environment if it doesn't exist
    sui client new-env --alias localnet --rpc http://127.0.0.1:9000 2>/dev/null || true
    
    # Switch to localnet
    sui client switch --env localnet 2>/dev/null || true
    
    # Start local Sui network in background
    echo -e "${YELLOW}Starting local Sui network (this may take a moment)...${NC}"
    sui start --with-faucet &
    SUI_PID=$!
    
    # Wait for the network to start
    echo -e "${YELLOW}Waiting for network to initialize...${NC}"
    sleep 10
    
    # Check if network is running
    for i in {1..30}; do
        if curl -s http://127.0.0.1:9000 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Local Sui network is running${NC}"
            break
        else
            echo -e "${YELLOW}⏳ Waiting for network... (${i}/30)${NC}"
            sleep 2
        fi
        
        if [ $i -eq 30 ]; then
            echo -e "${RED}❌ Failed to start local Sui network${NC}"
            exit 1
        fi
    done
fi

# Get or create address
echo -e "${BLUE}👤 Setting up wallet address...${NC}"
ADDRESSES=$(sui client addresses 2>/dev/null || echo "")

if [ -z "$ADDRESSES" ]; then
    echo -e "${YELLOW}Creating new address...${NC}"
    sui client new-address ed25519 2>/dev/null || true
fi

ACTIVE_ADDRESS=$(sui client active-address 2>/dev/null || echo "")
echo -e "${GREEN}Active address: ${ACTIVE_ADDRESS}${NC}"

# Request gas from faucet (for localnet)
if [ "$ACTIVE_ENV" = "localnet" ]; then
    echo -e "${BLUE}⛽ Requesting gas from faucet...${NC}"
    sui client faucet --address $ACTIVE_ADDRESS 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Faucet request failed, but continuing...${NC}"
    }
fi

# Build the contract
echo -e "${BLUE}🔨 Building Move contract...${NC}"
if ! sui move build; then
    echo -e "${RED}❌ Build failed. Please check your Move code.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

# Publish the contract
echo -e "${BLUE}📦 Publishing contract...${NC}"
PUBLISH_OUTPUT=$(sui client publish --gas-budget 100000000 2>&1)

if echo "$PUBLISH_OUTPUT" | grep -q "successfully"; then
    echo -e "${GREEN}✅ Contract published successfully!${NC}"
    
    # Extract package ID
    PACKAGE_ID=$(echo "$PUBLISH_OUTPUT" | grep -oE "0x[a-f0-9]{64}" | head -1)
    
    if [ -n "$PACKAGE_ID" ]; then
        echo -e "${GREEN}📋 Package ID: ${PACKAGE_ID}${NC}"
        
        # Save package ID to a file
        echo "$PACKAGE_ID" > package_id.txt
        
        # Create JavaScript snippet for frontend
        cat > ../app/auth/login/contract-config.js << EOF
// Auto-generated contract configuration
// Generated on: $(date)

window.setSuiStrategyContract('$PACKAGE_ID');

console.log('SuiStrategy contract configured with Package ID: $PACKAGE_ID');
EOF
        
        echo -e "${BLUE}📁 Contract configuration saved to:${NC}"
        echo -e "   ${YELLOW}• package_id.txt${NC}"
        echo -e "   ${YELLOW}• ../app/auth/login/contract-config.js${NC}"
        
        echo ""
        echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo -e "1. Open your browser and go to the login page"
        echo -e "2. Open browser console (F12) and paste:"
        echo -e "   ${YELLOW}window.setSuiStrategyContract('$PACKAGE_ID')${NC}"
        echo -e "3. Or include the contract-config.js script in your HTML"
        echo ""
        echo -e "${BLUE}Package ID for manual configuration:${NC}"
        echo -e "${YELLOW}$PACKAGE_ID${NC}"
        
    else
        echo -e "${RED}❌ Could not extract package ID from output${NC}"
        echo "$PUBLISH_OUTPUT"
    fi
else
    echo -e "${RED}❌ Contract publishing failed${NC}"
    echo "$PUBLISH_OUTPUT"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ SuiStrategy is ready for local testing!${NC}"