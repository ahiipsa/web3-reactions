import {ethers, network} from "hardhat";
import { expect } from "chai";
import { Contract} from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Reactions", function () {
  let reactionsContract: Contract;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  const widgetId = '63982991313271193396585598611485285442926986849639588830131034967830111525590';

  beforeEach(async function () {
    await network.provider.send("hardhat_reset")
    const ReactionsContractFactory = await ethers.getContractFactory("Reactions");
    [owner, user1, user2] = await ethers.getSigners();

    reactionsContract = await ReactionsContractFactory.deploy();
    await reactionsContract.deployed();

    // Create a widget
    await reactionsContract.createWidget(0); // 0 for single type widget
  });

  it('should allow users to create widget', async function () {
    await reactionsContract.createWidget(1); // 0 for single type widget

    const widgetList = await reactionsContract.getMyWidgets()

    expect(widgetList[1].ownerAddress).to.equal(owner.address);
    expect(widgetList[1].widgetType).to.equal(1);
  });

  it("should allow users to create reactions", async function () {
    const emojiId = 1;

    // User 1 creates a reaction
    await reactionsContract.connect(user1).createReaction(widgetId, emojiId);
    const reactions1 = await reactionsContract.getWidgetReactions(widgetId);

    expect(reactions1.length).to.equal(1);
    expect(reactions1[0].ownerAddress).to.equal(user1.address);
    expect(reactions1[0].emojiId).to.equal(emojiId);

    // User 2 creates a reaction
    await reactionsContract.connect(user2).createReaction(widgetId, emojiId);
    const reactions2 = await reactionsContract.getWidgetReactions(widgetId);

    expect(reactions2.length).to.equal(2);
    expect(reactions2[1].ownerAddress).to.equal(user2.address);
    expect(reactions2[1].emojiId).to.equal(emojiId);


  });

  it("should allow users to change their reactions", async function () {
    const emojiId = 1;
    const newEmojiId = 2;

    // User 1 creates a reaction
    await reactionsContract.connect(user1).createReaction(widgetId, emojiId);
    const reactions1 = await reactionsContract.getWidgetReactions(widgetId);
    expect(reactions1.length).to.equal(1);
    expect(reactions1[0].ownerAddress).to.equal(user1.address);
    expect(reactions1[0].emojiId).to.equal(emojiId);

    // User 1 changes their reaction
    await reactionsContract.connect(user1).changeReaction(widgetId, newEmojiId);
    const reactions = await reactionsContract.getWidgetReactions(widgetId);

    expect(reactions[0].ownerAddress).to.equal(user1.address);
    expect(reactions[0].emojiId).to.equal(newEmojiId);
  });

  it("should allow users to remove their reactions", async function () {
    const emojiId = 1;
    // User 1 creates a reaction
    await reactionsContract.connect(user1).createReaction(widgetId, emojiId);

    // User 1 removes their reaction
    await reactionsContract.connect(user1).removeReaction(widgetId);
    const reactions = await reactionsContract.getWidgetReactions(widgetId);

    expect(reactions.length).to.equal(1);
    expect(reactions[0].ownerAddress).to.equal('0x0000000000000000000000000000000000000000');
  });

  it('should allow users to get widget by id', async function () {
    const widget = await reactionsContract.connect(user1).getWidget(widgetId)
    expect(widget.ownerAddress).to.equal('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266');
    expect(widget.widgetType).to.equal(0);
    expect(widget.id).to.equal(widgetId);
  });
});