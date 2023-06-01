import { ethers } from "hardhat";

async function main() {
  const ReactionsContractFactory = await ethers.getContractFactory("Reactions");
  const reactionsContract = await ReactionsContractFactory.deploy();

  await reactionsContract.deployed();

  console.log('### contract address', reactionsContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
