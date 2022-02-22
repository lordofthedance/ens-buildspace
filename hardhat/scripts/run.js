const main = async () => {
  const [owner, randomPerson] = await hre.ethers.getSigners();

  const domainContractFactory = await hre.ethers.getContractFactory('Domains');
  const domainContract = await domainContractFactory.deploy('dance');
  await domainContract.deployed();
  console.log('Contract deployed to:', domainContract.address);
  console.log('Contract deployed by:', owner.address);

  let txn = await domainContract.registerAndSetData(
    'lordof',
    'to be or not to be',
    'this is my avatar',
    { value: hre.ethers.utils.parseEther('1234') }
  );
  await txn.wait();

  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log('Contract balance:', hre.ethers.utils.formatEther(balance));

  try {
    txn = await domainContract.connect(randomPerson).withdraw();
    await txn.wait();
  } catch (error) {
    console.log('Could not rob contract');
  }

  // Let's look in their wallet so we can compare later
  let ownerBalance = await hre.ethers.provider.getBalance(owner.address);
  console.log(
    'Balance of owner before withdrawal:',
    hre.ethers.utils.formatEther(ownerBalance)
  );

  // Oops, looks like the owner is saving their money!
  txn = await domainContract.connect(owner).withdraw();
  await txn.wait();

  // Fetch balance of contract & owner
  const contractBalance = await hre.ethers.provider.getBalance(
    domainContract.address
  );
  ownerBalance = await hre.ethers.provider.getBalance(owner.address);

  console.log(
    'Contract balance after withdrawal:',
    hre.ethers.utils.formatEther(contractBalance)
  );
  console.log(
    'Balance of owner after withdrawal:',
    hre.ethers.utils.formatEther(ownerBalance)
  );

  // const domainOwner = await domainContract.getAddress('lordof');
  // const record = await domainContract.getRecord('lordof');
  // const avatar = await domainContract.getAvatar('lordof');
  // console.log(
  //   'Owner of domain:',
  //   domainOwner,
  //   '\nRecord:',
  //   record,
  //   '\nAvatar:',
  //   avatar
  // );
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
