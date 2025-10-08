// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

contract ChrnoVault {
    struct Capusle {
        address owner;
        uint256 unlockTime;
        string ipfsHash;
        bool unlocked;
    }

    uint256 public capsuleCount = 0;
    mapping(uint256 => Capusle) public capsules;

    event CapsuleCreated(uint256 capsuleId, address owner, uint256 unlockTime, string ipfsHash);
    event CapsuleUnlocked(uint256 capsuleId);

    function createCapusle(string memory ipfsHash, uint256 unlockTime) external {
        require(unlockTime > block.timestamp, "Unlock time must be in the future");

        capsules[capsuleCount] = Capusle({
            owner: msg.sender,
            unlockTime: unlockTime,
            ipfsHash: ipfsHash,
            unlocked: false
        });

        emit CapsuleCreated(capsuleCount, msg.sender, unlockTime, ipfsHash);
        capsuleCount++;
    }

    function unlockCapsule(uint256 capsuleId) external {
        Capusle storage capsule = capsules[capsuleId];
        require(msg.sender == capsule.owner, "Only the owner can unlock the capsule");
        require(block.timestamp >= capsule.unlockTime, "Capsule is still locked");
        require(!capsule.unlocked, "Capsule already unlocked");

        capsule.unlocked = true;
        emit CapsuleUnlocked(capsuleId);
    }

    function getCapsule(uint256 capsuleId) external view returns (Capusle memory) {
        return capsules[capsuleId];
    }

   
}