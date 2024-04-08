const { ethers, waffle, upgrades } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = ethers;

module.exports = () => {
  let PushPull;
  let pushPull;
  let Token;
  let token;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    Token = await ethers.getContractFactory("Token");
    token = await upgrades.deployProxy(Token, {
      initializer: "initialize",
      kind: "transparent",
    });

    PushPull = await ethers.getContractFactory("PushPull");
    pushPull = await upgrades.deployProxy(PushPull, [token.target], {
      initializer: "initialize",
      kind: "transparent",
    });
    await token.transfer(pushPull.target, parseEther("100000"));
    await token.transfer(addr2, parseEther("100000"));
  });

  it("owner can withdraw", async () => {
    expect(await token.balanceOf(addr1)).to.be.equal(0);
    await pushPull
      .connect(owner)
      .withdraw(token.target, addr1, parseEther("100"));
    expect(await token.balanceOf(addr1)).to.be.equal(parseEther("100"));
  });

  it("non-owner cannot withdraw", async () => {
    await expect(
      pushPull.connect(addr1).withdraw(token.target, addr1, parseEther("100"))
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("native token can be withdraw by passing address(0)", async () => {
    expect(await token.balanceOf(addr1)).to.be.equal(0);
    // send ethers to contract address
    await owner.sendTransaction({
      to: pushPull.target,
      value: parseEther("1"),
    });

    expect(await ethers.provider.getBalance(pushPull.target)).to.be.equal(
      parseEther("1")
    );
    await pushPull
      .connect(owner)
      .withdraw(
        "0x0000000000000000000000000000000000000000",
        addr1,
        parseEther("1")
      );

    expect(await ethers.provider.getBalance(pushPull.target)).to.be.equal(0);
  });
};
