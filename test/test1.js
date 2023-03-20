const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
const BigNumber = require('bignumber.js');
var assert = require('assert');

var Stakeholder = artifacts.require("../contracts/Stakeholder.sol");
var TrustInsure = artifacts.require("../contracts/TrustInsure.sol");
var MedicalCert = artifacts.require("../contracts/MedicalCert.sol");
var Hospital = artifacts.require("../contracts/Hospital.sol");
var Insurance = artifacts.require("../contracts/Insurance.sol");
var InsuranceCompany = artifacts.require("../contracts/InsuranceCompany.sol");
var InsuranceMarket = artifacts.require("../contracts/InsuranceMarket.sol");

const oneEth = new BigNumber(1000000000000000000);

contract('InsuranceMarket', function (accounts){
    before(async () => {
        stakeholderInstance = await Stakeholder.deployed();
        trustInsureInstance = await TrustInsure.deployed();
        medicalCertInstance = await MedicalCert.deployed();
        hospitalInstance = await Hospital.deployed();
        insuranceInstance = await Insurance.deployed();
        insuranceCompanyInstance = await InsuranceCompany.deployed();
        //insuranceMarketInstance = await InsuranceMarket.deployed();
    })

    console.log('testing InsuranceMarket')

    it('Stakeholder Creation', async () => {
        let s1 = await stakeholderInstance.addStakeholder({from: accounts[1]});
        let s2 = await stakeholderInstance.addStakeholder({from: accounts[2]});
        let s3 = await stakeholderInstance.addStakeholder({from: accounts[3]});

        truffleAssert.eventEmitted();
        truffleAssert.eventEmitted();
        truffleAssert.eventEmitted();
    });

    it('InsuranceCompany Creation', async () => {
        let c1 = await insuranceCompanyInstance.add('Life', {from : accounts[9], value: oneEth.dividedBy(100)});
        truffleAssert.eventEmitted();

    });


    it('InsuranceMarket Creation/Listing', async () => {
        await truffleAssert.reverts(insuranceCompanyInstance.addProduct(uint256 insuranceId,uint256 companyId,uint256 amount,insuranceType insType,reasonType reason,uint256 price, {from: accounts[5]}), 'Not Correct Company')
        let p1 = await insuranceCompanyInstance.addProduct(uint256 insuranceId,uint256 companyId,uint256 amount,insuranceType insType,reasonType reason,uint256 price, {from: accounts[9]});
        let p2 = await insuranceCompanyInstance.addProduct(uint256 insuranceId,uint256 companyId,uint256 amount,insuranceType insType,reasonType reason,uint256 price, {from: accounts[9]});

        truffleAssert.eventEmitted();
        truffleAssert.eventEmitted();

        insuranceMarketInstance = await InsuranceMarket.deployed(accounts[9]); //????; why insuCompany address not insuranceCompanyInstance

        truffleAssert.eventEmitted();
    });

    //stakeholder get product listing, will transmit information as event -> console log data
    //format: 
    //At the start of paragraph: all the insurance can be paid yearly or monthly
    // company info - "0 XXXCompany(100): " -> "companyid company_name(company_credit)"
    //under every company has product info
    //prod_arr: ["accident $200, ", "life $20000"] -> "productType: sumAssured"

    it('Get Token', async () => {
        let t1 = await insuranceMarketInstance.getToken('number' , {from: accounts[1]});

        const val = await trustInsureInstance.checkInsure(accounts[1]);
        await assert.strictEqual(val, 'number', 'getToken not working properly')

    });

    it('Test WantToBuy', async () => {
        let b1 = await insuranceMarketInstance.wantToBuy('Life', {from: accounts[1]});

    });

    it('Cannot Accept/Reject/check requests if not Company', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.checkRequests({from: accounts[5]}));

    });

    it('Accept and Created', async () => {
        let l1 = await insuranceMarketInstance.checkRequests({from: accounts[9]});
        let a1 = await insuranceMarketInstance.approve(0, {from: accounts[9]});
        let i1 = await insuranceCompanyInstance.createInsurance(Stakeholder policyOwner,
            Stakeholder lifeAssured,
            Stakeholder payingAccount,
            uint256 insuredAmount,
            insuranceType insType,
            uint256 issueDate,
            reasonType reason,
            uint256 price, {from: accounts[9]});


        truffleAssert.eventEmitted();
    });

    it('Buy Insurance', async () => {
        let b1 = await stakeholderInstance.buyInsurance(0, 0, 0, 1, {from: accounts[1]});

        truffleAssert.eventEmitted();

        let p1bal = await trustInsureInstance.checkInsure();
        let c1bal = await trustInsureInstance.checkInsure();

        await assert.strictEqual(p1bal, 5, 'Buyer no pay');
        await assert.strictEqual(c1bal, 10, 'Token not received');

    });

    it('Company sign?', async () => {

    });


    it('Pay Premium', async () => {
        let prem = await stakeholderInstance.payPremium(0,5,0, {from: accounts[1]});

        truffleAssert.eventEmitted();

        let p1bal1 = await trustInsureInstance.checkInsure();
        let c1bal1 = await trustInsureInstance.checkInsure();

        await assert.strictEqual(p1bal1, 4, 'Buyer no pay');
        await assert.strictEqual(c1bal1, 11, 'Token not received');
    });

    it('Create Hospital', async () => {

        await truffleAssert.reverts(hospitalInstance.register('ic', 'password', {from: accounts[7]}), 'invalid IC');

        let h1 = await hospitalInstance.register('ic', 'password', {from: accounts[7]});
        truffleAssert.eventEmitted();
    });

    it('Wrong Password CreateMC', async () => {
        await truffleAssert.reverts(hospitalInstance.createMC(uint256 memory _hospitalId, string memory _password,
            uint256 hospital, string memory name, string memory NRIC, uint256 sex, 
            uint256 birthdate, string memory race, string memory nationality, 
            certCategory incidentType, uint256 incidentYYYYMMDDHHMM, 
            string memory place, string memory cause, string memory titleNname, string memory institution, {from: accounts[7]}), 'wrong password');


    });

    it('Hospital Create MC', async () => {
        let m1 = await hospitalInstance.createMC(uint256 memory _hospitalId, string memory _password,
            uint256 hospital, string memory name, string memory NRIC, uint256 sex, 
            uint256 birthdate, string memory race, string memory nationality, 
            certCategory incidentType, uint256 incidentYYYYMMDDHHMM, 
            string memory place, string memory cause, string memory titleNname, string memory institution, {from: accounts[7]});

        truffleAssert.eventEmitted();

    });

    it('Fail Claim', async () => {
        await truffleAssert.reverts(stakeholderInstance.claim(0, m1), 'premium not paid');

        await truffleAssert.reverts(stakeholderInstance.claim(0, m1), 'suicide');

        let m2 = await hospitalInstance.createMC(uint256 memory _hospitalId, string memory _password,
            uint256 hospital, string memory name, string memory NRIC, uint256 sex, 
            uint256 birthdate, string memory race, string memory nationality, 
            certCategory incidentType, uint256 incidentYYYYMMDDHHMM, 
            string memory place, string memory cause, string memory titleNname, string memory institution, {from: accounts[7]});
        await truffleAssert.reverts(stakeholderInstance.claim(0, m2), 'MC invalid');

        let m3 = await hospitalInstance.createMC(uint256 memory _hospitalId, string memory _password,
            uint256 hospital, string memory name, string memory NRIC, uint256 sex, 
            uint256 birthdate, string memory race, string memory nationality, 
            certCategory incidentType, uint256 incidentYYYYMMDDHHMM, 
            string memory place, string memory cause, string memory titleNname, string memory institution, {from: accounts[7]});

        await truffleAssert.reverts(stakeholderInstance.claim(0, m3), 'not enough tokens');
    });

    it('Claim', async () => {
        let t2 = insuranceMarketInstance.getToken(1000, {from:accounts[9]})
        let claim = stakeholderInstance.claim(0,m3);

        truffleAssert.eventEmitted('transfer');

        let p1bal2 = await trustInsureInstance.checkInsure();
        let c1bal2 = await trustInsureInstance.checkInsure();

        await assert.strictEqual(p1bal2, 1004, 'Tokens not received');
        await assert.strictEqual(c1bal2, 11, 'Token not paid');
        
    });

    it('Withdraw to Ether', async () => {
        let AccountBal = new BigNumber(await web3.eth.getBalance(accounts[1]));

        let w1 = insuranceMarketInstance.withdraw(1000, {from: accounts[1]});

        let newAccountBal = new BigNumber(await web3.eth.getBalance(accounts[1]));

        await assert(newAccountBal.isGreaterThan(AccountBal), "Incorrect Return Amt");
    });
})