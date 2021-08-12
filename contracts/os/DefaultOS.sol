import "@openzeppelin/contracts/access/Ownable.sol";
import "./OS.sol";

abstract contract DefaultOS is Ownable {
    OS internal _OS;

    constructor(OS defaultOS_) {
        _OS = defaultOS_;
    }
}