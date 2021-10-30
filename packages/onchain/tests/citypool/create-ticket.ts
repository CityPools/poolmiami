import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v0.14.0/index.ts'
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts'

export async function createTicket() {
  Clarinet.test({
    name: 'When create-ticket is called, it converts their principal to an id and stores it in current round',
    async fn(chain: Chain, accounts: Map<string, Account>) {
      let wallet_1 = accounts.get('wallet_1')!
      let wallet_2 = accounts.get('wallet_2')!
      let block = chain.mineBlock([
        Tx.contractCall('miamipool', 'start-round', [], wallet_1.address),
        Tx.contractCall(
          'miamipool',
          'add-funds',
          [types.uint(1000000)],
          wallet_1.address
        ),
        Tx.contractCall(
          'miamipool',
          'add-funds',
          [types.uint(2000000)],
          wallet_2.address
        ),
        Tx.contractCall(
          'miamipool',
          'get-round',
          [types.uint(1)],
          wallet_1.address
        ),
        Tx.contractCall(
          'miamipool',
          'id-to-principal',
          [types.uint(1)],
          wallet_1.address
        ),
        Tx.contractCall(
          'miamipool',
          'principal-to-id',
          [types.principal(wallet_2.address)],
          wallet_1.address
        ),
      ])
      block.receipts[0].result.expectOk()
      block.receipts[1].result.expectOk()
      block.receipts[2].result.expectOk()
      block.receipts[3].result.expectOk().expectTuple()
      assertEquals(
        block.receipts[3].result,
        '(ok {blockHeight: u1, blocksWon: [], participantIds: [u1, u2], totalMiaWon: u0, totalStx: u3000000})'
      )
      block.receipts[4].result.expectOk()
      assertEquals(block.receipts[4].result, '(ok ' + wallet_1.address + ')')
      block.receipts[5].result.expectOk()
      assertEquals(block.receipts[5].result, '(ok u2)')
    },
  })
}


