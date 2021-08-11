// Stakes are not ERC20 tokens—they are simply locked in the contract. No ERC20/composability
// Around the staked tokens so as to not reduce the opportunity cost of the liquidity preference
// e.g. staking DEF is less of a commitment if someone can swap their sDEF for DEF/USDC immediately.
// And less confusing for the user when participating in governance/selling their tokens (see vBNT/BNT).

contract Staking {

    // number of staking blocks for the user
    uint16 numBlocks;

    // getter for the Stake, using expiry epoch as unique identifier.
    // adding stakes to an existing stake for expiry epoch increments the existing amount.
    mapping(uint16 => Stake) getStakeAt;

    // the first staking block of the list -> used for unstaking
    uint16 public HEAD = 0;

    // the last staking block of the list -> used for staking
    uint16 public TAIL = 0;

    // all staked tokens of the user
    uint256 public totalStakedTokens = 0;


    // pack the struct variables--order declaration matters!
    struct Stake {

        // Expiry epoch for a block of staked tokens.
        // Used as the comparison for the list sort, and unique id for linked list.
        uint16 expirationEpoch;

        // staking duration in epochs
        uint16 lockDuration;

        // prev node in linked list of staking blocks
        uint16 prevStakeExpiryEpoch;

        // next node in linked list of staking blocks
        uint16 nextStakeExpiryEpoch;

        // DEF tokens staked
        uint256 amountStaked;
    }

    // amount of tokens + duration of stake
    function stake(uint256 amount_, uint32 lockDuration_) internal () {
        // UNIMPLEMNETED:: check to see if expiration epoch exists first

        uint16 expirationEpoch = _OS.currentEpoch + lockDuration_;
        assert(expirationEpoch != 0, "expiration cannot be the 0 epoch");

        // if the list is empty, set the head and increase the numBlocks
        if (numBlocks == 0) {
            HEAD = expirationEpoch;
            TAIL = expirationEpoch;
            getStakeAt[expirationEpoch] = new Stake(expirationEpoch, lockDuration_, 0, 0, amount_);

        // otherwise, keep looking through the list and insert when it finds a later expiring staking block
        } else {

            // start from the back because a new staking block is more likely to expire later than earlier than previous staking blocks
            Stake storage CURRENT_BLOCK = getStakeAt[TAIL];
            if (expirationEpoch > CURRENT_BLOCK.expirationEpoch) {
                
                // if current expiry is after current latest, make current expiry the tail
                TAIL = expirationEpoch;
                CURRENT_BLOCK.nextStakeExpiryEpoch = expirationEpoch;

            // otherwise keep going until the previous staking block is less than the current expiration epoch ()
            } else {

                // If the next staking block exists and is less than current expiry, keep going.
                while (CURRENT_BLOCK.prevStakeExpiryEpoch != 0 && CURRENT_BLOCK.prevStakeExpiryEpoch > expirationEpoch) {
                    CURRENT_BLOCK = getStakeAt[CURRENT_BLOCK.prevStakeExpiryEpoch];
                }

                // If the current block is the HEAD, make the new Staking Block the head.
                if (CURRENT_BLOCK.prevStakeExpiryEpoch == 0) {
                    HEAD = expirationEpoch;

                // If it's another staking block, adjust its next pointer to the new block
                } else {
                    Stake storage PREV_BLOCK = getStakeAt[CURRENT_BLOCK.prevStakeExpiryEpoch];
                    PREV_BLOCK.nextStakeExpiryEpoch = expirationEpoch;
                }

                // Adjust the current block's prev pointer to the new block
                CURRENT_BLOCK.prevStakeExpiryEpoch = expirationEpoch;

                // create and map new block
                getStakeAt[expirationEpoch] = new Stake(expirationEpoch, 
                                                                    lockDuration_,
                                                                    CURRENT_BLOCK.prevStakeExpiryEpoch,
                                                                    CURRENT_BLOCK.expirationEpoch, 
                                                                    amount_);


                


        // increment the numBlocks of the list
        numBlocks++;
        totalStakedTokens += amount_;

        // transfer Def Tokens to the contract
        DefToken.transferFrom(member_, address(this), amount_);

        // record the event for dapps
        emit DefTokensStaked(member_, amount_)
    }

    function unstake(address member_, uint256 amount_) internal () {
        require(numBlocks != 0, "There is nothing to unstake!");

        uint256 leftToUnstake = amount_;
        uint16 nextStakeExpiryEpoch = HEAD;

        while (leftToUnstake >= 0) {
            Stake storage stakeToRedeem = getStakesAt[nextStakeExpiryEpoch]];
            assert(_OS.currentEpoch <= stakeToRedeem.expirationEpoch, "Not enough tokens available to unstake");

            leftToUnstake -= stakeToRedeem.amountStaked;

            if (leftToUnstake >= 0) {
                // reset the mapping slot
                getStakesAt[stake.expirationEpoch] = new Stake(0, 0, 0, 0, 0);
                numBlocks--;
            }

            nextStakeExpiryEpoch = stakeToRedeem.nextStakeExpiryEpoch;
        }

        // point HEAD to the most recent expiring stake after unstaking tokens
        stakeToRedeem.amountStaked += leftToUnstake;
        HEAD = stakeToRedeem.expirationEpoch;

        // transfer Def Tokens back to user
        DefTokens.transfer(member_, amount_);

        emit DefTokensUnstaked(member_, amount_);
    }
}