pragma solidity ^0.4.11;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) revert();
    }
}

contract ERC223Token {
    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function contribution(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public decimals;
    string public name;
}

contract StandardToken is ERC223Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {return false;}
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {return false;}
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    uint256 public totalSupply;
}

contract ReserveToken is StandardToken, SafeMath {
    address public minter;

    function ReserveToken() {
        minter = msg.sender;
    }

    function create(address account, uint amount) {
        if (msg.sender != minter) revert();
        balances[account] = safeAdd(balances[account], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }

    function destroy(address account, uint amount) {
        if (msg.sender != minter) revert();
        if (balances[account] < amount) revert();
        balances[account] = safeSub(balances[account], amount);
        totalSupply = safeSub(totalSupply, amount);
    }
}

contract SciCube is SafeMath {
    address public admin;
    address public feeAccount;
    uint public feeMake;
    uint public feeTake;
    uint public freeUntilDate;
    mapping(address => mapping(address => uint)) public tokens;
    mapping(address => mapping(bytes32 => bool)) public orders;
    mapping(address => mapping(bytes32 => uint)) public orderFills;

    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

    function SciCube(address admin_, address feeAccount_, uint feeMake_, uint feeTake_, uint freeUntilDate_) {
        admin = admin_;
        feeAccount = feeAccount_;
        feeMake = feeMake_;
        feeTake = feeTake_;
        freeUntilDate = freeUntilDate_;
    }

    function() {
        revert();
    }

    function changeAdmin(address admin_) {
        if (msg.sender != admin) revert();
        admin = admin_;
    }

    function changeFeeAccount(address feeAccount_) {
        if (msg.sender != admin) revert();
        feeAccount = feeAccount_;
    }

    function changeFeeMake(uint feeMake_) {
        if (msg.sender != admin) revert();
        if (feeMake_ > feeMake) revert();
        feeMake = feeMake_;
    }

    function changeFeeTake(uint feeTake_) {
        if (msg.sender != admin) revert();
        if (feeTake_ > feeTake) revert();
        feeTake = feeTake_;
    }

    function changeFreeUntilDate(uint freeUntilDate_) {
        if (msg.sender != admin) revert();
        freeUntilDate = freeUntilDate_;
    }

    function deposit() payable {
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function withdraw(uint amount) {
        if (tokens[0][msg.sender] < amount)
            revert();
        tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
        if (!msg.sender.call.value(amount)())
            revert();
        Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    function depositToken(address token, uint amount) {
        if (token == 0) revert();
        if (!ERC223Token(token).transferFrom(msg.sender, this, amount)) revert();
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) {
        if (token == 0) revert();
        if (tokens[token][msg.sender] < amount) revert();
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (!ERC223Token(token).transfer(msg.sender, amount)) revert();
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function tokenFallback(address _origin, uint _value, bytes _data) public returns (bool ok)
    {
        return true;
    }

    function balanceOf(address token, address user) constant returns (uint) {
        return tokens[token][user];
    }

    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orders[msg.sender][hash] = true;
        Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(
        (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
        block.number <= expires &&
        safeAdd(orderFills[user][hash], amount) <= amountGet
        )) revert();
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
        Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
    }

    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {

        if (now < freeUntilDate) {
            uint feeMakeXfer = 0;
            uint feeTakeXfer = 0;
        } else {
            uint feeMakeXfer = safeMul(amount, feeMake) / (1 ether);
            uint feeTakeXfer = safeMul(amount, feeTake) / (1 ether);
        }

        tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
        tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSub(amount, feeMakeXfer));
        tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeAdd(feeMakeXfer, feeTakeXfer));
        tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
        tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
    }

    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns (uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderFills[user][hash];
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(orders[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender)) revert();
        orderFills[msg.sender][hash] = amountGet;
        Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }
}