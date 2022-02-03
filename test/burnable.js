/* eslint-disable max-len */
/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
/* eslint-disable prefer-destructuring */
const { time, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const path = require('path');
const { setupAddresses, setupEnvironment, setupBurnableToken } = require('./utils');

let adr;
let env;

const scriptName = path.basename(__filename, '.js');

const lerc20InitialSupply = 2000000;

describe.only(scriptName, () => {
  beforeEach(async () => {
    adr = await setupAddresses();
    env = await setupEnvironment(adr.lssAdmin,
      adr.lssRecoveryAdmin,
      adr.lssPauseAdmin,
      adr.lssInitialHolder,
      adr.lssBackupAdmin);
    lerc20BurnableToken = await setupBurnableToken(lerc20InitialSupply,
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

  describe('when burning tokens', () => {
    it('it should burn expected amount', async () => {
      
      expect(
        await lerc20BurnableToken.balanceOf(adr.lerc20InitialHolder.address),
      ).to.be.equal(lerc20InitialSupply);

      await expect(
        lerc20BurnableToken.connect(adr.lerc20InitialHolder).burn(10000),
      ).to.emit(env.lssController, 'Burn').withArgs(
        lerc20BurnableToken.address,
        adr.lerc20InitialHolder.address,
        10000,
      );

      expect(
        await lerc20BurnableToken.balanceOf(adr.lerc20InitialHolder.address),
      ).to.be.equal(lerc20InitialSupply - 10000);
    });
  });

  describe('when burning tokens From', () => {
    it('it should burn expected amount', async () => {
      
      await lerc20BurnableToken.connect(adr.lerc20InitialHolder).transfer(adr.regularUser1.address, 20000);
      await lerc20BurnableToken.connect(adr.regularUser1).approve(adr.lerc20InitialHolder.address, 10000);

      expect(
        await lerc20BurnableToken.balanceOf(adr.regularUser1.address),
      ).to.be.equal(20000);

      await expect(
        lerc20BurnableToken.connect(adr.lerc20InitialHolder).burnFrom(adr.regularUser1.address, 10000),
      ).to.emit(env.lssController, 'Burn').withArgs(
        lerc20BurnableToken.address,
        adr.regularUser1.address,
        10000,
      );

      expect(
        await lerc20BurnableToken.balanceOf(adr.regularUser1.address),
      ).to.be.equal(10000);
    });
  });
});