import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Registration tests",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Test passenger registration
    let block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'register-passenger', 
        [
          types.principal(wallet1.address),
          types.ascii("John Passenger"),
        ],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk();
    
    // Test driver registration
    block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'register-driver', 
        [
          types.principal(wallet2.address),
          types.ascii("John Driver"),
          types.ascii("ABC123")
        ],
        wallet2.address
      )
    ]);
    block.receipts[0].result.expectOk();
    
    // Test duplicate registration
    block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'register-driver', 
        [
          types.principal(wallet2.address),
          types.ascii("John Driver"),
          types.ascii("ABC123")
        ],
        wallet2.address
      )
    ]);
    block.receipts[0].result.expectErr(types.uint(103));
  }
});

Clarinet.test({
  name: "Complete ride lifecycle test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const passenger = accounts.get('wallet_1')!;
    const driver = accounts.get('wallet_2')!;
    
    // Register both parties
    let block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'register-passenger',
        [
          types.principal(passenger.address),
          types.ascii("John Passenger")
        ],
        passenger.address
      ),
      Tx.contractCall('quantum-ride', 'register-driver',
        [
          types.principal(driver.address),
          types.ascii("John Driver"),
          types.ascii("XYZ789")
        ],
        driver.address
      )
    ]);
    
    // Create ride request
    block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'create-ride-request',
        [
          types.principal(passenger.address),
          types.uint(100),
          types.ascii("123 Start St"),
          types.ascii("456 End Ave")
        ],
        passenger.address
      )
    ]);
    
    const requestId = block.receipts[0].result.expectOk();
    
    // Accept ride
    block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'accept-ride',
        [
          types.principal(driver.address),
          requestId
        ],
        driver.address
      )
    ]);
    block.receipts[0].result.expectOk();
    
    // Complete ride
    block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'complete-ride',
        [requestId],
        driver.address
      )
    ]);
    block.receipts[0].result.expectOk();
    
    // Verify ride counts updated
    const driverInfo = chain.callReadOnlyFn(
      'quantum-ride',
      'get-driver-info',
      [types.principal(driver.address)],
      driver.address
    );
    driverInfo.result.expectOk().expectSome().get("total-rides").expectUint(1);
  }
});
