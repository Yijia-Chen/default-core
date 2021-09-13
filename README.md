# Events

## Epoch
### event EpochIncremented(address os, address member, uint16 epoch, uint256 epochTime)

## Members
### event MemberRegistered(address os, address member, bytes32 alias_, uint16 epoch);
### event TokensStaked(address os, address member, uint256 amount, uint16 lockDuration, uint16 epoch);
### event TokensUnstaked(address os, address member, uint256 amount, uint16 lockDuration, uint16 epoch);
### event EndorsementGiven(address os, address fromMember, address toMember, uint256 endorsementsGiven, uint16 epoch);
### event EndorsementWithdrawn(address os, address fromMember, address toMember, uint256 endorsementsWithdrawn, uint16 epoch);

## PeerRewards
### event MemberRegistered(address os, address member, uint16 epochRegisteredFor, uint256 ptsRegistered);
### event AllocationSet(address os, address fromMember, address toMember, uint8 allocPts, uint16 currentEpoch);
### event AllocationGiven(address os, address fromMember, address toMember, uint256 allocGiven, uint16 currentEpoch);
### event RewardsClaimed(address os, address member, uint256 totalRewardsClaimed, uint16 epochClaimed);

## Mining
### event RewardsIssued(address os, address issuer, uint16 currentEpoch, uint256 newRewardsPerShare);
### event RewardsClaimed(address os, uint16 epochClaimed, address member, uint256 totalRewardsClaimed);
### event Registered(address os, uint16 currentEpoch, address member);

## Treasury
### event VaultOpened(address os, Vault vault, string name,string symbol, uint8 decimals, uint8 fee, uint16 epochOpened);
### event VaultFeeChanged(address os, Vault vault, uint8 newFee, uint16 epochOpened);
### event Deposited(address os, Vault vault, address member, uint256 amount, uint16 epoch);
### event Withdrawn(address os, Vault vault, address member, uint256 amount, uint16 epoch);

## DefaultOS
### event ModuleInstalled(address os, address module, bytes3 moduleKeycode);

## DefaultOSFactory
### event OSCreated(address os, string id, string name);