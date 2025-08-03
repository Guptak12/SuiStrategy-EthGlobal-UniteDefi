// cross-chain-relayer.ts
import { ethers } from 'ethers';
import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { fromB64 } from '@mysten/sui.js/utils';

// Types for cross-chain coordination
interface CrossChainOrder {
  orderHash: string;
  hashlock: string;
  maker: string;
  taker: string;
  srcChain: 'ethereum' | 'sui';
  dstChain: 'ethereum' | 'sui';
  srcAmount: string;
  dstAmount: string;
  srcToken: string;
  dstToken: string;
  timelocks: TimelocksConfig;
  signature: string;
}

interface TimelocksConfig {
  withdrawal: number;
  publicWithdrawal: number;
  cancellation: number;
  publicCancellation?: number;
}

interface EscrowStatus {
  address: string;
  isDeployed: boolean;
  isWithdrawn: boolean;
  isCancelled: boolean;
  secretRevealed?: string;
  transactionHash?: string;
}

interface SwapCoordinationState {
  orderHash: string;
  srcEscrow?: EscrowStatus;
  dstEscrow?: EscrowStatus;
  secret?: string;
  phase: 'pending' | 'locked' | 'revealing' | 'completed' | 'cancelled';
  createdAt: number;
  updatedAt: number;
}

/**
 * Cross-Chain Relayer Service
 * Coordinates ETH-SUI atomic swaps using HTLCs and Limit Order Protocol
 */
export class CrossChainRelayer {
  private ethProvider: ethers.Provider;
  private suiClient: SuiClient;
  private ethSigner: ethers.Signer;
  private suiKeypair: Ed25519Keypair;
  
  // Contract addresses
  private ethEscrowFactory: string;
  private suiEscrowPackage: string;
  
  // Active swaps tracking
  private activeSwaps = new Map<string, SwapCoordinationState>();
  private orderBook = new Map<string, CrossChainOrder>();
  
  // Event listeners
  private ethEventListeners: Array<() => void> = [];
  private suiEventSubscriptions: Array<() => void> = [];

  constructor(
    ethRpcUrl: string,
    ethPrivateKey: string,
    suiNetwork: 'mainnet' | 'testnet' | 'devnet',
    suiPrivateKey: string,
    ethEscrowFactory: string,
    suiEscrowPackage: string
  ) {
    // Initialize Ethereum connection
    this.ethProvider = new ethers.JsonRpcProvider(ethRpcUrl);
    this.ethSigner = new ethers.Wallet(ethPrivateKey, this.ethProvider);
    
    // Initialize Sui connection
    this.suiClient = new SuiClient({ url: getFullnodeUrl(suiNetwork) });
    this.suiKeypair = Ed25519Keypair.fromSecretKey(fromB64(suiPrivateKey));
    
    this.ethEscrowFactory = ethEscrowFactory;
    this.suiEscrowPackage = suiEscrowPackage;
  }

  /**
   * Start the relayer service
   */
  async start(): Promise<void> {
    console.log('Starting Cross-Chain Relayer Service...');
    
    // Setup event listeners
    await this.setupEthereumListeners();
    await this.setupSuiListeners();
    
    // Start monitoring active swaps
    this.startSwapMonitoring();
    
    console.log('Cross-Chain Relayer Service started successfully');
  }

  /**
   * Stop the relayer service
   */
  async stop(): Promise<void> {
    // Clean up event listeners
    this.ethEventListeners.forEach(cleanup => cleanup());
    this.suiEventSubscriptions.forEach(cleanup => cleanup());
    
    console.log('Cross-Chain Relayer Service stopped');
  }

  /**
   * Publish a new cross-chain order
   */
  async publishOrder(order: CrossChainOrder): Promise<string> {
    // Validate order structure
    this.validateOrder(order);
    
    // Store in order book
    this.orderBook.set(order.orderHash, order);
    
    // Try to find immediate matches
    await this.findAndExecuteMatches(order);
    
    console.log(`Order published: ${order.orderHash}`);
    return order.orderHash;
  }

