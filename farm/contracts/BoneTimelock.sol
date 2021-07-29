// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

// The shibaylock leverages using openzeppelin timelock for maximum safety.
// To see openzepplin's audits goto: https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/audit
contract BoneTimelock {
    using SafeERC20 for IERC20;

    IERC20 public bone;
    IERC20 public boneLP;

    TokenTimelock[] public Locks;

    constructor (IERC20 _bone, IERC20 _boneLP, address _beneficary) {

        bone = _bone;
        boneLP = _boneLP;
        uint currentTime = block.timestamp;

        createLock(_bone, _beneficary, currentTime + 30 days);
        createLock(_bone, _beneficary, currentTime + 60 days);
        createLock(_bone, _beneficary, currentTime + 90 days);
        createLock(_boneLP, _beneficary, currentTime + 365 days);
    }

    function createLock(IERC20 token, address sender, uint256 time) internal {
        TokenTimelock lock = new TokenTimelock(token, sender, time);
        Locks.push(lock);
    }

    // Attempts to release tokens. This is done safely with 
    // OpenZeppelin which checks the proper time has passed.
    // To see their code go to: 
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/TokenTimelock.sol
    function release(uint lock) external {
        Locks[lock].release();
    }

    function getLockAddress(uint lock) external view returns (address) {
        require(lock <= 3, "getLockAddress: lock doesnt exist");

        return address(Locks[lock]);
    }
    
    //Forward along tokens to their appropriate vesting place
    function forwardTokens() external {

        uint bones = bone.balanceOf(address(this));
        uint boneLPs = boneLP.balanceOf(address(this));

        require(bones > 0, "forwardTokens: no bones!");
        require(boneLPs > 0, "forwardTokens: no shiba lps!");

        for (uint256 index = 0; index <= 2; index++) {
            bone.transfer(address(Locks[index]), bones / 3);
        }

        // just incase theres any bones left from rounding
        uint leftover = bone.balanceOf(address(this));

        if (leftover > 0) {
            bone.transfer(address(Locks[2]), leftover);
        }

        boneLP.safeTransfer(address(Locks[3]), boneLPs);
    }


}
