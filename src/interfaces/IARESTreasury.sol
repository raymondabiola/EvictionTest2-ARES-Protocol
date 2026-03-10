// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IARESTreasury{
        struct Contributor{
        string name;
        bool isContributor;
        mapping(uint => bool) hasVoted;
    }

function checkIsContributor(address _address) external view returns(bool);
function transferOutOfTreasury(address _erc20Addr, address _to, uint _amount) external;
}