const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const contractAddress = "<YOUR_DEPLOYED_CONTRACT_ADDRESS>";
  const StakeHunt = await hre.ethers.getContractAt("StakeHunt", contractAddress);

  // Example function to call
  const tx = await StakeHunt.someFunction(); // Replace with actual function in your contract
  await tx.wait();

  console.log("Transaction completed");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


// npx hardhat run scripts/interact.js --network localhost
