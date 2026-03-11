// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;
import {IERC20} from "../src/interfaces/IERC20.sol";
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract AresTreasury is AccessControl, ReentrancyGuard{
    
    bytes32 public constant PROPOSAL_CONTRACT_ROLE = keccak256("PROPOSAL_CONTRACT_ROLE");

    mapping(address => mapping(address => uint)) public contributions;
    struct Contributor{
        string name;
        bool isContributor;
    }

    mapping(address => Contributor) public contributors;

    event TreasuryFunded(address indexed fundedBy, address indexed erc20Address, uint amount);
    event TreasuryTransferred(address indexed to, address indexed erc20Address, uint amount);

    constructor(address _proposalContract){
        require(_proposalContract != address(0), "Invalid Address");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PROPOSAL_CONTRACT_ROLE, _proposalContract);
    }

    function fundTreasury(string memory _name, uint _amount, address _erc20Address) public  nonReentrant{
        require(_amount > 0 , "Invalid Amount");
        require(_erc20Address != address(0));
        IERC20 token = IERC20(_erc20Address);
        token.transferFrom(msg.sender, address(this), _amount);
        contributors[msg.sender].name = _name; 
        contributions[msg.sender][_erc20Address] += _amount;

        if(!contributors[msg.sender].isContributor){
            contributors[msg.sender].isContributor  = true;
        }
        emit TreasuryFunded(msg.sender, _erc20Address, _amount);
    }

    function transferOutOfTreasury(address _to, address _erc20Addr, uint _amount) external onlyRole(PROPOSAL_CONTRACT_ROLE) nonReentrant{
        require(_to != address(0), "Invalid Address");
        require(_amount > 0 , "Invalid Amount");
        IERC20 token = IERC20(_erc20Addr);
        require(_amount <= token.balanceOf(address(this)), "Insufficient contract balance");
        token.transfer(_to, _amount);
        emit TreasuryTransferred(_to, _erc20Addr, _amount);
    }

    function checkIsContributor(address _address) external view returns(bool){
        return contributors[_address].isContributor;
    }
}
