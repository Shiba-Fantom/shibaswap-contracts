const ShibaRouter = artifacts.require("ShibaRouter");
const WETH = artifacts.require("WETH");

module.exports = async function (deployer, network) {
  let weth;
  const FACTORY_ADDRESS = '0xF056a6A3c45Eb58e4d221733faECC5593D3c7C8b';

  if (network === 'mainnet') {
    weth = await WETH.at('0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83');
  } else {
    await deployer.deploy(WETH);
    weth = await WETH.deployed();
  }
  await deployer.deploy(ShibaRouter, FACTORY_ADDRESS, weth.address);
};
