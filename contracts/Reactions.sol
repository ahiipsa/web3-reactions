// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// Uncomment this line to use console.log
 import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Reactions is Ownable {
    enum WidgetType {Single, Multi}

    struct Widget {
        uint256 id;
        address ownerAddress;
        WidgetType widgetType;
    }

    struct Reaction {
        address ownerAddress;
        uint256 widgetId;
        uint256 emojiId;
    }

    struct InitConfiguration {
        uint256 reactionPrice;
    }

    mapping(uint256 => address) private idToAddress;
    mapping(uint256 => uint256) private idToToValue;

    constructor(InitConfiguration memory _initConfig) {
        setReactionPrice(_initConfig.reactionPrice);
    }

    function buildId(address _address, uint256 _value) public pure returns (uint256) {
        uint256 id = uint256(keccak256(abi.encodePacked(_address, _value)));
        return id;
    }

    function createId(address _address, uint256 _value) public {
        uint256 id = buildId(_address, _value);
        idToAddress[id] = _address;
        idToToValue[id] = _value;
    }

    function reverseId(uint256 _id) public view returns (address, uint256) {
        address _address = idToAddress[_id];
        uint256 _value = idToToValue[_id];
        return (_address, _value);
    }

    uint256 private widgetCounter;
    uint256 private reactionPrice;
    mapping(address => Widget[]) private widgets;
    mapping(uint256 => Reaction[]) public widgetReactions;

    event WidgetCreated(uint256 id, address ownerAddress, WidgetType widgetType);
    event ReactionCreated(address ownerAddress, uint256 widgetId, uint256 emojiId);
    event ReactionChanged(address ownerAddress, uint256 widgetId, uint256 emojiId);
    event ReactionRemoved(address ownerAddress, uint256 widgetId);

    function setReactionPrice(uint256 price) public onlyOwner {
        reactionPrice = price;
    }

    function getReactionPrice() external view returns (uint256) {
        return reactionPrice;
    }

    function createWidget(WidgetType widgetType) external {
        widgetCounter++;
        uint256 index = widgets[msg.sender].length;
        uint256 widgetId = buildId(msg.sender, index);
        createId(msg.sender, index);
        Widget memory newWidget = Widget(widgetId, msg.sender, widgetType);

        widgets[msg.sender].push(newWidget);

        emit WidgetCreated(widgetId, msg.sender, widgetType);
    }

    function createReaction(uint256 widgetId, uint256 emojiId) external payable {
        uint256 receivedAmount = msg.value;
        require(receivedAmount >= reactionPrice, "Insufficient received amount");

        (address addr, uint256 index) = reverseId(widgetId);
        require(widgets[addr][index].ownerAddress != address(0), "Widget does not exist");

        Reaction memory newReaction = Reaction(msg.sender, widgetId, emojiId);
        widgetReactions[widgetId].push(newReaction);

        emit ReactionCreated(msg.sender, widgetId, emojiId);

        // Return any excess funds
        uint256 excess = receivedAmount - reactionPrice;
        if (excess > 0) {
            (bool success,) = msg.sender.call{value : excess}("");
            require(success, "cannot refund excess");
        }
    }

    function changeReaction(uint256 widgetId, uint256 emojiId) external payable {
        uint256 receivedAmount = msg.value;
        require(receivedAmount >= reactionPrice, "Insufficient received amount");

        (address addr, uint256 index) = reverseId(widgetId);
        require(widgets[addr][index].ownerAddress != address(0), "Widget does not exist");
        Reaction[] storage reactions = widgetReactions[widgetId];

        uint256 excess = receivedAmount - reactionPrice;
        if (excess > 0) {
            (bool success,) = msg.sender.call{value : excess}("");
            require(success, "cannot refund excess");
        }

        for (uint256 i = 0; i < reactions.length; i++) {
            if (reactions[i].ownerAddress == msg.sender) {
                reactions[i].emojiId = emojiId;
                emit ReactionChanged(msg.sender, widgetId, emojiId);
                // Return any excess funds
                return;
            }
        }

        revert("Reaction not found");
    }

    function _removeReaction(
        uint256 widgetId,
        uint256 index
    ) internal {
        if (index >= widgetReactions[widgetId].length) return;

        for (uint i = index; i < widgetReactions[widgetId].length - 1; i++) {
            widgetReactions[widgetId][i] = widgetReactions[widgetId][i+1];
        }
        widgetReactions[widgetId].pop();
    }

    function removeReaction(uint256 widgetId) external payable {
        uint256 receivedAmount = msg.value;
        require(receivedAmount >= reactionPrice, "Insufficient received amount");

        (address addr, uint256 index) = reverseId(widgetId);
        require(widgets[addr][index].ownerAddress != address(0), "Widget does not exist");
        Reaction[] storage reactions = widgetReactions[widgetId];

        uint256 excess = receivedAmount - reactionPrice;
        if (excess > 0) {
            (bool success,) = msg.sender.call{value : excess}("");
            require(success, "cannot refund excess");
        }
        for (uint256 i = 0; i < reactions.length; i++) {
            if (reactions[i].ownerAddress == msg.sender) {
                _removeReaction(widgetId, i);
                emit ReactionRemoved(msg.sender, widgetId);
                return;
            }
        }

        revert("Reaction not found");
    }

    function getWidgetReactions(uint256 widgetId) external view returns (Reaction[] memory) {
        return widgetReactions[widgetId];
    }

    function getMyWidgets() external view returns (Widget[] memory) {
        return widgets[msg.sender];
    }

    function getWidget(uint256 widgetId) external view returns (Widget memory) {
        (address addr, uint256 index) = reverseId(widgetId);
        return widgets[addr][index];
    }
}