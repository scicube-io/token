var Owned = artifacts.require("Owned");
var SCX = artifacts.require("SCX");
var StatusContribution = artifacts.require("StatusContribution");
var SciCube = artifacts.require("SciCube");
var SciCubeFactory = artifacts.require("SciCubeFactory");

var Web3 = require('web3');
var web3 = new Web3(
    new Web3.providers.HttpProvider('http://localhost:8545')
);


contract('SCX', function (accounts) {
    it("generate 12312 token in the owner account (Testnet-Access)", function () {
        var i;
        var generateTokenAmount = 12312;

        return SCX.deployed().then(function (instance) {
            i = instance;
            return i.generateTokens(accounts[0], generateTokenAmount);
        }).then(function (receipt) {
            return i.balanceOf(accounts[0]);
        }).then(function (balanceOfOwner) {
            assert.equal(balanceOfOwner.toNumber(), generateTokenAmount, "token generation failed");
        });
    });

    it("approve debit from account one to account two (Testnet-Transfer)", function () {
        var meta;
        var targetAmount = 100;
        var transferAmount = 100;
        var acc3_balance_before;

        return SCX.deployed().then(function (instance) {
            meta = instance;
            return meta.approve(accounts[1], targetAmount);
        }).then(function () {
            return meta.balanceOf(accounts[3]);
        }).then(function (balance) {
            acc3_balance_before = balance.toNumber();
            return meta.debit(accounts[0], accounts[1]);
        }).then(function (debit) {
            assert.equal(debit.toNumber(), targetAmount, "approve debit failed");
            return meta.transferFrom(accounts[0], accounts[3], transferAmount, { from: accounts[1] });
        }).then(function () {
            return meta.balanceOf(accounts[3]);
        }).then(function (balance) {
            assert(balance.toNumber(), acc3_balance_before, "delegate transfer failed");
        });
    });

    it("approve debit from account one to account two (Testnet-Transfer) but fail", function () {
        var i;
        var targetAmount = 100;
        var transferAmount = 1000;
        var acc3_balance_before;

        return SCX.deployed().then(function (instance) {
            i = instance;
            return i.approve(accounts[1], targetAmount);
        }).then(function () {
            return i.balanceOf(accounts[3]);
        }).then(function (balance) {
            acc3_balance_before = balance.toNumber();
            return i.debit(accounts[0], accounts[1]);
        }).then(function (debit) {
            assert.equal(debit.toNumber(), targetAmount, "approve debit failed");
            return i.transferFrom(accounts[0], accounts[3], transferAmount, { from: accounts[1] });
        }).then(function () {
            return i.balanceOf(accounts[3]);
        }).then(function (balance) {
            assert(balance.toNumber(), acc3_balance_before, "delegate transfer failed");
        });
    });
    
});


contract('Owned', function (accounts) {
    it("test owner address is the base address", function () {
        var meta;

        return Owned.deployed().then(function (instance) {
            meta = instance;
            return meta.owner();
        }).then(function (owner) {
            assert.equal(accounts[0], owner, "owner is not the first account");
        });
    });
});