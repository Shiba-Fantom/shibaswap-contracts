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
    vaultChef: false,
    strategyShiba: false,
    strategyMasterchef: true,
  }

  let vaultChefAddress = '0x8a6d97947BD45F72EE234aab1c95FC9D41744d38'
  let strategyShiba = '0x171BB6a358B7E769B1eB3E7b2Aab779423CBeee0'

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
  
  if(config.strategyShiba) {
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
    const masterChefAddress = '0x2b2929E785374c651a81A63878Ab22742656DcDd'
    const uniRouterAddress = '0xF491e7B69E4244ad4002BC14e878a34207E38c29'

    const pid = 0;  // this is for pool of masterchef
    const wantAddress = '0xec7178f4c41f346b2721907f5cf7628e388a7a58'
    const earnedAddress = '0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE'

    const _earnedToWethPath = ['0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE', '0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83']
    const _earnedToUsdcPath = ['0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE', '0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83', '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75']
    const _earnedToGbonePath = ['0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE', '0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83', '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75', '0x004B122eb5632077abdD2C38e8d9392348d5cA15']
    const _earnedToToken0Path = ['0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE', '0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83']
    const _earnedToToken1Path = []
    const _token0ToEarnedPath = ['0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83', '0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE']
    const _token1ToEarnedPath = []

    const StrategyMasterchef = await await ethers.getContractFactory('StrategyMasterchef', {
      signer: (await ethers.getSigners())[0]
    })

    const strategyMasterchef = await StrategyMasterchef.deploy(
      vaultChefAddress,
      masterChefAddress,
      uniRouterAddress,
      pid,
      wantAddress,
      earnedAddress,
      _earnedToWethPath,
      _earnedToUsdcPath,
      _earnedToGbonePath,
      _earnedToToken0Path,
      _earnedToToken1Path,
      _token0ToEarnedPath,
      _token1ToEarnedPath
    )
    await strategyMasterchef.deployed()

    console.log(`StrategyMasterchef for pool[${pid}] deployed to `, strategyMasterchef.address)

    await sleep(60);
    await hre.run("verify:verify", {
      address: strategyMasterchef.address,
      contract: "contracts/StrategyMasterchef.sol:StrategyMasterchef",
      constructorArguments: [
        vaultChefAddress,
        masterChefAddress,
        uniRouterAddress,
        pid,
        wantAddress,
        earnedAddress,
        _earnedToWethPath,
        _earnedToUsdcPath,
        _earnedToGbonePath,
        _earnedToToken0Path,
        _earnedToToken1Path,
        _token0ToEarnedPath,
        _token1ToEarnedPath
      ],
    })

    console.log('StrategyMasterchef verified')
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
