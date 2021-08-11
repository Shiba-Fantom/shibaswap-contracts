 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TankChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 lastRewardTime; // Last block timestamp that Rewards distribution occurs.
        uint256 accTokenPerShare; // Accumulated Rewards per share, times 1e18. See below.
        uint16 depositFee;      // Deposit fee in basis points
    }

    // The deposit token!
    IERC20 public depositToken;
    IERC20 public rewardToken;

    address public feeAddr;

    // Reward tokens created per block.
    uint256 public tokenPerSecond;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;
    uint256 public startTime;
    uint256 public endTime;

    // The amount to burn in 0.01 percentages
    uint256 public burnMultiplier;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDepositFee(address indexed user, uint16 amount);

    constructor(
        IERC20 _depositToken,
        IERC20 _rewardToken,
        address _feeAddr,
        uint256 _tokenPerSecond,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _burnMultiplier
    ) {
        depositToken = _depositToken;
        rewardToken = _rewardToken;
        feeAddr = _feeAddr;
        tokenPerSecond = _tokenPerSecond;
        startTime = _startTime;
        endTime = _endTime;
        burnMultiplier = _burnMultiplier;

        // staking pool
        poolInfo = PoolInfo({
            token: _depositToken,
            lastRewardTime: startTime,
            accTokenPerShare: 0,
            depositFee: 300
        });
    }

    function setTokenPerSecond(uint256 _tokenPerSecond) external onlyOwner {
        updatePool();
        tokenPerSecond = _tokenPerSecond;
    }
    function stopReward() external onlyOwner {
        endTime = block.timestamp;
    }

    function adjustBlockEnd() external onlyOwner {
        uint256 totalLeft = rewardToken.balanceOf(address(this));
        endTime = block.timestamp + totalLeft.div(tokenPerSecond);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        _from = _from > startTime ? _from : startTime;
        _to = _to > endTime ? endTime: _to;

        if (_to < startTime || _from > endTime) return 0;
        return _to - _from;
    }

    // View function to see pending Reward on frontend.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = poolInfo.accTokenPerShare;
        uint256 supply = poolInfo.token.balanceOf(address(this));
        if (block.timestamp > poolInfo.lastRewardTime && supply != 0) {
            uint256 multiplier = getMultiplier(
                poolInfo.lastRewardTime,
                block.timestamp
            );
            uint256 reward = multiplier.mul(tokenPerSecond);
            accTokenPerShare = accTokenPerShare.add(
                reward.mul(1e18).div(supply)
            );
        }
        return
            user.amount.mul(accTokenPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.timestamp <= poolInfo.lastRewardTime) {
            return;
        }
        uint256 supply = poolInfo.token.balanceOf(address(this));
        if (supply == 0) {
            poolInfo.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            poolInfo.lastRewardTime,
            block.timestamp
        );
        uint256 reward = multiplier.mul(tokenPerSecond);
        poolInfo.accTokenPerShare = poolInfo.accTokenPerShare.add(
            reward.mul(1e18).div(supply)
        );
        poolInfo.lastRewardTime = block.timestamp;
    }

    // Stake depositToken to TankChef
    function deposit(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(poolInfo.accTokenPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardDebt = user.amount.mul(poolInfo.accTokenPerShare).div(1e18);
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            uint256 burnAmount = _amount.mul(burnMultiplier).div(10000);
            uint256 depositFee = _amount.mul(poolInfo.depositFee).div(10000);
            poolInfo.token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount - burnAmount
            );
            if (depositFee > 0) {
                poolInfo.token.safeTransfer(feeAddr, depositFee);
            }
            if (burnAmount > 0) {
                poolInfo.token.safeTransferFrom(
                    address(msg.sender),
                    address(0xdead),
                    burnAmount
                );
            }
            user.amount = user.amount.add(_amount).sub(burnAmount).sub(depositFee);
        }
        user.rewardDebt = user.amount.mul(poolInfo.accTokenPerShare).div(1e18);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw depositToken tokens from STAKING.
    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();

        uint256 pending = user.amount.mul(poolInfo.accTokenPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            poolInfo.token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(poolInfo.accTokenPerShare).div(1e18);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        poolInfo.token.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(
            _amount <= rewardToken.balanceOf(address(this)),
            "not enough token"
        );
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
        // Update fee address by the previous fee manager.
    function setFeeAddress(address _feeAddr) external {
        require(msg.sender == feeAddr, "setFeeAddress: Forbidden");
        feeAddr = _feeAddr;

        emit SetFeeAddress(msg.sender, _feeAddr);
    }

    function setDepositFee(uint16 _depositFee) external onlyOwner {
        poolInfo.depositFee = _depositFee;

        emit SetDepositFee(msg.sender, _depositFee);
    }
    

    function updateStartTime(uint256 _startTime) external onlyOwner {
        require(block.timestamp < startTime, "Staking was started already");
        require(block.timestamp < _startTime);
        
        startTime = _startTime;
        uint256 totalLeft = rewardToken.balanceOf(address(this));
        endTime = block.timestamp + totalLeft.div(tokenPerSecond);
    }

}