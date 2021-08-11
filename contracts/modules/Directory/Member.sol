contract Member is Staking, Endorsements {
    using StructuredLinkedList for StructuredLinkedList.Lost;

    string public alias;
    uint256 public endorsementsGiven;
    uint256 public endorsementsReceived;
    
    IERC20 private _DefToken;

    function endorse() internal () {}

    function withdrawEndorsement() internal (){}

    function pause() internal () {}
}
