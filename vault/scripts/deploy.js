require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main () {
  const ethers = hre.ethers
  const upgrades = hre.upgrades;

  console.log('network:', await ethers.provider.getNetwork())

  const signer = (await ethers.getSigners())[0]
  console.log('signer:', await signer.getAddress())


  const config = {
    vaultChef: true,
    strategyShiba: true,
    strategyMasterchef: false,
  }

  let vaultChefAddress = null

  /**
   * deploy vaultchef
   */

  if(config.vaultChef) {
    const VaultChef = await await ethers.getContractFactory('VaultChef', {
      signer: (await ethers.getSigners())[0]
    })

    const vaultchef = await VaultChef.deploy()
    await vaultchef.deployed()

    console.log('VaultChef deployed to ', vaultchef.address)
    vaultChefAddress = vaultchef.address

    await sleep(60);
    await hre.run("verify:verify", {
      address: vaultchef.address,
      contract: "contracts/VaultChef.sol:VaultChef",
      constructorArguments: [],
    })

    console.log('VaultChef verified')
  }
  
  if(config.strategyMasterchef) {
    const StrategyShiba = await await ethers.getContractFactory('StrategyShiba', {
      signer: (await ethers.getSigners())[0]
    })

    const strategyShiba = await StrategyShiba.deploy(vaultChefAddress)
    await strategyShiba.deployed()

    console.log('StrategyShiba deployed to ', strategyShiba.address)

    await sleep(60);
    await hre.run("verify:verify", {
      address: strategyShiba.address,
      contract: "contracts/StrategyShiba.sol:StrategyShiba",
      constructorArguments: [vaultChefAddress],
    })

    console.log('StrategyShiba verified')
  }

  if(config.strategyMasterchef) {

  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
