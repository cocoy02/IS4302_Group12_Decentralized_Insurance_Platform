const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
const BigNumber = require('bignumber.js');
var assert = require('assert');

var Stakeholder = artifacts.require("../contracts/Stakeholder.sol");
var TrustInsure = artifacts.require("../contracts/TrustInsure.sol");
var MedicalCert = artifacts.require("MedicalCertificate");
var Hospital = artifacts.require("../contracts/Hospital.sol");
var Insurance = artifacts.require("../contracts/Insurance.sol");
var InsuranceCompany = artifacts.require("../contracts/InsuranceCompany.sol");
var InsuranceMarket = artifacts.require("../contracts/InsuranceMarket.sol");

const oneEth = new BigNumber(1000000000000000000);

contract('InsuranceMarket', function (accounts){
    before(async () => {
        trustInsureInstance = await TrustInsure.deployed();
        //medicalCertInstance = await MedicalCert.deployed();
        hospitalInstance = await Hospital.deployed();
        insuranceInstance = await Insurance.deployed();
        insuranceCompanyInstance = await InsuranceCompany.deployed();
        stakeholderInstance = await Stakeholder.deployed();
        insuranceMarketInstance = await InsuranceMarket.deployed();
    })

    console.log('testing InsuranceMarket')

    it('Stakeholder Creation', async () => {
        let s1 = await stakeholderInstance.addStakeholder('Bob Wong', 'S1234567A',{from: accounts[1]});
        let s2 = await stakeholderInstance.addStakeholder('Tom Wong', 'T0012345A', {from: accounts[2]});
        let s3 = await stakeholderInstance.addStakeholder('May Wong', 'T0234567A', {from: accounts[3]});
        const name1 = await stakeholderInstance.getStakeholderName(1, {from: accounts[1]});
        const name2 = await stakeholderInstance.getStakeholderName(2, {from: accounts[2]});
        const name3 = await stakeholderInstance.getStakeholderName(3, {from: accounts[3]});
        await assert.strictEqual(name1, 'Bob Wong', 'Stakeholder Created Wrongly');
        await assert.strictEqual(name2, 'Tom Wong', 'Stakeholder Created Wrongly');
        await assert.strictEqual(name3, 'May Wong', 'Stakeholder Created Wrongly');
    });

    it('InsuranceCompany Creation', async () => {
        let c1 = await insuranceCompanyInstance.registerCompany('Lion', {from : accounts[9], value: oneEth.dividedBy(10)});
        const cname = await insuranceCompanyInstance.getName(1);
        const cowner = await insuranceCompanyInstance.getOwner(1);
        await assert.strictEqual(cname, 'Lion', 'Company name wrong');
        await assert.strictEqual(cowner, accounts[9], 'Company owner wrong');


    });

    it('InsuranceMarket Creation/Listing without token', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.publishProduct(1, "life", 5, 10, {from: accounts[9]}), 'Do not have enought TrustInsure to publish products!');
    });

    it('Get TrustInsure', async () => {
        // let t1 = await trustInsureInstance.getInsure({from : accounts[9], value: oneEth.dividedBy(10)});
        let t1 = await trustInsureInstance.getInsure({from : accounts[9], value: 2* oneEth});
        //await truffleAssert.eventEmitted(t1, 'ERC20.Mint');
        let lionbal = await trustInsureInstance.checkInsure(accounts[9]);
        // assert.strictEqual(lionbal.toNumber(),10, 'getToken not working properly');
        assert.strictEqual(lionbal.toNumber(),205, 'getToken not working properly');

    });

    it('InsuranceMarket Creation/Listing', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.publishProduct(1, "life", 5, 10, {from: accounts[5]}), 'You are not allowed to list the product!');
        let p1 = await insuranceMarketInstance.publishProduct(1, "life", 5, 20, {from: accounts[9]});
        await truffleAssert.eventEmitted(p1, 'productPublished');

        let p2 = await insuranceMarketInstance.publishProduct(1, "accident", 5, 10, {from: accounts[9]});
        await truffleAssert.eventEmitted(p2, 'productPublished');

        //const pid, pprem, passured, ptype = insuranceCompanyInstance.getProductInfor()
        
    });

    //stakeholder get product listing, will transmit information as event -> console log data
    //format: 
    //At the start of paragraph: all the insurance can be paid yearly or monthly
    // company info - "0 XXXCompany(100): " -> "companyid company_name(company_credit)"
    //under every company has product info
    //prod_arr: ["accident $200, ", "life $20000"] -> "productType: sumAssured"
    //remember to convert enum productType into string

    it('Test WantToBuy', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.wantToBuy(2, 1, 1, '91112222', {from: accounts[1]}), 'Invalid stakeholder id!', 'Use correct stakeholder');
        await truffleAssert.reverts(insuranceMarketInstance.wantToBuy(1, 1, 1, '911122222', {from: accounts[1]}), 'Invalid length of phone number!', 'Use correct number');

        let b1 = await insuranceMarketInstance.wantToBuy(1, 1, 1, '91112222', {from: accounts[1]});
        truffleAssert.eventEmitted(b1, 'requestSucceed')

        //let status1, empty = await insuranceCompanyInstance.checkRequestsFromStakeholder(1,1); frontend


        //debug