  /**
   * Cancel an existing order
   */
  async cancelOrder(orderHash: string): Promise<boolean> {
    const order = this.orderBook.get(orderHash);
    if (!order) {
      throw new Error(`Order not found: ${orderHash}`);
    }
    
    // Remove from order book
    this.orderBook.delete(orderHash);
    
    // Cancel any active swap coordination
    const swapState = this.activeSwaps.get(orderHash);
    if (swapState) {
      swapState.phase = 'cancelled';
      swapState.updatedAt = Date.now();
    }
    
    console.log(`Order cancelled: ${orderHash}`);
    return true;
  }

  /**
   * Setup Ethereum event listeners
   */
  private async setupEthereumListeners(): Promise<void> {
    const factoryContract = new ethers.Contract(
      this.ethEscrowFactory,
      [
        'event EthToSuiSwapInitiated(bytes32 indexed orderHash, bytes32 indexed hashlock, address indexed maker, address taker, uint256 ethAmount, uint256 suiAmount, bytes32 suiTokenAddress)',
        'event SuiToEthSwapInitiated(bytes32 indexed orderHash, bytes32 indexed hashlock, address indexed taker, address maker, uint256 suiAmount, uint256 ethAmount, uint64 suiEscrowObjectId)',
        'event CrossChainSecretRevealed(bytes32 indexed orderHash, bytes32 secret, uint256 chainId)'
      ],
      this.ethProvider
    );

    // Define listener functions
    const ethToSuiListener = async (orderHash: string, hashlock: string, maker: string, taker: string, ethAmount: bigint, suiAmount: bigint, suiTokenAddress: string, event: any) => {
      console.log(`ETH → SUI swap initiated: ${orderHash}`);
      
      await this.handleEthToSuiInitiation({
        orderHash,
        hashlock,
        maker,
        taker,
        ethAmount: ethAmount.toString(),
        suiAmount: suiAmount.toString(),
        suiTokenAddress,
        transactionHash: event.transactionHash
      });
    };

    const suiToEthListener = async (orderHash: string, hashlock: string, taker: string, maker: string, suiAmount: bigint, ethAmount: bigint, suiEscrowObjectId: bigint, event: any) => {
      console.log(`SUI → ETH swap initiated: ${orderHash}`);
      
      await this.handleSuiToEthInitiation({
        orderHash,
        hashlock,
        taker,
        maker,
        suiAmount: suiAmount.toString(),
        ethAmount: ethAmount.toString(),
        suiEscrowObjectId: suiEscrowObjectId.toString(),
        transactionHash: event.transactionHash
      });
    };

    const secretListener = async (orderHash: string, secret: string, chainId: bigint) => {
      console.log(`Secret revealed for order ${orderHash} on chain ${chainId}`);
      await this.handleSecretRevelation(orderHash, secret, chainId.toString());
    };

    // Attach listeners to contract
    factoryContract.on('EthToSuiSwapInitiated', ethToSuiListener);
    factoryContract.on('SuiToEthSwapInitiated', suiToEthListener);
    factoryContract.on('CrossChainSecretRevealed', secretListener);

    this.ethEventListeners.push(
      () => factoryContract.removeListener('EthToSuiSwapInitiated', ethToSuiListener),
      () => factoryContract.removeListener('SuiToEthSwapInitiated', suiToEthListener),
      () => factoryContract.removeListener('CrossChainSecretRevealed', secretListener)
    );
  }

