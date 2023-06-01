// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Reactions {
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


    mapping(uint256 => address) private idToAddress;
    mapping(address => uint256) private addressToId;

    function createId(address _address, uint256 _value) public returns (uint256) {
        uint256 id = uint256(keccak256(abi.encodePacked(_address, _value)));
        idToAddress[id] = _address;
        addressToId[_address] = _value;
        return id;
    }

    function reverseId(uint256 _id) public view returns (address, uint256) {
        address _address = idToAddress[_id];
        uint256 _value = addressToId[_address];
        return (_address, _value);
    }

    uint256 private widgetCounter;
    mapping(address => Widget[]) private widgets;
    mapping(uint256 => Reaction[]) public widgetReactions;

    event WidgetCreated(uint256 id, address ownerAddress, WidgetType widgetType);
    event ReactionCreated(address ownerAddress, uint256 widgetId, uint256 emojiId);
    event ReactionChanged(address ownerAddress, uint256 widgetId, uint256 emojiId);
    event ReactionRemoved(address ownerAddress, uint256 widgetId);

    function createWidget(WidgetType widgetType) external {
        widgetCounter++;
        uint256 index = widgets[msg.sender].length;
        uint256 widgetId = createId(msg.sender, index);
        Widget memory newWidget = Widget(widgetId, msg.sender, widgetType);

        widgets[msg.sender].push(newWidget);

        emit WidgetCreated(widgetId, msg.sender, widgetType);
    }

    function createReaction(uint256 widgetId, uint256 emojiId) external {
        (address addr, uint256 index) = reverseId(widgetId);
        require(widgets[addr][index].ownerAddress != address(0), "Widget does not exist");

        Reaction memory newReaction = Reaction(msg.sender, widgetId, emojiId);
        widgetReactions[widgetId].push(newReaction);

        emit ReactionCreated(msg.sender, widgetId, emojiId);
    }

    function changeReaction(uint256 widgetId, uint256 emojiId) external {
        (address addr, uint256 index) = reverseId(widgetId);
        require(widgets[addr][index].ownerAddress != address(0), "Widget does not exist");
        Reaction[] storage reactions = widgetReactions[widgetId];

        for (uint256 i = 0; i < reactions.length; i++) {
            if (reactions[i].ownerAddress == msg.sender) {
                reactions[i].emojiId = emojiId;
                emit ReactionChanged(msg.sender, widgetId, emojiId);
                return;
            }
        }

        revert("Reaction not found");
    }

    function removeReaction(uint256 widgetId) external {
        (address addr, uint256 index) = reverseId(widgetId);
        require(widgets[addr][index].ownerAddress != address(0), "Widget does not exist");
        Reaction[] storage reactions = widgetReactions[widgetId];

        for (uint256 i = 0; i < reactions.length; i++) {
            if (reactions[i].ownerAddress == msg.sender) {
                delete reactions[i];
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