//        const status1 = await insuranceCompanyInstance.companies[1].requestLists[0].status;
//        const empty = await insuranceCompanyInstance.companies[1].requestLists[0].reqId; 
//        await assert.strictEqual(status1, InsuranceCompany.requestStatus.pending, 'Wrong status');
//        await assert.strictEqual(empty, 0, 'Wrong request id'); 

    });

//    it('Cannot Accept/Reject/check requests if not Company', async () => {  frontend
//        await truffleAssert.reverts(insuranceMarketInstance.checkRequests({from: accounts[5]}));

//    });

    it('Accept and Created', async () => {

        let si1 = await insuranceCompanyInstance.createStakeholderInfo(1,2,3,2, {from: accounts[9]});
        
        //let l1 = await insuranceMarketInstance.checkRequests({from: accounts[9]}); frontend
        await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 2, 5, 20, Insurance.insuranceType.life, 20200401, 20490401, {from: accounts[9]}), "Invalid company id!");
        await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 20200401, 20490401, {from: accounts[7]}), "You are not the owner");
       await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 2023040, 20490401, {from: accounts[9]}), "Invalid issue date!");
       await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 20230401, 2049040, {from: accounts[9]}), 'Invalid expiry date!');
       await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 20230401, 20230329, {from: accounts[9]}), 'Invalid expiry date!');
        // let a1 = await insuranceMarketInstance.approve(0, {from: accounts[9]}); not tested

        let i1 = await insuranceCompanyInstance.createInsurance(1, 1, 5, 10, Insurance.insuranceType.life, 20200401, 20490401, {from: accounts[9]});

        truffleAssert.eventEmitted(i1, 'create');

        let numIns = await insuranceCompanyInstance.getNumberOfInsurance();
        assert.equal(numIns.toNumber(), 1, 'Insurance creation incorrect');

        let solve = await insuranceCompanyInstance.solveRequest(1,1,1, {from:accounts[9]});
        truffleAssert.eventEmitted(solve, 'requestSolve');
        let status2, approved = await insuranceCompanyInstance.checkRequestsFromStakeholder(1,1); 
        assert.strictEqual(status2, InsuranceCompany.requestStatus.unapproved, 'Wrong status');
        // assert.strictEqual(approved.toNumber(), 1, 'Wrong request id'); 

    });

    it('Buy Insurance', async () => {
        let b1 = await stakeholderInstance.signInsurance(1, 1, 1, 'bobwang', {from: accounts[1]});
        truffleAssert.eventEmitted(b1,'signInsure');
    });


    it('Create Hospital', async () => {

        await truffleAssert.reverts(hospitalInstance.register('ic', 'password', {from: accounts[7], value: oneEth.dividedBy(10)}), 'invalid NRIC number');

        let h1 = await hospitalInstance.register('S7654321Z', 'password', {from: accounts[7],value: oneEth.dividedBy(10)});
        truffleAssert.eventEmitted(h1,'registered');

        const hosId = await hospitalInstance.getHospitalId(accounts[7]);

        await assert.strictEqual(hosId.toNumber(), 1, 'Hospital creation incorrect');

    });

    it('MC Request', async () => {
        let m1 = await stakeholderInstance.requestMC(1, 'Bob Wang', 'S1234567A', {from: accounts[1]});
        const numMCReq = await hospitalInstance.getNumOfReqs();

        await assert.strictEqual(numMCReq.toNumber(), 1, 'requestMC incorrect');
        // hospital checkmcrequest


        let pi1 = await hospitalInstance.createPersonalInfo(1, 'password', 'Bob Wang', 'S1234567A', 'Male', '19721023', 'Chinese Singaporean', {from: accounts[9]});
        const numP = await hospitalInstance.getNumOfPeople();

        await assert.strictEqual(numP.toNumber(), 1, 'createPersonalInfo incorrect');

        let mc1 = await hospitalInstance.addMC(1, 'password', 1, 2, '202304061400', 'Strange', {from: accounts[9]});
        const numMC = await hospitalInstance.getHospitalCounter();

        await assert.strictEqual(numMC.toNumber(),1 ,'addMC incorrect');

        let solve1 = await hospitalInstance.solveRequest(1, 'password', 1, 1, 1, {from: accounts[9]});
        
        await truffleAssert.eventEmitted(solve1, 'requestSolve');

    });    

    it('Wrong Password CreateMC', async () => {
        await truffleAssert.reverts(hospitalInstance.createPersonalInfo(1, 'passwordo', 'Tom Wang', 'T0012345A', 'Male', 20000202, 'Chinese Singaporean', {from: accounts[9]}), 'Wrong password!');
        await truffleAssert.reverts(hospitalInstance.addMC(1, 'passwordo', 1, MedicalCert.certCategory.incident, 202304061400, 'Strange', {from: accounts[9]}), 'Wrong password!');

        await truffleAssert.reverts(hospitalInstance.createPersonalInfo(1, 'password', 'Tom Wang', 'T0012345A', 'Male', 20000202, 'Chinese Singaporean', {from: accounts[8]}), 'Invalid hospital id');
        await truffleAssert.reverts(hospitalInstance.addMC(1, 'password', 1, MedicalCert.certCategory.incident, 202304061400, 'Strange', {from: accounts[8]}), 'Invalid hospital id');


    });

    it('Check MC status', async () => {
        let check1 = await stakeholderInstance.checkMCRequests(1, 1, 1, {from: accounts[1]});
        await assert.strictEqual(check1.toNumber(), 1, 'MCRequest incorrect');


    });

    it('Fail Claim', async () => {
        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 1, 'Bob Wang', 'S1234567A'), "Invalid Beneficiary");

        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 2, 'Bob Wang', 'S1234567A'), "Stakeholder haven't paid the insurance");

        await truffleAssert.reverts(stakeholderInstance.payPremium(1,2,1, {from: accounts[1]}), 'Not allowed to spend this much');

        truffleAssert.eventEmitted();

        let gettoken = await trustInsureInstance.getInsure({from: accounts[1], value: oneEth.dividedBy(10)});
        let prem = await stakeholderInstance.payPremium(1,2,1, {from: accounts[1]});

        let p1bal1 = await trustInsureInstance.checkInsure(accounts[1].address);
        let c1bal1 = await trustInsureInstance.checkInsure(accounts[9].address);

        await assert.strictEqual(p1bal1.toNumber(), 3, 'Buyer no pay');
        await assert.strictEqual(c1bal1.toNumber(), 10, 'Token not received');        
        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 2, 'Bob Wang', 'S1234567A'), "Stakeholder haven't paid the insurance");

        let prem2 = await stakeholderInstance.payPremium(1,3,1, {from: accounts[1]});
        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 2, 'Bob Wang', 'S1234567A'), 'If suicide cannot claim within 2 years');

        let m2 = await hospitalInstance.addMC(1, 'password', 1, MedicalCert.certCategory.death, 202304061400, 'Strange', {from: accounts[9]});
        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 2, 'Bob Wang', 'S1234567A'), 'Not enough TrustInsure');
    });

