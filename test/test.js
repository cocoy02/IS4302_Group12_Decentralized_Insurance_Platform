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
        medicalCertInstance = await MedicalCert.deployed();
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
        assert.strictEqual(name1, 'Bob Wong', 'Stakeholder Created Wrongly');
        assert.strictEqual(name2, 'Tom Wong', 'Stakeholder Created Wrongly');
        assert.strictEqual(name3, 'May Wong', 'Stakeholder Created Wrongly');
    });

    it('InsuranceCompany Creation', async () => {
        await truffleAssert.reverts(insuranceCompanyInstance.registerCompany('Lion', {from : accounts[9]}));
        let c1 = await insuranceCompanyInstance.registerCompany('Lion', {from : accounts[9], value: oneEth.dividedBy(10)});
        const cname = await insuranceCompanyInstance.getName(1);
        const cowner = await insuranceCompanyInstance.getOwner(1);
        assert.strictEqual(cname, 'Lion', 'Company name wrong');
        assert.strictEqual(cowner, accounts[9], 'Company owner wrong');


    });

    it('InsuranceMarket Creation/Listing without token', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.publishProduct(1, "life", 5, 10, {from: accounts[9]}), 'Do not have enough TrustInsure to publish products!');
    });

    it('Get TrustInsure', async () => {

        let t1 = await trustInsureInstance.getInsure({from : accounts[9], value: 2* oneEth});

        const lionbal = await trustInsureInstance.checkInsure(accounts[9]);
        assert.strictEqual(lionbal.toNumber(),205, 'getToken not working properly');

    });

    it('InsuranceMarket Creation/Listing', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.publishProduct(1, "life", 5, 10, {from: accounts[5]}), 'You are not allowed to list the product!');
        await truffleAssert.reverts(insuranceMarketInstance.publishProduct(1, "what", 5, 10, {from: accounts[9]}), "You should input valid product type, eg. accident or life!");
        let p1 = await insuranceMarketInstance.publishProduct(1, "life", 5, 20, {from: accounts[9]});
        await truffleAssert.eventEmitted(p1, 'productPublished');

        let p2 = await insuranceMarketInstance.publishProduct(1, "accident", 5, 10, {from: accounts[9]});
        await truffleAssert.eventEmitted(p2, 'productPublished');

        let lionbal1 = await trustInsureInstance.checkInsure(accounts[9]);
        let marketbal = await trustInsureInstance.checkInsure(insuranceMarketInstance.address);
 
        assert.strictEqual(lionbal1.toNumber(), 203, 'publish commission not paid');
        assert.strictEqual(marketbal.toNumber(), 2, 'publish commission not received');
        
    });

    it('Test WantToBuy', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.wantToBuy(2, 1, 1, '91112222', {from: accounts[1]}), 'Invalid stakeholder id!', 'Use correct stakeholder');
        await truffleAssert.reverts(insuranceMarketInstance.wantToBuy(1, 1, 1, '911122222', {from: accounts[1]}), 'Invalid length of phone number!', 'Use correct number');

        let b1 = await insuranceMarketInstance.wantToBuy(1, 1, 1, '91112222', {from: accounts[1]});
        truffleAssert.eventEmitted(b1, 'requestSucceed')

    });

    it('Accept and Created', async () => {

        let si1 = await insuranceCompanyInstance.createStakeholderInfo(1,2,3,2, {from: accounts[9]});
        

        await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 2, 5, 20, Insurance.insuranceType.life, 20200401, 20490401, {from: accounts[9]}), "Invalid company id!");
        await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 20200401, 20490401, {from: accounts[7]}), "You are not the owner");
        await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 2023040, 20490401, {from: accounts[9]}), "Invalid issue date!");
        await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 20230401, 2049040, {from: accounts[9]}), 'Invalid expiry date!');
        await truffleAssert.reverts(insuranceCompanyInstance.createInsurance(1, 1, 5, 20, Insurance.insuranceType.life, 20230401, 20230329, {from: accounts[9]}), 'Invalid expiry date!');


        let i1 = await insuranceCompanyInstance.createInsurance(1, 1, 5, 210, Insurance.insuranceType.life, 20200401, 20490401, {from: accounts[9]});

        truffleAssert.eventEmitted(i1, 'create');

        let numIns = await insuranceCompanyInstance.getNumberOfInsurance();
        assert.strictEqual(numIns.toNumber(), 1, 'Insurance creation incorrect');

        let solve = await insuranceCompanyInstance.solveRequest(1,1,1, {from:accounts[9]});
        truffleAssert.eventEmitted(solve, 'requestSolve');
        let status2, approved = await insuranceCompanyInstance.checkRequestsFromStakeholder(1,1); 
        assert.strictEqual(status2, InsuranceCompany.requestStatus.unapproved, 'Wrong status');


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

        assert.strictEqual(hosId.toNumber(), 1, 'Hospital creation incorrect');

    });

    it('MC Request', async () => {
        let m1 = await stakeholderInstance.requestMC(1, 'Bob Wang', 'S1234567A', {from: accounts[1]});
        const numMCReq = await hospitalInstance.getNumOfReqs();

        assert.strictEqual(numMCReq.toNumber(), 1, 'requestMC incorrect');


        let pi1 = await hospitalInstance.createPersonalInfo(1, 'password', 'Bob Wang', 'S1234567A', 'Male', '19721023', 'Chinese Singaporean', {from: accounts[9]});
        const numP = await hospitalInstance.getNumOfPeople();

        assert.strictEqual(numP.toNumber(), 1, 'createPersonalInfo incorrect');

        let mc1 = await hospitalInstance.addMC(1, 'password', 1, 2, '202304061400', 'Strange', {from: accounts[9]});
        const numMC = await hospitalInstance.getHospitalCounter();

        assert.strictEqual(numMC.toNumber(),1 ,'addMC incorrect');

        let solve1 = await hospitalInstance.solveRequest(1, 'password', 1, 1, 1, {from: accounts[9]});
        
        await truffleAssert.eventEmitted(solve1, 'requestSolve');

    });    

    it('Wrong Password CreateMC', async () => {
        await truffleAssert.reverts(hospitalInstance.createPersonalInfo(1, 'passwordo', 'Tom Wang', 'T0012345A', 'Male', '20000202', 'Chinese Singaporean', {from: accounts[9]}), 'Wrong password!');
        await truffleAssert.reverts(hospitalInstance.addMC(1, 'passwordo', 1, 0, '202304061400', 'Strange', {from: accounts[9]}), 'Wrong password!');

        await truffleAssert.reverts(hospitalInstance.createPersonalInfo(11, 'password', 'Tom Wang', 'T0012345A', 'Male', '20000202', 'Chinese Singaporean', {from: accounts[9]}), 'Invalid hospital id');
        await truffleAssert.reverts(hospitalInstance.addMC(11, 'password', 1, 0, '202304061400', 'Strange', {from: accounts[9]}), 'Invalid hospital id');


    });

    it('Check MC status', async () => {
        let check1 = await stakeholderInstance.checkMCRequests(1, 1, 1, {from: accounts[1]});
        assert.strictEqual(check1.toNumber(), 1, 'MCRequest incorrect');


    });

    it('Fail Claim', async () => {
        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 1, 'Bob Wang', 'S1234567A', {from: accounts[1]}), "Invalid beneficiary!");

        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 2, 'Bob Wang', 'S1234567A', {from: accounts[2]}), "Stakeholder haven't paid the insurance");

        await truffleAssert.reverts(stakeholderInstance.payPremium(1,2,1, {from: accounts[1]}), "From doesn't have enough balance");

        let gettoken = await trustInsureInstance.getInsure({from: accounts[1], value: oneEth.dividedBy(10)});
        let prem = await stakeholderInstance.payPremium(1,2,1, {from: accounts[1]});

        let p1bal1 = await trustInsureInstance.checkInsure(accounts[1]);
        let c1bal1 = await trustInsureInstance.checkInsure(accounts[9]);

        assert.strictEqual(p1bal1.toNumber(), 8, 'Buyer no pay'); // 10-2
        assert.strictEqual(c1bal1.toNumber(), 205, 'Token not received'); //203+2       
        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 1, 2, 'Bob Wang', 'S1234567A', {from: accounts[2]}), "Stakeholder haven't paid the insurance");

        let prem2 = await stakeholderInstance.payPremium(1,3,1, {from: accounts[1]});
      
        let m2 = await hospitalInstance.addMC(1, 'password', 1, 1, '202304061400', 'Strange', {from: accounts[9]});
        await truffleAssert.reverts(stakeholderInstance.claimInsurance(1, 1, 2, 2, 'Bob Wang', 'S1234567A', {from: accounts[2]}), 'not enough TrustInsure to pay!');
    });

    it('Claim', async () => {
        let gettoken2 = await trustInsureInstance.getInsure({from: accounts[9], value: oneEth.dividedBy(10)});
        let claim1 = await stakeholderInstance.claimInsurance(1, 1, 1, 2, 'Bob Wang', 'S1234567A', {from: accounts[2]});

        let p1bal2 = await trustInsureInstance.checkInsure(accounts[2]);
        let c1bal2 = await trustInsureInstance.checkInsure(accounts[9]);

        assert.strictEqual(p1bal2.toNumber(), 210, 'Tokens not received');  // 0 + 210
        assert.strictEqual(c1bal2.toNumber(), 8, 'Token not paid'); // 205 + 3 + 10 - 210
        
    });
    
    it('Withdraw Product', async () => {
        await truffleAssert.reverts(insuranceMarketInstance.withdrawProduct(1,1, {from: accounts[5]}), "You are not allowed to list the product!");
        await truffleAssert.reverts(insuranceMarketInstance.withdrawProduct(1,3, {from: accounts[9]}), "Please ensure the input product id is valid!");

        let w1 = await insuranceMarketInstance.withdrawProduct(1,1, {from: accounts[9]});

        truffleAssert.eventEmitted(w1, 'productWithdrawedSucceed');

        let m1bal3 = await trustInsureInstance.checkInsure(insuranceMarketInstance.address);
        let c1bal3 = await trustInsureInstance.checkInsure(accounts[9]);

        assert.strictEqual(m1bal3.toNumber(), 3, 'Tokens not received'); //2+1
        assert.strictEqual(c1bal3.toNumber(), 7, 'Token not paid'); //8-1
        
    });

    it('Reject insurance request', async () => {
        let b2 = await insuranceMarketInstance.wantToBuy(2, 1, 2, '91112222', {from: accounts[2]});

        truffleAssert.eventEmitted(b2, 'requestSucceed');

        await truffleAssert.reverts(insuranceCompanyInstance.rejectRequest(0, 1, {from: accounts[9]}), "Input valid requestId!");
        await truffleAssert.reverts(insuranceCompanyInstance.rejectRequest(3, 1, {from: accounts[9]}), "Invalid request id!");
        let r1 = await insuranceCompanyInstance.rejectRequest(2, 1, {from: accounts[9]});

        truffleAssert.eventEmitted(r1, 'requestReject');
        
    });

    it('Hospital change password and president', async () => {
        await truffleAssert.reverts(hospitalInstance.changePassword(1, 'password', 'changepass', {from: accounts[9]}), "Unauthorized!"); //validpassword
        await truffleAssert.reverts(hospitalInstance.changePassword(1, 'passwordo', 'changepass', {from: accounts[7]}), "Wrong password!"); //owneronly

        let cp1 = await hospitalInstance.changePassword(1, 'password', 'changepass', {from: accounts[7]});

        await truffleAssert.reverts(hospitalInstance.changePresident(1, 'password', 'S7788991Z', {from: accounts[8]}), "Wrong password!"); //validpassword

        let cp2 = await hospitalInstance.changePresident(1, 'changepass', 'S7788991Z', {from: accounts[8]});
        truffleAssert.eventEmitted(cp2, 'presidentChanged');
    
    });
    
});