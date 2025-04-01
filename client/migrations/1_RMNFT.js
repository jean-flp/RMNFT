const RMNFT = artifacts.require("RMNFT");

module.exports = function (deployer) {
  deployer.deploy(RMNFT);
};
