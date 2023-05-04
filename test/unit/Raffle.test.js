const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Raffle Unit Tests", function () {
          let raffle ,vrfCoordinatorV2Mock
          beforeEach(async () => {
           const {deployer} = await getNamedAccounts()
            await deployments.fixture(["all"]) // Deploys modules with the tags "mocks" and "raffle"
            raffle = await ethers.getContract("Raffle", deployer) // Returns a new connection to the Raffle contract
            vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
           
        })

        describe("constructor", function () {
            it("initializes the raffle correctly", async () => {
                // Ideally, we'd separate these out so that only 1 assert per "it" block
                // And ideally, we'd make this check everything
                const raffleState = (await raffle.getRaffleState()).toString()
                const interval = await raffle.getInterval()
                // Comparisons for Raffle initialization:
                assert.equal(raffleState, "0")
                assert.equal(
                    interval.toString(),
                    networkConfig[network.config.chainId]["keepersUpdateInterval"]
                )
            })
        })
      


    })