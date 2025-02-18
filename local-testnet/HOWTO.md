# How to run local testnet with one coprocessor

1. Ensure you are in local-testnet folder
2. Run `./setup.sh`
    1. This command will among other steps generate fhe keys in fhevm-keys

> [!NOTE]
> Be careful! fhevm-go-copro expects FHE keys in the FHEVM_GO_KEYS_DIR environment variable. If this variable is already set globally, it could potentially overwrite the environment variable provided to the RPC node. 
3. Check you have 4 tmux sessions
 ```bash
tmux ls
bootnode: 1 windows (created Thu Apr 25 15:07:05 2024)
rpc1: 1 windows (created Thu Apr 25 15:07:05 2024)
val1: 1 windows (created Thu Apr 25 15:07:05 2024)
val2: 1 windows (created Thu Apr 25 15:07:05 2024)
 ```

 4. Attach to rpc1 node
 ```bash
 tmux a -t rpc1
 ```

5. Open **Metamask** and import a new account with the following private key:
 `d4251c2bca983ae6d2e19e728ec7fd8b80002cde2ee5c21f3f243fad82852386`


Add a **new network** in **Metamask** with the following parameters:

- Network name: `co-pro`
- New RPC URL: `http://127.0.0.1:8745`
- Chain ID: `12345`
- Currency symbol: `LETH`

6. Click on switch to **co-pro**

7. You should have 1 LETH

8. Open [Remix](https://remix.ethereum.org/)

9. Connect your Metamask account with Remix (using __Injected Provider Metamask__)

10. Create a new contracts with the following test content

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract FhevmCoproc {
  // for debugging only
  function trivialEncrypt(uint32 input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  // for debugging only
  function decrypt(uint256 input) public pure returns (uint256) {
    return input;
  }

  function fheAdd(uint256 lhs, uint256 rhs, bytes1 scalar) public pure returns (uint256) {
    uint8 fheOp = 0;
    return uint256(keccak256(abi.encodePacked(fheOp, lhs, rhs, scalar)));
  }
}
```

10. In Solidity Compiler tab downgrade compiler to **0.8.19+commit** version and **Compile**

11. In deploy tab, deploy your smart contract

You should see in rpc log:
```bash
INFO [04-25|15:47:01.590] Submitted contract creation              hash=0xdcc33a885d5b4424131e8802511eaddcce04aaa6b5b68823f453c801447f169a from=0x1181A1FB7B6de97d4CB06Da82a0037DF1FFe32D0 nonce=1 contract=0x6819e3aDc437fAf9D533490eD3a7552493fCE3B1 value=0
```

12. The deployed address should be the same one as defined in **setup.sh**

`0x6819e3aDc437fAf9D533490eD3a7552493fCE3B1`

13. Now you can interact with the smart contract.

14. First call Trivial encrypt with a value.

```bash
INFO [04-25|16:02:23.427] Executing coprocessor payload            input=6d02b1f30000000000000000000000000000000000000000000000000000000000000005 output=920ae4155769cd69c30626f054134b5f003772473f57f84837402df6d166e663
```

15. Copy output value in the log wich corresponds to the handle of the ciphertext

16. Decrypt it by adding 0x in front of the handle in **Decrypt method** in Remix

17. You should see the plaintext value in the log.

```bash
Executing coprocessor payload            input=5a4ee440920ae4155769cd69c30626f054134b5f003772473f57f84837402df6d166e663 output=920ae4155769cd69c30626f054134b5f003772473f57f84837402df6d166e663
Executing captured operation decrypt(uint256)
Handle 920ae4155769cd69c30626f054134b5f003772473f57f84837402df6d166e663 points to ciphertext decryption of [5]

```

18. You can call FheAdd by giving two handles and 0x00 at the end of the parameter:

`0x920ae4155769cd69c30626f054134b5f003772473f57f84837402df6d166e663, 0x920ae4155769cd69c30626f054134b5f003772473f57f84837402df6d166e663, 0x00`

19. Copy the handle and decrypt it again

```bash
Executing coprocessor payload            input=5a4ee4403eccf67746858051703095ccf88517351d71412618e5205651f460bf2c692e8b output=3eccf67746858051703095ccf88517351d71412618e5205651f460bf2c692e8b
Executing captured operation decrypt(uint256)
Handle 3eccf67746858051703095ccf88517351d71412618e5205651f460bf2c692e8b points to ciphertext decryption of [10]

```