//    it('Pay Premium', async () => {
//        let prem = await stakeholderInstance.payPremium(0,5,0, {from: accounts[1]});

//        truffleAssert.eventEmitted();

//        let p1bal1 = await trustInsureInstance.checkInsure();
//        let c1bal1 = await trustInsureInstance.checkInsure();

//        await assert.strictEqual(p1bal1, 3, 'Buyer no pay');
//        await assert.strictEqual(c1bal1, 10, 'Token not received');
//    });

    it('Claim', async () => {
        let gettoken2 = trustInsureInstance.getInsure({from: accounts[9], value: oneEth});
        let claim1 = stakeholderInstance.claimInsurance(1, 1, 2, 1, 'Bob Wang', 'S1234567A', {from: accounts[2]});

        truffleAssert.eventEmitted(claim1, 'transfer');

        let p1bal2 = await trustInsureInstance.checkInsure();
        let c1bal2 = await trustInsureInstance.checkInsure();

        await assert.strictEqual(p1bal2.toNumber(), 1004, 'Tokens not received');
        await assert.strictEqual(c1bal2.toNumber(), 11, 'Token not paid');
        
    });

//    it('Withdraw to Ether', async () => {
//        let AccountBal = new BigNumber(await web3.eth.getBalance(accounts[1]));

//        let w1 = insuranceMarketInstance.withdraw(1000, {from: accounts[1]});

//        let newAccountBal = new BigNumber(await web3.eth.getBalance(accounts[1]));

//        await assert(newAccountBal.isGreaterThan(AccountBal), "Incorrect Return Amt");
//    });
});