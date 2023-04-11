const ERC20 = artifacts.require("ERC20");
const MedicalCert = artifacts.require("MedicalCertificate");
const TrustInsure = artifacts.require("TrustInsure");
const Hospital = artifacts.require("Hospital");
const InsuranceCompany = artifacts.require("InsuranceCompany");
const Stakeholder = artifacts.require("Stakeholder");
const InsuranceMarket = artifacts.require("InsuranceMarket");
const Insurance = artifacts.require("Insurance");


module.exports = (deployer, network, accounts) => {
  deployer
    .deploy(TrustInsure)
    .then(function () {
      return deployer.deploy(Hospital);
    })
    .then(function() {
      return deployer.deploy(Insurance);
    })
    .then(function () {
      return deployer.deploy(InsuranceCompany, Hospital.address,TrustInsure.address);
    })
    .then(function () {
      return deployer.deploy(Stakeholder, InsuranceCompany.address, Hospital.address, TrustInsure.address,);
    })
    .then(function () {
      return deployer.deploy(InsuranceMarket, InsuranceCompany.address, Stakeholder.address, TrustInsure.address);
    });
};