  /**
   * Setup Sui event listeners
   */
  private async setupSuiListeners(): Promise<void> {
    // Subscribe to SUI escrow events
    const unsubscribeEscrowCreated = await this.suiClient.subscribeEvent({
      filter: {
        Package: this.suiEscrowPackage
      },
      onMessage: async (event: any) => {
        if (event.type.endsWith('::SuiEscrowCreated')) {
          await this.handleSuiEscrowCreated(event);
        } else if (event.type.endsWith('::EscrowWithdrawal')) {
          await this.handleSuiEscrowWithdrawal(event);
        } else if (event.type.endsWith('::SecretRevealed')) {
          await this.handleSuiSecretRevealed(event);
        }
      }
    });
    
    this.suiEventSubscriptions.push(unsubscribeEscrowCreated);
  }

  /**
   * Handle ETH → SUI swap initiation
   */
  private async handleEthToSuiInitiation(params: {
    orderHash: string;
    hashlock: string;
    maker: string;
    taker: string;
    ethAmount: string;
    suiAmount: string;
    suiTokenAddress: string;
    transactionHash: string;
  }) {
    const swapState: SwapCoordinationState = {
      orderHash: params.orderHash,
      srcEscrow: {
        address: '', // Will be computed
        isDeployed: true,
        isWithdrawn: false,
        isCancelled: false,
        transactionHash: params.transactionHash
      },
      phase: 'locked',
      createdAt: Date.now(),
      updatedAt: Date.now()
    };

    this.activeSwaps.set(params.orderHash, swapState);

    // Create corresponding SUI destination escrow
    await this.createSuiDestinationEscrow(params);
  }

  /**
   * Handle SUI → ETH swap initiation
   */
  private async handleSuiToEthInitiation(params: {
    orderHash: string;
    hashlock: string;
    taker: string;
    maker: string;
    suiAmount: string;
    ethAmount: string;
    suiEscrowObjectId: string;
    transactionHash: string;
  }) {
    const swapState: SwapCoordinationState = {
      orderHash: params.orderHash,
      srcEscrow: {
        address: params.suiEscrowObjectId,
        isDeployed: true,
        isWithdrawn: false,
        isCancelled: false,
        transactionHash: params.transactionHash
      },
      phase: 'locked',
      createdAt: Date.now(),
      updatedAt: Date.now()
    };

    this.activeSwaps.set(params.orderHash, swapState);

    // Create corresponding ETH destination escrow would be handled by the order matching
  }

  /**
   * Create SUI destination escrow
   */
  private async createSuiDestinationEscrow(params: {
    orderHash: string;
    hashlock: string;
    maker: string;
    taker: string;
    suiAmount: string;
    suiTokenAddress: string;
  }) {
    try {
      const tx = new TransactionBlock();
      
      // Convert hashlock from hex to bytes
      const hashlockBytes = Array.from(ethers.getBytes(params.hashlock));
      const orderHashBytes = Array.from(ethers.getBytes(params.orderHash));
      
      // Create destination escrow on Sui
      tx.moveCall({
        target: `${this.suiEscrowPackage}::escrow_factory::create_dst_escrow`,
        typeArguments: ['0x2::sui::SUI'], // Assuming SUI token for now
        arguments: [
          tx.object('FACTORY_OBJECT_ID'), // Factory object
          tx.pure(orderHashBytes),
          tx.pure(hashlockBytes),
          tx.pure(params.maker),
          tx.pure(params.taker),
          tx.object('SUI_COIN_OBJECT'), // SUI coin to lock
          tx.object('SAFETY_DEPOSIT_COIN'), // Safety deposit
          tx.pure(1800000), // withdrawal_delay (30 minutes)
          tx.pure(5400000), // public_withdrawal_delay (1.5 hours)
          tx.pure(90000000), // cancellation_delay (25 hours)
          tx.pure(0), // protocol_fee_amount
          tx.pure(0), // integrator_fee_amount
          tx.pure(params.maker), // protocol_fee_recipient
          tx.pure(params.taker), // integrator_fee_recipient
          tx.object('0x6'), // Clock object
        ],
      });

      const result = await this.suiClient.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        signer: this.suiKeypair,
        options: {
          showEffects: true,
          showEvents: true,
        },
      });

