import { useEffect, useState } from 'react';
import { Button } from '@chakra-ui/react';
import { useConnect } from '@stacks/connect-react';
import {
  createAssetInfo,
  FungibleConditionCode,
  makeContractFungiblePostCondition,
  makeContractSTXPostCondition,
  PostConditionMode,
  uintCV,
} from '@stacks/transactions';
import {
  CITYPOOLS_CORE,
  CONTRACT_DEPLOYER,
  NETWORK,
} from '../lib/constants';
import { TxStatus } from './TxStatus';

const BigNum = require('bn.js');

export default function Mint() {
  const [loading, setLoading] = useState(false);
  const [txId, setTxId] = useState();

  const claimNFT = async () => {
    const targetRewardCycleCV = uintCV(6);
    const amountUstxCV = uintCV(1000000);
    const amountCityCoinCV = uintCV(305000);
    setLoading(true);
    let postConditions = [];
    amountUstxCV.value > 0 &&
      postConditions.push(
        makeContractSTXPostCondition(
          CONTRACT_DEPLOYER,
          CITYPOOLS_CORE,
          FungibleConditionCode.Equal,
          amountUstxCV.value
        )
      );
      
    await doContractCall({
      contractAddress: CONTRACT_DEPLOYER,
      contractName: CITYCOIN_CORE,
      functionName: 'claim',
      functionArgs: [],
      postConditionMode: PostConditionMode.Deny,
      postConditions: postConditions,
      network: NETWORK,
      onCancel: () => {
        setLoading(false);
      },
      onFinish: result => {
        setLoading(false);
        setTxId(result.txId);
      },
    });
  };

  return (
    <Button
      size="lg"
      colorScheme="blue"
      height="14"
      px="8"
      fontSize="md"
      onClick={claimNFT}
    >
      Mint
    </Button>
  );
}