import { useEffect, useState } from 'react';
import { useConnect } from '@stacks/connect-react';
import { Button } from '@chakra-ui/react';
import {
  createAssetInfo,
  FungibleConditionCode,
  NonFungibleConditionCode,
  makeStandardFungiblePostCondition,
  makeContractFungiblePostCondition,
  makeStandardNonFungiblePostCondition,
  makeContractNonFungiblePostCondition,
  PostConditionMode,
  uintCV,
  stringAsciiCV,
  contractPrincipalCV,
} from '@stacks/transactions';
import { FinishedTxData, openContractCall } from "@stacks/connect";
import { StacksTestnet } from '@stacks/network';
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
    // With a standard principal
    const contractPrincipal = contractPrincipalCV(CONTRACT_DEPLOYER, CITYPOOLS_CORE)
    const amountToStack = uintCV(50);
    const postConditionAddress = 'ST143YHR805B8S834BWJTMZVFR1WP5FFC00V8QTV4';
    const postConditionCode = FungibleConditionCode.Equal;
    const mintPostConditionAmount = new BigNum(10);
    const stackingPostConditionAmount = new BigNum(amountToStack.value);
    const network = new StacksTestnet();
    const assetAddress = CONTRACT_DEPLOYER;
    const assetContractName = CITYPOOLS_CORE;
    const fungibleAssetInfo = createAssetInfo(assetAddress, assetContractName, "CityCoin");

    const mintPostCondition = makeStandardFungiblePostCondition(
      postConditionAddress,
      postConditionCode,
      mintPostConditionAmount,
      fungibleAssetInfo
    );

    const stackingPostCondition = makeContractFungiblePostCondition(
      postConditionAddress,
      assetContractName,
      postConditionCode,
      stackingPostConditionAmount,
      fungibleAssetInfo
    );

    // Non-fungible Post Condition
    
    const nftPostConditionAddress = CONTRACT_DEPLOYER;
    const nftPostConditionCode = NonFungibleConditionCode.DoesNotOwn;
    const nftAssetAddress = CONTRACT_DEPLOYER;
    const nftAssetContractName = 'rigid-gray-dinosaur';
    const assetName = 'PoolMiami-Ticket';
    const tokenAssetName = stringAsciiCV('PoolMiami Ticket');
    const nonFungibleAssetInfo = createAssetInfo(assetAddress, assetContractName, assetName);

    const standardNonFungiblePostCondition = makeContractNonFungiblePostCondition(
      nftAssetAddress,
      nftAssetContractName,
      nftPostConditionCode,
      nonFungibleAssetInfo,
      tokenAssetName
    );

    setLoading(true);

    await openContractCall({
      onCancel: () => alert("Cancelled!"),
      onFinish: (tx: FinishedTxData) => console.log("tx sent", tx),
      contractAddress: CONTRACT_DEPLOYER,
      contractName: CITYPOOLS_CORE,
      functionName: 'claim',
      functionArgs: [amountToStack],
      postConditionMode: PostConditionMode.Deny,
      postConditions: [mintPostCondition, stackingPostCondition, standardNonFungiblePostCondition],
      
    })
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