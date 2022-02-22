const main = async () => {
  const domainContractFactory = await hre.ethers.getContractFactory('Domains');
  const domainContract = await domainContractFactory.deploy('dance');
  await domainContract.deployed();

  console.log('Contract deployed to:', domainContract.address);

  let txn = await domainContract.register('readyto', {
    value: hre.ethers.utils.parseEther('0.01'),
  });
  await txn.wait();
  console.log('Minted domain readyto.dance');

  txn = await domainContract.setRecord('readyto', 'Am I?');
  await txn.wait();
  console.log('Set record!');

  const address = await domainContract.getAddress('readyto');
  console.log('Owner of domain readyto:', address);

  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log('Contract balance:', hre.ethers.utils.formatEther(balance));
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
