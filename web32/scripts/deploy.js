import hre from "hardhat";

async function main() {
  const StakeHunt = await hre.ethers.getContractFactory("StakeHunt");
  const stakeHunt = await StakeHunt.deploy();
  await stakeHunt.deployed();
  console.log("StakeHunt contract deployed to:", stakeHunt.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