      console.log(`Created SUI destination escrow: ${result.digest}`);
      
      // Update swap state
      const swapState = this.activeSwaps.get(params.orderHash);
      if (swapState) {
        swapState.dstEscrow = {
          address: result.digest, // Transaction digest as reference
          isDeployed: true,
          isWithdrawn: false,
          isCancelled: false,
          transactionHash: result.digest
        };
        swapState.updatedAt = Date.now();
      }

    } catch (error) {
      console.error('Failed to create SUI destination escrow:', error);
    }
  }

  /**
   * Handle secret revelation
   */
  private async handleSecretRevelation(orderHash: string, secret: string, chainId: string): Promise<void> {
    const swapState = this.activeSwaps.get(orderHash);
    if (!swapState) {
      console.warn(`No active swap found for order: ${orderHash}`);
      return;
    }

    swapState.secret = secret;
    swapState.phase = 'revealing';
    swapState.updatedAt = Date.now();

    console.log(`Secret revealed for ${orderHash}: ${secret}`);

    // Coordinate the cross-chain claim process
    await this.coordinateClaimProcess(orderHash, secret);
  }

  /**
   * Coordinate the claim process across chains
   */
  private async coordinateClaimProcess(orderHash: string, secret: string): Promise<void> {
    const swapState = this.activeSwaps.get(orderHash);
    if (!swapState) return;

    try {
      // If we have both escrows deployed, proceed with claims
      if (swapState.srcEscrow?.isDeployed && swapState.dstEscrow?.isDeployed) {
        
        // Determine which chain to claim from first based on the swap direction
        const order = this.orderBook.get(orderHash);
        if (!order) {
          console.error(`Order not found in order book: ${orderHash}`);
          return;
        }

        if (order.srcChain === 'ethereum') {
          // ETH → SUI: Claim from SUI first, then ETH
          await this.claimFromSui(orderHash, secret);
          await this.claimFromEthereum(orderHash, secret);
        } else {
          // SUI → ETH: Claim from ETH first, then SUI
          await this.claimFromEthereum(orderHash, secret);
          await this.claimFromSui(orderHash, secret);
        }

        swapState.phase = 'completed';
        swapState.updatedAt = Date.now();
        
        console.log(`Swap completed successfully: ${orderHash}`);
      }
    } catch (error) {
      console.error(`Failed to coordinate claim process for ${orderHash}:`, error);
    }
  }

  /**
   * Claim from SUI escrow
   */
  private async claimFromSui(orderHash: string, secret: string): Promise<void> {
    const swapState = this.activeSwaps.get(orderHash);
    if (!swapState?.dstEscrow) return;

    try {
      const tx = new TransactionBlock();
      const secretBytes = Array.from(ethers.getBytes(secret));

      // Determine if this is source or destination escrow
      const order = this.orderBook.get(orderHash);
      if (!order) return;

      if (order.srcChain === 'sui') {
        // Claim from source escrow
        tx.moveCall({
          target: `${this.suiEscrowPackage}::escrow_factory::withdraw_src`,
          typeArguments: ['0x2::sui::SUI'],
          arguments: [
            tx.object(swapState.srcEscrow!.address),
            tx.pure(secretBytes),
            tx.object('0x6'), // Clock
          ],
        });
      } else {
        // Claim from destination escrow
        tx.moveCall({
          target: `${this.suiEscrowPackage}::escrow_factory::withdraw_dst`,
          typeArguments: ['0x2::sui::SUI'],
          arguments: [
            tx.object(swapState.dstEscrow.address),
            tx.pure(secretBytes),
            tx.object('0x6'), // Clock
          ],
        });
      }

      const result = await this.suiClient.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        signer: this.suiKeypair,
        options: {
          showEffects: true,
        },
      });

      console.log(`Claimed from SUI escrow: ${result.digest}`);
      
      if (swapState.srcEscrow && order.srcChain === 'sui') {
        swapState.srcEscrow.isWithdrawn = true;
      }
      if (swapState.dstEscrow && order.dstChain === 'sui') {
        swapState.dstEscrow.isWithdrawn = true;
      }

    } catch (error) {
      console.error(`Failed to claim from SUI: ${error}`);
    }
  }

  /**
   * Claim from Ethereum escrow
   */
  private async claimFromEthereum(orderHash: string, secret: string): Promise<void> {
    const swapState = this.activeSwaps.get(orderHash);
    if (!swapState) return;

    try {
      const order = this.orderBook.get(orderHash);
      if (!order) return;

      // Get the appropriate escrow contract address
      const escrowAddress = swapState.srcEscrow?.address || swapState.dstEscrow?.address;
      if (!escrowAddress) return;

      // Create contract instance
      const escrowContract = new ethers.Contract(
        escrowAddress,
        [
          'function withdraw(bytes32 secret, tuple(bytes32 orderHash, bytes32 hashlock, address maker, address taker, address token, uint256 amount, uint256 safetyDeposit, uint256 timelocks, bytes parameters) immutables)',
          'function publicWithdraw(bytes32 secret, tuple(bytes32 orderHash, bytes32 hashlock, address maker, address taker, address token, uint256 amount, uint256 safetyDeposit, uint256 timelocks, bytes parameters) immutables)'
        ],
        this.ethSigner
      );

      // Prepare immutables struct
      const immutables = {
        orderHash: orderHash,
        hashlock: order.hashlock,
        maker: order.maker,
        taker: order.taker,
        token: order.srcChain === 'ethereum' ? order.srcToken : order.dstToken,
        amount: order.srcChain === 'ethereum' ? order.srcAmount : order.dstAmount,
        safetyDeposit: ethers.parseEther('0.01'), // Standard safety deposit
        timelocks: this.encodeTimelocks(order.timelocks),
        parameters: '0x' // Empty parameters
      };

      // Try private withdrawal first, fallback to public
      let tx;
      try {
        tx = await escrowContract.withdraw(secret, immutables);
      } catch (error) {
        console.log('Private withdrawal failed, trying public withdrawal');
        tx = await escrowContract.publicWithdraw(secret, immutables);
      }

      const receipt = await tx.wait();
      console.log(`Claimed from Ethereum escrow: ${receipt.transactionHash}`);

      // Update state
      if (swapState.srcEscrow && order.srcChain === 'ethereum') {
        swapState.srcEscrow.isWithdrawn = true;
      }
      if (swapState.dstEscrow && order.dstChain === 'ethereum') {
        swapState.dstEscrow.isWithdrawn = true;
      }

    } catch (error) {
      console.error(`Failed to claim from Ethereum: ${error}`);
    }
  }

  /**
   * Handle SUI escrow created event
   */
  private async handleSuiEscrowCreated(event: any): Promise<void> {
    const { escrow_id, order_hash } = event.parsedJson;
    const orderHashHex = '0x' + Buffer.from(order_hash).toString('hex');
    
    console.log(`SUI escrow created: ${escrow_id} for order ${orderHashHex}`);
    
    const swapState = this.activeSwaps.get(orderHashHex);
    if (swapState && !swapState.srcEscrow?.isDeployed) {
      swapState.srcEscrow = {
        address: escrow_id,
        isDeployed: true,
        isWithdrawn: false,
        isCancelled: false,
        transactionHash: event.id.txDigest
      };
      swapState.updatedAt = Date.now();
    }
  }

  /**
   * Handle SUI escrow withdrawal event
   */
  private async handleSuiEscrowWithdrawal(event: any): Promise<void> {
    const { escrow_id, secret } = event.parsedJson;
    const secretHex = '0x' + Buffer.from(secret).toString('hex');
    
    console.log(`SUI escrow withdrawal: ${escrow_id}, secret: ${secretHex}`);
    
    // Find the corresponding swap by escrow ID
    for (const [orderHash, swapState] of this.activeSwaps) {
      if (swapState.srcEscrow?.address === escrow_id || swapState.dstEscrow?.address === escrow_id) {
        await this.handleSecretRevelation(orderHash, secretHex, '101'); // SUI chain ID
        break;
      }
    }
  }

  /**
   * Handle SUI secret revealed event
   */
  private async handleSuiSecretRevealed(event: any): Promise<void> {
    const { order_hash, secret } = event.parsedJson;
    const orderHashHex = '0x' + Buffer.from(order_hash).toString('hex');
    const secretHex = '0x' + Buffer.from(secret).toString('hex');
    
    await this.handleSecretRevelation(orderHashHex, secretHex, '101');
  }

  /**
   * Find and execute order matches
   */
  private async findAndExecuteMatches(newOrder: CrossChainOrder): Promise<void> {
    for (const [existingOrderHash, existingOrder] of this.orderBook) {
      if (this.ordersMatch(newOrder, existingOrder)) {
        console.log(`Found matching orders: ${newOrder.orderHash} <-> ${existingOrderHash}`);
        await this.executeOrderMatch(newOrder, existingOrder);
        break;
      }
    }
  }

  /**
   * Check if two orders match
   */
  private ordersMatch(order1: CrossChainOrder, order2: CrossChainOrder): boolean {
    return (
      order1.srcChain === order2.dstChain &&
      order1.dstChain === order2.srcChain &&
      order1.srcToken === order2.dstToken &&
      order1.dstToken === order2.srcToken &&
      order1.srcAmount === order2.dstAmount &&
      order1.dstAmount === order2.srcAmount &&
      order1.orderHash !== order2.orderHash
    );
  }

  /**
   * Execute a matched order pair
   */
  private async executeOrderMatch(order1: CrossChainOrder, order2: CrossChainOrder): Promise<void> {
    console.log(`Executing order match: ${order1.orderHash} <-> ${order2.orderHash}`);
    
    // Generate shared secret for both orders
    const secret = ethers.hexlify(ethers.randomBytes(32));
    const hashlock = ethers.keccak256(secret);
    
    // Update both orders with the same hashlock
    order1.hashlock = hashlock;
    order2.hashlock = hashlock;
    
    // Store the secret for later revelation
    const swapState1: SwapCoordinationState = {
      orderHash: order1.orderHash,
      secret,
      phase: 'pending',
      createdAt: Date.now(),
      updatedAt: Date.now()
    };
    
    const swapState2: SwapCoordinationState = {
      orderHash: order2.orderHash,
      secret,
      phase: 'pending',
      createdAt: Date.now(),
      updatedAt: Date.now()
    };
    
    this.activeSwaps.set(order1.orderHash, swapState1);
    this.activeSwaps.set(order2.orderHash, swapState2);
    
    // The actual escrow creation will be triggered by the LOP execution
    console.log(`Order match setup complete with secret: ${secret}`);
  }

  /**
   * Monitor active swaps for timeouts and issues
   */
  private startSwapMonitoring(): void {
    setInterval(async () => {
      const now = Date.now();
      const TIMEOUT_THRESHOLD = 24 * 60 * 60 * 1000; // 24 hours
      
      for (const [orderHash, swapState] of this.activeSwaps) {
        // Check for timeouts
        if (now - swapState.createdAt > TIMEOUT_THRESHOLD && swapState.phase !== 'completed') {
          console.warn(`Swap timeout detected: ${orderHash}`);
          await this.handleSwapTimeout(orderHash);
        }
        
        // Check for stuck swaps
        if (now - swapState.updatedAt > 60 * 60 * 1000 && swapState.phase === 'revealing') { // 1 hour
          console.warn(`Stuck swap detected: ${orderHash}`);
          await this.handleStuckSwap(orderHash);
        }
      }
    }, 60 * 1000); // Check every minute
  }

  /**
   * Handle swap timeout
   */
  private async handleSwapTimeout(orderHash: string): Promise<void> {
    const swapState = this.activeSwaps.get(orderHash);
    if (!swapState) return;
    
    console.log(`Handling timeout for swap: ${orderHash}`);
    
    // Mark as cancelled and notify participants
    swapState.phase = 'cancelled';
    swapState.updatedAt = Date.now();
    
    // Remove from order book
    this.orderBook.delete(orderHash);
    
    // Could trigger cancellation transactions here if needed
  }

  /**
   * Handle stuck swap
   */
  private async handleStuckSwap(orderHash: string): Promise<void> {
    const swapState = this.activeSwaps.get(orderHash);
    if (!swapState || !swapState.secret) return;
    
    console.log(`Attempting to unstick swap: ${orderHash}`);
    
    // Retry the claim process
    await this.coordinateClaimProcess(orderHash, swapState.secret);
  }

  /**
   * Validate order structure
   */
  private validateOrder(order: CrossChainOrder): void {
    if (!order.orderHash || !order.maker || !order.taker) {
      throw new Error('Invalid order: missing required fields');
    }
    
    if (!order.srcAmount || !order.dstAmount) {
      throw new Error('Invalid order: missing amounts');
    }
    
    if (order.srcChain === order.dstChain) {
      throw new Error('Invalid order: source and destination chains must be different');
    }
    
    if (!['ethereum', 'sui'].includes(order.srcChain) || !['ethereum', 'sui'].includes(order.dstChain)) {
      throw new Error('Invalid order: unsupported chain');
    }
  }

  /**
   * Encode timelocks for Ethereum contracts
   */
  private encodeTimelocks(timelocks: TimelocksConfig): string {
    // This is a simplified encoding - actual implementation would pack into uint256
    const packed = 
      (timelocks.withdrawal & 0xFFFFFFFF) |
      ((timelocks.publicWithdrawal & 0xFFFFFFFF) << 32) |
      ((timelocks.cancellation & 0xFFFFFFFF) << 64) |
      (((timelocks.publicCancellation || 0) & 0xFFFFFFFF) << 96);
    
    return ethers.toBeHex(packed, 32);
  }

  /**
   * Get swap status
   */
  getSwapStatus(orderHash: string): SwapCoordinationState | undefined {
    return this.activeSwaps.get(orderHash);
  }

  /**
   * Get all active swaps
   */
  getAllActiveSwaps(): Map<string, SwapCoordinationState> {
    return new Map(this.activeSwaps);
  }

  /**
   * Get order book
   */
  getOrderBook(): Map<string, CrossChainOrder> {
    return new Map(this.orderBook);
  }
}

// Example usage
async function main() {
  const relayer = new CrossChainRelayer(
    'https://eth-mainnet.g.alchemy.com/v2/your-api-key',
    'your-eth-private-key',
    'mainnet',
    'your-sui-private-key',
    '0x1234...', // ETH escrow factory address
    '0x5678...'  // SUI escrow package ID
  );

  await relayer.start();

  // Example order
  const order: CrossChainOrder = {
    orderHash: '0xabc123...',
    hashlock: '0x000...', // Will be set during matching
    maker: '0xmaker...',
    taker: '0xtaker...',
    srcChain: 'ethereum',
    dstChain: 'sui',
    srcAmount: ethers.parseEther('1').toString(),
    dstAmount: '1000000000', // 1 SUI
    srcToken: '0x0000000000000000000000000000000000000000', // ETH
    dstToken: '0x0000000000000000000000000000000000000002::sui::SUI',
    timelocks: {
      withdrawal: 3600,
      publicWithdrawal: 7200,
      cancellation: 86400,
      publicCancellation: 172800
    },
    signature: '0xsignature...'
  };

  await relayer.publishOrder(order);
}

// Export for use as a module
export default CrossChainRelayer;