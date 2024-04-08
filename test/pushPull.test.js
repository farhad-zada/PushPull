const { ethers, waffle, upgrades } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = ethers;

describe("PushPull", function () {
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

  it("deployed successfully", async function () {
    expect(pushPull.target).to.be.not.NaN;
  });

  it("token is correct", async function () {
    expect(await pushPull.token()).to.be.equal(token.target);
  });

  it("owner is admin", async function () {
    expect(await pushPull.admins(owner)).to.be.true;
  });

  it("addr1 is not admin", async function () {
    expect(await pushPull.admins(addr1)).to.be.false;
  });

  it("admin can push to chain", async function () {
    expect(await token.balanceOf(addr1)).to.be.equal(0);
    await pushPull.connect(owner).toOnChain(addr1, parseEther("100"));
    expect(await token.balanceOf(addr1)).to.be.equal(parseEther("100"));
  });

  it("non-admin cannot push to chain", async function () {
    await expect(
      pushPull.connect(addr1).toOnChain(addr1, parseEther("100"))
    ).to.be.revertedWithCustomError(PushPull, "OnlyAdmin");
  });

  it("without allowance cannot pull from chain", async function () {
    await expect(
      pushPull.connect(addr1).toOffChain(parseEther("100"))
    ).to.be.revertedWithCustomError(PushPull, "InsufficientAllowance");
  });

  it("anyone with token can pull from chain", async function () {
    expect(await token.balanceOf(addr2)).to.be.equal(parseEther("100000"));
    await token.connect(addr2).approve(pushPull.target, parseEther("100000"));
    await pushPull.connect(addr2).toOffChain(parseEther("100"));
    expect(await token.balanceOf(addr2)).to.be.equal(parseEther("99900"));
  });

  it("only owner can set admin", async function () {
    await expect(
      pushPull.connect(addr1).setAdmin(addr1, true)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("owner can set admin", async function () {
    expect(await pushPull.admins(addr1)).to.be.false;
    await pushPull.connect(owner).setAdmin(addr1, true);
    expect(await pushPull.admins(addr1)).to.be.true;
  });

  it("owner can remove admin", async function () {
    expect(await pushPull.admins(addr1)).to.be.false;
    await pushPull.connect(owner).setAdmin(addr1, true);
    expect(await pushPull.admins(addr1)).to.be.true;
    await pushPull.connect(owner).setAdmin(addr1, false);
    expect(await pushPull.admins(addr1)).to.be.false;
  });

  it("admin can renounce adminship", async function () {
    expect(await pushPull.admins(addr1)).to.be.false;
    await pushPull.connect(owner).setAdmin(addr1, true);
    expect(await pushPull.admins(addr1)).to.be.true;
    await pushPull.connect(addr1).renounceAdmin();
    expect(await pushPull.admins(addr1)).to.be.false;
  });
});
