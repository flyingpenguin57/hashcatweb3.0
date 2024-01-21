const { expect } = require("chai");

const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Basic contract", function () {

    async function deployBasicFixture() {
        // Get the Signers here.
        const [owner, addr1, addr2] = await ethers.getSigners();

        // To deploy our contract, we just have to call ethers.deployContract and await
        // its waitForDeployment() method, which happens once its transaction has been
        // mined.
        const basic = await ethers.deployContract("Basic");

        await basic.waitForDeployment();

        // Fixtures can return anything you consider useful for your tests
        return { basic, owner, addr1, addr2 };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { basic, owner } = await loadFixture(deployBasicFixture);

            expect(await basic.owner()).to.equal(owner.address);
        });

        it("Should init a commander", async function () {
            const { basic } = await loadFixture(deployBasicFixture);

            const initCommander = await basic.commanders(0);
            expect(initCommander.name).to.equal("init");
        });
    })

    describe("Operation", function() {
        it("Operation", async function() {
            const {basic, owner, addr1} = await loadFixture(deployBasicFixture);
            
            //owner create commander
            await basic.createCommander("xiaoli");
            let newCommander = await basic.commanders(1);
            expect(newCommander[0]).to.equal("xiaoli");
            expect(await basic.ownerToCommander(owner.address)).to.equal(1);

            //second time create commander will fail
            try {
               await basic.createCommander("xiaowang"); 
            } catch (e) {
                expect(e).not.undefined;
                console.log(e);
            }

            //addr1 create commander
            await basic.connect(addr1).createCommander("xiaohong");
            let addr1Commander = await basic.commanders(2);
            expect(addr1Commander[0]).to.equal("xiaohong");
            expect(await basic.ownerToCommander(addr1.address)).to.equal(2);

            //owner modify commander name
            await basic.modifyCommanderName("xiaowangm");
            let ownerCommanderID = await basic.ownerToCommander(owner.address);
            let ownerCommander = await basic.commanders(ownerCommanderID);
            expect(ownerCommander[0]).to.equal("xiaowangm");

            //addr1 modify commander name
            await basic.connect(addr1).modifyCommanderName("xiaohongm");
            let addr1CommanderID = await basic.ownerToCommander(addr1.address);
            let addr1CommanderAfterModify = await basic.commanders(addr1CommanderID);
            expect(addr1CommanderAfterModify[0]).to.equal("xiaohongm");

            //owenr coin two robot 
            await basic.createRobot("123456uuu");
            await basic.createRobot("123456ooo");
            ownerRobotDnas = await basic.getMyRobots();
            console.log(ownerRobotDnas);
            expect(ownerRobotDnas.length).to.equal(2);
        })

    })

});