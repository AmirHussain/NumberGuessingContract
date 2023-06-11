/**
 *Submitted for verification at BscScan.com on 2022-10-29
 */

// SPDX-License-Identifier: MIT License
pragma solidity 0.8.9;
import 'hardhat/console.sol';

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, 'Address: low-level static call failed');
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), 'Address: delegate call to non-contract');

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), 'SafeERC20: approve from non-zero to non-zero allowance');
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract VarnofxStaking is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public USD;
    address public paymentTokenAddress;

    event _Deposit(address indexed addr, uint256 amount, uint40 tm, bool isBorrowed, bool isBreakEven);
    event _Payout(address indexed addr, uint256 amount);
    event _Refund(address indexed addr, uint256 amount);
    event ReinvestMade(address indexed addr, uint256 amount, uint40 tm);

    address payable public ceo;
    address payable public dev;

    uint256 unit1 = 1 * 10 ** 18;

    uint8 public isScheduled = 1;
    uint256 private constant DAY = 24 hours;
    uint256 private numDays = 1;

    uint16 constant PERCENT_DIVIDER = 100;
    uint16[1] private ref_bonuses = [5];

    uint256 public invested;
    uint256 public reinvested;
    uint256 public withdrawn;
    uint256 public ref_bonus;
    uint256 public refunds;
    uint256 public supply_pool;
    uint256 public available_supply;
    uint40 public lastUpdated;

    struct Tarif {
        uint256 life_days;
        uint256 percent;
    }

    struct Depo {
        uint256 tarif;
        uint256 amount;
        uint40 time;
        bool isBorrowed;
        bool isBreakEven;
    }

    struct Downline {
        uint8 level;
        address invite;
    }

    struct PayoutAmount {
        uint256 devident;
        uint256 poolDevident;
    }

    struct Member {
        string email;
        string lastname;
        string firstname;
        string password;
        address upline;
        uint256 dividends;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_ref_bonus;
        uint256 total_reinvested;
        uint256 total_refunded;
        uint40 lastWithdrawn;
        Depo[] deposits;
        Downline[] downlines1;
        uint256[1] structure;
    }
    uint256 secondsPerDay = 86400;
    mapping(address => uint256) public ownerWithdraw;
    mapping(address => uint256) public ownerDeposit;

    mapping(address => Member) public members;
    mapping(address => uint256) public memberSupply;

    mapping(address => uint8) public banned;
    mapping(uint256 => Tarif) public tarifs;
    address[] public userAddresses;

    uint public nextMemberNo;

    constructor() {
        dev = payable(msg.sender);
        ceo = payable(msg.sender);

        tarifs[0] = Tarif(36135, 3613500);

        paymentTokenAddress = 0x0455A1cC4E88A146A98f83D35e94e1D6a3BE2759; //USDC
        // paymentTokenAddress = token;
        USD = IERC20(paymentTokenAddress);
    }

    function OwnerWithDraw(uint256 amount) external onlyOwner {
        require(invested >= amount, 'Ammount exceeded the invested amount');
        ownerWithdraw[msg.sender] += amount;
        USD.safeTransfer(owner(), amount);
    }

    function OwnerDeposit(uint256 amount) external onlyOwner {
        ownerDeposit[msg.sender] += amount;
        USD.safeTransferFrom(msg.sender, address(this), amount);
    }

    function Deposit(address _upline, uint256 amount, bool isBorrowed, bool isBreakEven, uint256 breakevenAmount) external {
        if (isBreakEven) {
            PayoutAmount memory payout = this.computePayout(msg.sender);
            require(payout.devident > breakevenAmount, 'Available amount is less then breakeven amount');
            Payout(false, true, breakevenAmount);
            amount = payout.devident - breakevenAmount;
        }

        require(amount >= 10 ether, 'Minimum Deposit is 10 USDT!');
        // require(amount <= 500 ether, 'Maximum Deposit is 500 USDT!');

        lastUpdated = uint40(block.timestamp);
        setUpline(msg.sender, _upline);
        Member storage member = members[msg.sender];
        if (isBorrowed) {
            available_supply -= amount;
        } else {
            if (isBreakEven == false) {
                USD.safeTransferFrom(msg.sender, address(this), amount);
            }
        }
        member.deposits.push(Depo({tarif: 0, amount: amount, time: uint40(block.timestamp), isBorrowed: isBorrowed, isBreakEven: isBreakEven}));
        emit _Deposit(msg.sender, amount, uint40(block.timestamp), isBorrowed, isBreakEven);

        uint256 teamFee = SafeMath.div(amount, 100);
        USD.safeTransfer(dev, teamFee);

        member.total_invested += amount;

        invested += amount;
        withdrawn += teamFee;
        commissionPayouts(msg.sender, amount);
    }

    function Reinvest() external {
        require(banned[msg.sender] == 0, 'Banned Wallet!');
        Member storage member = members[msg.sender];
        lastUpdated = uint40(block.timestamp);
        getPayout(msg.sender);

        require(member.dividends >= 10 ether, 'Minimum reinvest is 10 USDT.');

        uint256 amount = member.dividends;
        member.dividends = 0;

        member.total_withdrawn += amount;
        withdrawn += amount;

        member.deposits.push(Depo({tarif: 0, amount: amount, time: uint40(block.timestamp), isBorrowed: false, isBreakEven: false}));
        emit ReinvestMade(msg.sender, amount, uint40(block.timestamp));

        member.total_invested += amount;
        member.total_reinvested += amount;

        invested += amount;
        reinvested += amount;
    }

    function Payout(bool supplyToPool, bool breakEven, uint256 breakEvenAmount) public {
        require(banned[msg.sender] == 0, 'Banned Wallet!');
        Member storage member = members[msg.sender];
        lastUpdated = uint40(block.timestamp);

        if (isScheduled == 1) {
            require(block.timestamp >= (member.lastWithdrawn + (DAY * numDays)), 'Not due yet for next payout!');
        }

        getPayout(msg.sender);
        uint256 supply = memberSupply[msg.sender];
        require((member.dividends + supply) >= 10 ether, 'Minimum payout is 10 USDT.');

        uint256 amount = member.dividends;
        member.dividends = 0;

        member.total_withdrawn += amount;
        if (supplyToPool == false) {
            if (memberSupply[msg.sender] > 0) {
                amount += memberSupply[msg.sender];
                supply_pool -= memberSupply[msg.sender];
                memberSupply[msg.sender] = 0;
            }
            uint256 depositAmount = amount;
            if (breakEven) {
                depositAmount = breakEvenAmount;
            }
            USD.safeTransfer(msg.sender, depositAmount);
        }
        emit _Payout(msg.sender, amount);

        uint256 teamFee = SafeMath.div(amount, 100);
        USD.safeTransfer(ceo, teamFee);
        withdrawn += amount + teamFee;
        if (supplyToPool) {
            memberSupply[msg.sender] += (amount - teamFee);
            supply_pool += (amount - teamFee);
            available_supply += (amount - teamFee);
        }
    }

    function refundWallet(address wallet) external returns (bool success) {
        lastUpdated = uint40(block.timestamp);
        require(wallet == msg.sender || wallet == owner(), 'Unidentified wallet');

        if (banned[wallet] == 1) {
            return false;
        }
        Member storage member = members[wallet];

        uint256 refund = member.total_invested;
        member.total_refunded += refund;
        withdrawn += refund;
        refunds += refund;

        //uint256 deduct = refund.div(10) + refund.div(50);
        //refund = refund.sub(deduct);

        USD.safeTransfer(wallet, refund);
        emit _Refund(wallet, refund);
        banned[wallet] = 1;
        return true;
    }

    function computePayout(address _addr) external view returns (PayoutAmount memory) {
        PayoutAmount memory payout = PayoutAmount({devident: 0, poolDevident: 0});

        if (banned[_addr] == 1) {
            return payout;
        }
        Member storage member = members[_addr];

        for (uint256 i = 0; i < member.deposits.length; i++) {
            Depo storage dep = member.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * secondsPerDay;
            uint40 from = member.lastWithdrawn > dep.time ? member.lastWithdrawn : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;
            uint256 percent = tarif.percent;
            if (dep.isBorrowed) {
                percent = tarif.percent / 2;
            }
            if (from < to) {
                uint256 devident = (dep.amount * (to - from) * percent) / tarif.life_days / secondsPerDay / 100;
                payout.devident += devident;
                if (dep.isBorrowed) {
                    payout.poolDevident += devident;
                }
            }
        }
        return payout;
    }

    function getPayout(address _addr) private {
        PayoutAmount memory payout = this.computePayout(_addr);
        uint256 profitPerLendingToken = 0;
        if (payout.poolDevident > 0) {
            (payout.poolDevident * unit1) / supply_pool;
        }
        if (payout.devident > 0) {
            members[_addr].lastWithdrawn = uint40(block.timestamp);
            members[_addr].dividends += payout.devident;
        }
        if (payout.poolDevident > 0) {
            setSupplyProfit(profitPerLendingToken);
        }
    }

    function setSupplyProfit(uint256 profitPerLendingToken) private {
        for (uint256 index = 0; index < userAddresses.length; index++) {
            memberSupply[userAddresses[index]] += ((memberSupply[userAddresses[index]] * profitPerLendingToken) / unit1);
        }
    }

    function addressExistsInArray(address[] memory addressesArray, address targetAddress) public pure returns (bool) {
        for (uint i = 0; i < addressesArray.length; i++) {
            if (addressesArray[i] == targetAddress) {
                return true;
            }
        }
        return false;
    }

    function setUpline(address _addr, address _upline) private {
        if (members[_addr].upline == address(0) && _addr != owner()) {
            if (members[_upline].total_invested <= 0) {
                _upline = owner();
            }
            if (!addressExistsInArray(userAddresses, _addr)) {
                userAddresses.push(_addr);
            }

            members[_addr].upline = _upline;
            members[_upline].structure[0]++;

            Member storage up = members[_upline];
            up.downlines1.push(Downline({level: 1, invite: _addr}));
        }
    }

    function commissionPayouts(address _addr, uint256 _amount) private {
        address up = members[_addr].upline;

        if (up == address(0)) return;
        if (banned[up] == 0) {
            uint256 bonus = (_amount * ref_bonuses[0]) / PERCENT_DIVIDER;

            USD.safeTransfer(up, bonus);

            members[up].total_ref_bonus += bonus;
            members[up].total_withdrawn += bonus;

            ref_bonus += bonus;
            withdrawn += bonus;
        }
    }

    function ChiefCEO(uint256 amount) public onlyOwner returns (bool success) {
        lastUpdated = uint40(block.timestamp);
        USD.safeTransfer(msg.sender, amount);
        withdrawn += amount;
        return true;
    }

    function nextWithdraw(address _addr) external view returns (uint40 next_sked) {
        if (banned[_addr] == 1) {
            return 0;
        }
        Member storage member = members[_addr];
        if (member.deposits.length > 0) {
            return uint40(member.lastWithdrawn + (DAY * numDays));
        }
        return 0;
    }

    function setPaymentToken(address newval) public onlyOwner returns (bool success) {
        paymentTokenAddress = newval;
        return true;
    }

    function getContractBalance() public view returns (uint256) {
        return IERC20(paymentTokenAddress).balanceOf(address(this));
    }

    function setProfile(string memory _email, string memory _lname, string memory _fname, string memory _password) public returns (bool success) {
        members[msg.sender].email = _email;
        members[msg.sender].lastname = _lname;
        members[msg.sender].firstname = _fname;
        members[msg.sender].password = _password;
        return true;
    }

    function setSponsor(address member, address newSP) public onlyOwner returns (bool success) {
        members[member].upline = newSP;
        return true;
    }

    function setCEO(address payable newval) public onlyOwner returns (bool success) {
        ceo = newval;
        return true;
    }

    function setDev(address payable newval) public onlyOwner returns (bool success) {
        dev = newval;
        return true;
    }

    function setScheduled(uint8 newval) public onlyOwner returns (bool success) {
        isScheduled = newval;
        return true;
    }

    function setDays(uint newval) public onlyOwner returns (bool success) {
        numDays = newval;
        return true;
    }

    function banWallet(address wallet) public onlyOwner returns (bool success) {
        banned[wallet] = 1;
        return true;
    }

    function unbanWallet(address wallet) public onlyOwner returns (bool success) {
        banned[wallet] = 0;
        return true;
    }

    function userInfo(
        address _addr
    ) external view returns (uint256 for_withdraw, uint256 numDeposits, uint256 downlines1, uint256[1] memory structure) {
        Member storage member = members[_addr];

        PayoutAmount memory payout = this.computePayout(_addr);

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = member.structure[i];
        }

        return (payout.devident + member.dividends, member.deposits.length, member.downlines1.length, structure);
    }

    function memberDownline(address _addr, uint8 level, uint256 index) external view returns (address downline) {
        Member storage member = members[_addr];
        Downline storage dl = member.downlines1[0];
        if (level == 1) {
            dl = member.downlines1[index];
        }
        return (dl.invite);
    }

    function memberDeposit(address _addr, uint256 index) external view returns (uint40 time, uint256 amount, uint256 lifedays, uint256 percent) {
        Member storage member = members[_addr];
        Depo storage dep = member.deposits[index];
        Tarif storage tarif = tarifs[dep.tarif];
        return (dep.time, dep.amount, tarif.life_days, tarif.percent);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function getContractValues() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (invested, reinvested, withdrawn, ref_bonus, refunds, supply_pool, available_supply);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
