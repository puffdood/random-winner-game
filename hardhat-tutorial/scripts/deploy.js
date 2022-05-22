const { ethers } = require('hardhat')
require('dotenv').config({ path: '.env' })
require('@nomiclabs/hardhat-etherscan')
const { FEE, VRF_COORDINATOR, LINK_TOKEN, KEY_HASH } = require('../constants')

async function main() {
  const randomWinnerGame = await ethers.getContractFactory('RandomWinnerGame')
  const deployedRandomWinnerGameContract = await randomWinnerGame.deploy(
    VRF_COORDINATOR,
    LINK_TOKEN,
    KEY_HASH,
    FEE,
  )

  await deployedRandomWinnerGameContract.deployed()

  console.log(
    'Verify contract address:',
    deployedRandomWinnerGameContract.address,
  )

  console.log('Sleeping....')
  await sleep(60000)

  await hre.run('verify:verify', {
    address: deployedRandomWinnerGameContract.address,
    constructorArguments: [VRF_COORDINATOR, LINK_TOKEN, KEY_HASH, FEE],
  })
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
