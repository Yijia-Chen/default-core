# Events

## Epoch
### event EpochIncremented(uint16 epoch, uint256 epochTime)

## Members
### event MemberRegistered(address member, bytes32 alias_, uint16 epoch);
### event TokensStaked(address member, uint256 amount, uint16 lockDuration, uint16 epoch);
### event TokensUnstaked(address member, uint256 amount, uint16 lockDuration, uint16 epoch);
### event EndorsementGiven(address fromMember, address toMember, uint256 endorsementsGiven, uint16 epoch);
### event EndorsementWithdrawn(address fromMember, address toMember, uint256 endorsementsWithdrawn, uint16 epoch);

## PeerRewards
### event MemberRegistered(address member, uint16 epochRegisteredFor, uint256 ptsRegistered);
### event AllocationSet(address fromMember, address toMember, uint8 allocPts);
### event AllocationGiven(address fromMember, address toMember, uint256 allocGiven, uint16 epoch);
### event RewardsClaimed(address member, uint256 totalRewardsClaimed, uint16 epochClaimed);

## Mining
### event RewardsIssued(uint16 currentEpoch, uint256 newRewardsPerShare);
### event RewardsClaimed(uint16 epochClaimed, address member, uint256 totalRewardsClaimed);
### event Registered(uint16 currentEpoch, address member);

## Treasury
### event VaultOpened(Vault vault, uint16 epochOpened);
### event VaultFeeChanged(Vault vault, uint8 newFee, uint16 epochOpened);
### event Deposited(Vault vault, address member, uint256 amount, uint16 epoch);
### event Withdrawn(Vault vault, address member, uint256 amount, uint16 epoch);

## DefaultOS
### event ModuleInstalled(bytes3 moduleKeycode, address OSAddress, address moduleAddress);

## DefaultOSFactory
### event DaoCreated(address os, string id);