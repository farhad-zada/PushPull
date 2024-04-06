const { ethers, upgrades } = require("hardhat");
require("dotenv").config();
const TOKEN = process.env.TOKEN;
async function main() {
  const PushPull = await ethers.getContractFactory("PushPull");
  console.log("Deploying PushPull...");
  const pushPull = await upgrades.deployProxy(PushPull, [TOKEN], {
    initializer: "initialize",
    kind: "transparent",
  });
  console.log(`Waiting for 3 confirmations...`);
  await pushPull.deploymentTransaction().wait(3);

  console.log("\x1b[32mPushPull deployed to:", pushPull.target, "\x1b[0m");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
