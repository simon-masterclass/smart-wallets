//SPDX-License-Identifier: MIT

/// @author @TomsCourses (youtube channel)
/// @author simon-masterclass (github username) = SGI
/// @zeroarmy

pragma solidity 0.8.15;

contract WalletWithGuardians {
    address payable public owner; //TEMPORARILY public
    address payable public nextOwner; //TEMPORARILY public

    mapping(address => uint256) public allowance;
    mapping(address => bool) public isAllowedToSend;

    //Struct contains data necessary to ensure 3/5 votes don't get double counted. -SGI
    struct guardianData {
        bool isGuardian;
        uint8 index_arrayTF;
    }

    //Array of bools to enable tracking who has and hasn't voted. -SGI
    bool[5] guardianVotedTF;

    mapping(address => guardianData) public guardians;
    uint256 public guardiansResetCount; //TEMPORARILY public
    uint256 public constant confirmationsFromGuardiansForReset = 3;

    constructor() {
        owner = payable(msg.sender);
    }

    //Function for resettinng all bools back to False after voting. -SGI
    function resetVotedTFarray() internal {
        for (uint8 i = 0; i < 5; i++) {
            guardianVotedTF[i] = false;
        }
    }

    function proposeNewOwner(address payable newOwner) public {
        require(
            guardians[msg.sender].isGuardian,
            "You are not a guardian, aborting."
        );
        if (nextOwner != newOwner) {
            nextOwner = newOwner;
            guardiansResetCount = 0;
            //reset voting bools to False after a new candidate is proposed. -SGI
            resetVotedTFarray();
        }
        //Require guardians to have NOT voted before. -SGI
        require(
            guardianVotedTF[guardians[msg.sender].index_arrayTF] == false,
            "You have already voted, aborting."
        );

        guardiansResetCount++;
        //This array of T/F values guards against double voting using the require statement above -SGI
        guardianVotedTF[guardians[msg.sender].index_arrayTF] = true;

        if (guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
            //reset voting bools -SGI
            resetVotedTFarray();
        }
    }

    function setAllowance(address _from, uint256 _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        allowance[_from] = _amount;
        isAllowedToSend[_from] = true;
    }

    function setGuardian(
        address _guardian,
        bool _setTF,
        uint8 _indexTF
    ) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        require(
            (_indexTF >= 0 && _indexTF < 5),
            "index is out of range, aborting!"
        );

        guardians[_guardian].isGuardian = _setTF;
        guardians[_guardian].index_arrayTF = _indexTF;
    }

    function denySending(address _from) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        isAllowedToSend[_from] = false;
    }

    function transfer(
        address payable _to,
        uint256 _amount,
        bytes memory payload
    ) public returns (bytes memory) {
        require(
            _amount <= address(this).balance,
            "Can't send more than the contract owns, aborting."
        );
        if (msg.sender != owner) {
            require(
                isAllowedToSend[msg.sender],
                "You are not allowed to send any transactions, aborting"
            );
            require(
                allowance[msg.sender] >= _amount,
                "You are trying to send more than you are allowed to, aborting"
            );
            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(
            payload
        );
        require(success, "Transaction failed, aborting");
        return returnData;
    }

    receive() external payable {}
}

contract consumer {
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {}
}
