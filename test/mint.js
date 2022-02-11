/* eslint-disable max-len */
/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
/* eslint-disable prefer-destructuring */
const { time, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const exp = require('constants');
const path = require('path');
const { setupAddresses, setupEnvironment, setupMintableToken } = require('./utils');

let adr;
let env;

const scriptName = path.basename(__filename, '.js');

const lerc20InitialSupply = 2000000;

describe(scriptName, () => {
  beforeEach(async () => {
    adr = await setupAddresses();
    env = await setupEnvironment(adr.lssAdmin,
      adr.lssRecoveryAdmin,
      adr.lssPauseAdmin,
      adr.lssInitialHolder,
      adr.lssBackupAdmin);
    lerc20MintableToken = await setupMintableToken(lerc20InitialSupply,
      'Random Token',
      'RAND',
      adr.lerc20InitialHolder,
      adr.lerc20Admin.address,
      adr.lerc20BackupAdmin.address,
      Number(time.duration.days(1)),
      env.lssController.address);

    await env.lssController.connect(adr.lssAdmin).setWhitelist([env.lssReporting.address], true);
    await env.lssController.connect(adr.lssAdmin).setDexList([adr.dexAddress.address], true);
  });

  describe('when minting tokens', () => {
    it('should not revert when called by admin', async () => {
      await expect(
        lerc20MintableToken.connect(adr.lerc20Admin).mint(adr.regularUser1.address, 1000),
      ).to.emit(env.lssController, 'Mint').withArgs(
        lerc20MintableToken.address,
        adr.regularUser1.address,
        1000,
      );

      expect(
        await lerc20MintableToken.balanceOf(adr.regularUser1.address),
      ).to.be.equal(1000);
    });

    it('should revert when called by non admin', async () => {
      await expect(
        lerc20MintableToken.connect(adr.maliciousActor1).mint(adr.maliciousActor1.address, 1000),
      ).to.be.revertedWith('LERC20: Must be admin');

      expect(
        await lerc20MintableToken.balanceOf(adr.maliciousActor1.address),
      ).to.be.equal(0);
    });

    it('should revert when minting to blacklisted', async () => {

      await env.lssToken.connect(adr.lssInitialHolder)
      .transfer(adr.reporter1.address, env.stakingAmount);

      await env.lssToken.connect(adr.reporter1).approve(env.lssReporting.address, env.stakingAmount);

      await env.lssReporting.connect(adr.reporter1).report(lerc20MintableToken.address, adr.maliciousActor1.address);

      await expect(
        lerc20MintableToken.connect(adr.lerc20Admin).mint(adr.maliciousActor1.address, 1000),
      ).to.be.revertedWith('LSS: Cannot mint to blacklisted');

      expect(
        await lerc20MintableToken.balanceOf(adr.maliciousActor1.address),
      ).to.be.equal(0);
    });

    it('should revert when minting from blacklisted contract', async () => {

      await env.lssToken.connect(adr.lssInitialHolder)
      .transfer(adr.reporter1.address, env.stakingAmount);

      await env.lssToken.connect(adr.reporter1).approve(env.lssReporting.address, env.stakingAmount);

      await env.lssReporting.connect(adr.reporter1).report(lerc20MintableToken.address, lerc20MintableToken.address);

      await expect(
        lerc20MintableToken.connect(adr.lerc20Admin).mint(adr.maliciousActor1.address, 1000),
      ).to.be.revertedWith('LSS: Blacklisted cannot mint');

      expect(
        await lerc20MintableToken.balanceOf(adr.maliciousActor1.address),
      ).to.be.equal(0);
    });
  });
});