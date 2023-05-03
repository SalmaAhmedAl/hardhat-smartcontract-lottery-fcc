const { ethers , network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const BASE_FEE= ethers.utils.parseEther("0.25")  //0.25 is premium. It cost 0.25 LINK for reqeust 
const GAS_PRICE_LINK = 1e9 // 1000000000//link per gas //calculated price based on the gas price of the chain

//Chainlink Nodes pay the gas fees to give us a randomness& do external execution
//So they price of request change pased on the price of gas 
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    //const chainId = network.config.chainId
    const args=[BASE_FEE, GAS_PRICE_LINK]

    if (developmentChains.includes(network.name)) {
        log("Local network detected! Deploying mocks...")
        //deploy a mock on vrfcoordinator...
        await deploy("VRFCoordinatorV2Mock", {
          from:deployer,
          log:true,
          args:args,

        })
        log("Mocks deployed!")
        log("----------------------------------------------------------------------------")

        
    }
}

module.exports.tags = ["all", "mocks"]
/**
 * Mock testing involves creating simulated objects or functions that mimic the behavior of real objects or functions within the blockchain system. These simulated objects can then be used to test the functionality of the system without actually executing real transactions or altering the blockchain.
 */