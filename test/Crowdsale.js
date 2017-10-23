const web3 = global.web3;
const Crowdsale = artifacts.require('./Crowdsale.sol')

contract('Crowdsale', function ([owner, donor]) {
    let crowdsale;
    beforeEach('setup contract for each test', async function () {
        crowdsale = await Crowdsale.new(owner);
    })

    it('has an owner', async function () {
        assert.equal(await crowdsale.owner(), owner);
    })

    it('is able to accept funds', async function () {
          await crowdsale.sendTransaction({ value: 10*1e+18, from: donor });

          const crowdsaleAddress = await crowdsale.address;
          assert.equal(web3.eth.getBalance(crowdsaleAddress).toNumber(), 10*1e+18);
        })

    it('is able to accept refunds', async function () {
          let addError;
          await crowdsale.sendTransaction({ value: 10*1e+18, from: donor });
          try {
                await crowdsale.refund();
              } catch (error) {
                addError = error;
              }
          assert.notEqual(addError, undefined, 'Error must be thrown');
    })

    it('is able to accept refunds', async function () {
              let addError;
              await crowdsale.sendTransaction({ value: 10*1e+18, from: donor });
              try {
                    await crowdsale.refund();
                  } catch (error) {
                    addError = error;
                  }
              assert.notEqual(addError, undefined, 'Error must be thrown');
        })
})