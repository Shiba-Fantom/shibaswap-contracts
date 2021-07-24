const Factory = artifacts.require("ShibaFactory");

module.exports = async function (deployer, network, addresses) {
  await deployer.deploy(Factory, addresses[0], true);
};
