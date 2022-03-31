//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MetaXLauncher is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;

    uint8 public _decimals;
    bool public presaleEnded;
    bool public feesEnabled;
    uint256 public _fee;
    mapping(address => bool) internal _isExcludedFromFee;

    function initialize(address tokenOwner) public initializer {
        __ERC20_init("MetaXLauncher", "MXL");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _decimals = 9;
        _fee = 5_000;
        _mint(tokenOwner, 1_000_000_000 * (10**_decimals));

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[tokenOwner] = true;
    }

    function setAccountFeeStatus(address account, bool isExcluded)
        public
        onlyOwner
    {
        _isExcludedFromFee[account] = isExcluded;
    }

    function setFee(uint256 fee_) public onlyOwner {
        _fee = fee_;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(
            presaleEnded ||
                (!presaleEnded &&
                    (_isExcludedFromFee[sender] ||
                        _isExcludedFromFee[recipient])),
            "You don't have permission to make transfer while presale is ongoing."
        );

        if (feesEnabled) {
            if (
                !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            ) {
                uint256 feeAmount = (amount * _fee) / 100_000;
                if (feeAmount > 0) {
                    super._transfer(sender, address(this), feeAmount);
                    amount -= feeAmount;
                }
            }
        }

        super._transfer(sender, recipient, amount);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function finalizePresale() public onlyOwner {
        require(!presaleEnded, "Its already finalized.");
        feesEnabled = true;
        presaleEnded = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    receive() external payable {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
