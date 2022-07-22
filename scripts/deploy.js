const { ethers } = require("hardhat");

async function main(){
    const NFTMarket = await ethers.getContractFactory("MyNFTMarket");
    const NFTmarket = await NFTMarket.deploy();
    const myNFT = await ethers.getContractFactory("MyNFT");
    const MyNFT = await myNFT.deploy();

    console.log("Marketplace Contract has been deployed to ",NFTmarket.address);
    console.log("NFT Contract has been deployed to ",MyNFT.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.log(error)
    process.exit(1)
})