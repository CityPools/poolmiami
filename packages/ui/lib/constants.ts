import {
  TransactionsApi,
  SmartContractsApi,
  AccountsApi,
  Configuration,
  InfoApi,
} from '@stacks/blockchain-api-client';
import { StacksTestnet, StacksMainnet } from '@stacks/network';

export const testnet = true;
export const localAuth = false;

console.log({ localAuth, testnet });

export const CONTRACT_DEPLOYER = 'ST143YHR805B8S834BWJTMZVFR1WP5FFC00V8QTV4';
export const CITYPOOLS_CORE = 'organisational-black-cockroach';

export const STACKS_API_URL = 'https://stacks-node-api.testnet.stacks.co';
export const STACKS_API_WS_URL = 'wss://stacks-node-api.testnet.stacks.co';
export const STACKS_API_V2_INFO = `${STACKS_API_URL}/v2/info`;
export const STACKS_API_ACCOUNTS_URL = `${STACKS_API_URL}/v2/accounts`;
export const STACKS_API_FEE_URL = `${STACKS_API_URL}/v2/fees/transfer`;

export const NETWORK = new StacksTestnet();
NETWORK.coreApiUrl = STACKS_API_URL;

const basePath = STACKS_API_URL;
const config = new Configuration({ basePath });
export const accountsApi = new AccountsApi(config);
export const smartContractsApi = new SmartContractsApi(config);
export const transactionsApi = new TransactionsApi(config);
export const infoApi = new InfoApi(config);