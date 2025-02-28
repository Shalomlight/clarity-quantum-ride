import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Driver registration test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('quantum-ride', 'register-driver', 
        [
          types.principal(wallet1.address),
          types.ascii("John Doe"),
          types.ascii("ABC123")
        ],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk();
    
    const response = chain.callReadOnlyFn(
      'quantum-ride',
      'get-driver-info',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    response.result.expectOk().expectSome();
  }
});

Clarinet.test({
  name: "Ride request lifecycle test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const passenger = accounts.get('wallet_1')!;
    const driver = accounts.get('wallet_2')!;
    
    // Register driver
    let block = chain.mineBlock([
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
  }
});
