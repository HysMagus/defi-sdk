// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import { ProtocolAdapter } from "../adapters/ProtocolAdapter.sol";
import { AmountType } from "../Structs.sol";
import { ERC20 } from "../ERC20.sol";


/**
 * @title Base contract for interactive protocol adapters.
 * @dev deposit() and withdraw() functions MUST be implemented
 * as well as all the functions from ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
abstract contract InteractiveAdapter is ProtocolAdapter {

    uint256 internal constant RELATIVE_AMOUNT_BASE = 1e18;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev The function must deposit assets to the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function deposit(
        address[] memory tokens,
        uint256[] memory amounts,
        AmountType[] memory amountTypes,
        bytes memory data
    )
        public
        payable
        virtual
        returns (address[] memory);

    /**
     * @dev The function must withdraw assets from the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function withdraw(
        address[] memory tokens,
        uint256[] memory amounts,
        AmountType[] memory amountTypes,
        bytes memory data
    )
        public
        payable
        virtual
        returns (address[] memory);

    function getAbsoluteAmountDeposit(
        address token,
        uint256 amount,
        AmountType amountType
    )
        internal
        view
        virtual
        returns (uint256)
    {
        if (amountType == AmountType.Relative) {
            require(amount <= RELATIVE_AMOUNT_BASE, "L: wrong relative value!");

            uint256 balance;
            if (token == ETH) {
                balance = address(this).balance;
            } else {
                balance = ERC20(token).balanceOf(address(this));
            }

            if (amount == RELATIVE_AMOUNT_BASE) {
                return balance;
            } else {
                return mul(balance, amount) / RELATIVE_AMOUNT_BASE;
            }
        } else {
            return amount;
        }
    }

    function getAbsoluteAmountWithdraw(
        address token,
        uint256 amount,
        AmountType amountType
    )
        internal
        view
        virtual
        returns (uint256)
    {
        if (amountType == AmountType.Relative) {
            require(amount <= RELATIVE_AMOUNT_BASE, "L: wrong relative value!");

            (uint256 balance, ) = getBalance(token, address(this));
            if (amount == RELATIVE_AMOUNT_BASE) {
                return balance;
            } else {
                return mul(balance, amount) / RELATIVE_AMOUNT_BASE;
            }
        } else {
            return amount;
        }
    }

    function mul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 c = a * b;
        require(c / a == b, "IA: multiplication overflow");

        return c;
    }
}
