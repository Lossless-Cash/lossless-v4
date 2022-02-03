/* eslint-disable max-len */
/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
/* eslint-disable prefer-destructuring */
const { time, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const path = require('path');
const { setupAddresses, setupEnvironment, setupToken } = require('../../utils');

let adr;
let env;

const scriptName = path.basename(__filename, '.js');

describe(scriptName, () => {
  beforeEach(async () => {
    adr = await setupAddresses();
    env = await setupEnvironment(adr.lssAdmin,
      adr.lssRecoveryAdmin,
      adr.lssPauseAdmin,
      adr.lssInitialHolder,
      adr.lssBackupAdmin);
  });

  describe('when setting the Reporter Reward', () => {
    it('should revert when not admin', async () => {
      await expect(
        env.lssReporting.connect(adr.regularUser1).setReporterReward(1),
      ).to.be.revertedWith('LSS: Must be admin');
    });

    it('should not revert when equal 0 percent', async () => {
      await expect(
        env.lssReporting.connect(adr.lssAdmin).setReporterReward(0),
      ).to.not.be.reverted;
    });

    it('should revert when more than 100 percent', async () => {
      await expect(
        env.lssReporting.connect(adr.lssAdmin).setReporterReward(103),
      ).to.be.revertedWith('LSS: Total exceed 100');
    });

    it('should revert when if total rewards exceed 100 percent', async () => {
      await expect(
        env.lssReporting.connect(adr.lssAdmin).setReporterReward(100),
      ).to.be.revertedWith('LSS: Total exceed 100');
    });

    it('should not revert when sent by admin', async () => {
      await expect(
        env.lssReporting.connect(adr.lssAdmin).setReporterReward(3),
      ).to.not.be.reverted;

      expect(
        await env.lssReporting.reporterReward(),
      ).to.be.equal(3);
    });
  });

  describe('when other rewards are set', () => {
    beforeEach(async () => {
      await env.lssReporting.connect(adr.lssAdmin).setLosslessReward(50);
      await env.lssReporting.connect(adr.lssAdmin).setStakersReward(45);
      await env.lssReporting.connect(adr.lssAdmin).setCommitteeReward(1);
    });

    it('should revert when going over 100 percent rewards', async () => {
      await expect(
        env.lssReporting.connect(adr.lssAdmin).setReporterReward(5),
      ).to.be.revertedWith('LSS: Total exceed 100');
    });

    it('should not revert when staying under 100 percent rewards', async () => {
      await expect(
        env.lssReporting.connect(adr.lssAdmin).setReporterReward(4),
      ).to.not.be.reverted;
    });
  });
});
