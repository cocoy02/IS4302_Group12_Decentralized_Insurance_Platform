# IS4302_Group12_Decentralized_Insurance_Platform

## Motivation
Currently, the insurance market is offline and buyers have to manually research and compare various insurance contracts from different insurance companies by themselves. This is inefficient and troublesome for buyers. As for insurance companies, for each claim, they currently have to manually verify the authenticity of medical certificates, before releasing the claim amount to the insurance buyer. This is inefficient for the company if there is a large volume of claims waiting to be processed by the company, as the company might lack manpower to handle the verification of claims hence decreasing the efficiency of verifying and releasing claims to buyers. Manual verification will take a lot of time on sourcing information and might also involve human error, resulting in inaccuracy of claim verification. 

To address the above issues, our group will therefore aim to streamline the process of buying and claiming insurances for both insurance companies and insurance buyers, by creating an Insurance market on blockchain which consists of insurance companies, stakeholders including policy owners, beneficiaries and life assured, and hospitals that give out medical certificates. Through this project, we aim to implement the possibility of an insurance market on blockchain, in order to provide an idea for the insurance market to go onto the blockchain eventually. 




## Getting Started
This project mainly uses Solidity Language for implementing smart contracts. Upon cloning this repository into your local machine, start Ganache app on local machien and run the following command in terminal.

```bash
truffle compile
```
```bash
truffle migrate
```
```bash
truffle test
```

## Files
The following table contains a brief description of the files and folders in this repository.
| Folder / File | Description |
| - | - |
| **contracts/Datetime.sol** | Datetime library |
| **contracts/ERC20.sol** | Fungible tokens created using Ethereum blockchain |
| **contracts/TrustInsure.sol** | Native token curated for this project |
| **contracts/Hospital.sol** | Representing registered hospitals that issue medical certificates|
| **contracts/Insurance.sol** | Insurance contract |
| **contracts/InsuranceCompany.sol** | Representing insurance companies registered on the chain |
| **contracts/InsuranceMarket.sol** | Market for transactions of insurances |
| **contracts/MedicalCert.sol** | Medical certificate contract |
| **contracts/Stakeholder.sol** | Representing stakeholder that buys contract|
| **contracts/Migration.sol** | Admin file|
| **test/test.js** | Test cases for smart contracts |
| **migrations/1_initial_migration.js** | Initial migration |
| **migrations/2_deploy_contracts.js** | Deploy contracts |
