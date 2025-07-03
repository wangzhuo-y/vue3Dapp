// eslint-disable-next-line @typescript-eslint/no-require-imports
const { ethers } = require('hardhat')

async function main() {
  const [account1, account2] = await ethers.getSigners()

  console.log(account1.address, account2.address)

  const fundMeFactory = await ethers.getContractFactory('FundMe')
  console.log('合约中正在部署')
  const fundMe = await fundMeFactory.connect(account1).deploy(1 * 60 * 60)
  await fundMe.waitForDeployment()
  console.log('合约已部署完成 合约地址为:', await fundMe.getAddress())
}

main()
  .then()
  .catch((error) => {
    console.log(error)
    process.exit(1)
  })
