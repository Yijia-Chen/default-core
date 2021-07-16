interface IVault {
    function withdraw(uint256 amount) external returns (bool);
    function deposit(uint256 amount) external returns (bool);
    function borrow(uint256 amount) external returns (bool);
    function repay(uint256 amount) external returns(bool);
    function setFee(uint8 percentage) external returns(bool);

    event Withdrawn(address indexed member, uint256 amount);
    event Deposited(address indexed member, uint256 amount);
    event FeeChanged(uint8 percentage);
}