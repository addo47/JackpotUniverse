//                                   @@@@@@@&&##&%
//                            %&&&@@@@@@@@&&&%%&&%%&%&%/*
//                        #%&&@@@@@@@@@@&@@&&&%(&%&&&&/***.,.
//                     .#%&@@@@@@@@@@@@@@&&&&&*/&(%%%%&*#(/,/*.
//                   (#%&@@@@@@@@@@@@&@@&&&&%%%%%##/((/**%#**.*/**
//                  (##%%%%%##(*,,,%&&#,,,,,,,,,,,,,,,,,((##(#,,,(/
//              ,&%%#%%%%..%%%%%#%.*&&#.%%%%#&&..%#%%%%%##./(/.%&%%%#%,,%,,,,,,,
//              .&%%%%%%%.%%%&%%%&,*%%#.%&%%%%%,,%%%%&&%%&%,//,&%&%%%%,,%%%%%&%,.
//              ,&#%#%%&,,%%%&#%#&,*%%(,%%#%#%%,,&#%%%#%#%%&,.,&%&#%#%,,%%#%%&#&,
//              ,&&%#%&&,,%&&&%%%&,*%&/*&&&%#&&,,%#%&&&&%&&&&%,&&&%%#&(,&%#%&&&%,
//             .,&#%&%&&,,&%&&#&&#,*%%*,@&#&&#&,,%&#&&#%,#&&#%&(&&#%&%@,,%&#&&#%,
//     ,,,,,,,,#,&&&#&&&,,#&&&&&#&,*%%,&&&&&#&&,,&#&&&&&**&&&&#&&&&&#&&,,&#&&&&&,
//   ,&&&@&%&&*%*%&&&@&%,,&@&%&&&@&,,,&@&%&&&@&,,&&@&%&&,.,,&&&@&#&&&@&,,&&@&#&&,.
//   ,%&&@@@%&&&@@%&&@@,.(,&@@%&&&@@%&&&@@%&&,***&&&@@&&,.((.&&&@@&&&&@,,&&&@@%&,.
//    *@&@&@@@&@@@@@&,..//*#,,(&%@&@@@&@&@,,.*#*,&%&&@@@,.///,%@@@@@&@&,,@&@&@@@%,
//      ,,,,,,,,,,,.(###(#%%%%**////(((/////%&%(///////**(#*/(#(............,@@&&.
//       .,//*((//***#%&&&&%#%%%&&&&&&%&&&&&/#%#&&&&&&#(/#(#%####((***/((/**///*
//         .*/((((((%%%%%%%%%#%%%%%#%%%%&#%*%##%&&&###(%####/%((%##/(((((#((*.
//             ..... **(#######%%####%%%%%%%%%%%%%%(&(%%%%#%(/(/*,   .....,..
//                     ,/(###%%%#%%%%%%&%%(&&&%&*(%(%&&&&%##%(/
//                        ///###%%%%%&&&@&&&&&%/%,&&&&&%%%%/*
//                            /((##%%&&&&@&&&&&&&%&&&%%%#
//                                   (##%%%%%%&&&&

/*                                                                             
This is the official contract of JackpotUniverse (JUNI) GOLD token.

Website: https://www.juni.gg
Twitter: https://twitter.com/JUNIBSC
Instagram: https://www.instagram.com/juniversebsc/
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Gold is ERC20PresetMinterPauser {
    using Address for address;

    event ValueReceived(address origin, address user, uint256 amount);

    event ValueReceivedInFallback(address origin, address user, uint256 amount);

    event MultiTransfer(address sender, uint256 recipientCount);

    event ContractsBanned(bool status);

    bool private contractsBanned = true;

    constructor() ERC20PresetMinterPauser("Gold", "GOLD") {
        // EMPTY
    }

    receive() external payable {
        if (msg.value > 0) {
            emit ValueReceived(tx.origin, msg.sender, msg.value);
        }
    }

    fallback() external payable {
        if (msg.value > 0) {
            emit ValueReceivedInFallback(tx.origin, msg.sender, msg.value);
        }
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must be admin");
        _;
    }

    function setContractBan(bool status) external onlyAdmin {
        contractsBanned = status;

        emit ContractsBanned(status);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from.isContract() || to.isContract()) {
            require(
                !contractsBanned ||
                    hasRole(DEFAULT_ADMIN_ROLE, from) ||
                    hasRole(MINTER_ROLE, from) ||
                    hasRole(DEFAULT_ADMIN_ROLE, to) ||
                    hasRole(MINTER_ROLE, to),
                "Tranferring to and from contracts is currently banned"
            );
        }

        if (
            _msgSender() == from &&
            hasRole(MINTER_ROLE, from) &&
            amount > balanceOf(from)
        ) {
            uint256 mintedTickets = amount * 10;
            mint(from, mintedTickets);
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (from != address(0) && hasRole(MINTER_ROLE, to)) {
            // Sending back to minter, so the user is burning/using those tokens up
            _burn(to, amount);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function withdrawBnb() external onlyAdmin {
        uint256 excess = address(this).balance;
        require(excess > 0, "No BNBs to withdraw");
        Address.sendValue(payable(_msgSender()), excess);
    }

    function withdrawNativeTokens() external onlyAdmin {
        uint256 excess = balanceOf(address(this));
        require(excess > 0, "No tokens to withdraw");
        transferFrom(address(this), _msgSender(), excess);
    }

    function withdrawOtherTokens(address token) external onlyAdmin {
        require(
            token != address(this),
            "Use the appropriate native token withdraw method"
        );
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(token).transfer(_msgSender(), balance);
    }

    function multiTransfer(
        address[] memory _recipients,
        uint256[] memory _values
    ) external onlyAdmin {
        require(
            _recipients.length == _values.length,
            "Total number of recipients and values are not equal"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                transfer(_recipients[i], _values[i]);
            }
        }

        emit MultiTransfer(msg.sender, _recipients.length);
    }

    function aboutMe() public pure returns (uint256) {
        return 0x6164646f34370a;
    }
}
