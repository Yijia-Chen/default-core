async function incrementWeek(customTime) {
  const time = customTime ? customTime : 7 * 24 * 60 * 60;

  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const timestampBefore = blockBefore.timestamp;

  await ethers.provider.send('evm_setNextBlockTimestamp', [timestampBefore + time])
  await ethers.provider.send('evm_mine');
}

module.exports = {
  incrementWeek
}