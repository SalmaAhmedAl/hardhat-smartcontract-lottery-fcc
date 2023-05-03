const { network, getNamedAccounts, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

developmentChains.includes(network.name)
    ? describe.skip
    : describe("Raffle Unit Tests", function () {
          let raffleContract, vrfCoordinatorV2Mock
          beforeEach(async () => {
            const {deployer} = await getNamedAccounts()
            await deployments.fixture(["all"]) // Deploys modules with the tags "mocks" and "raffle"
            vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock") // Returns a new connection to the VRFCoordinatorV2Mock contract
            raffleContract = await ethers.getContract("Raffle") // Returns a new connection to the Raffle contract
           
        })

    })