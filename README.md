# Multicall Proxy

Upgradeable (UUPS) multicall contract.

- `multicall` — admins batch arbitrary calls (with ETH value). Reverts the
  whole batch if any call fails, bubbling the target's revert reason.
- `multiview` — anyone batches `staticcall`s to view functions.
- Owner manages admins (`setAdmins`) and upgrades (`upgradeTo`).

Built with Foundry, solc `0.8.19`, OpenZeppelin Contracts `v4.9.6`.

## Build

```shell
git clone --recursive <repo-url>   # or: git submodule update --init --recursive
forge build
forge test
```

## Deploy

```shell
cp .env.example .env
```

| Var | Required | Description |
|---|---|---|
| `RPC_URL` | yes | Network RPC endpoint |
| `PRIVATE_KEY` | yes | Deployer key |
| `OWNER` | no | Final owner, defaults to deployer |
| `ADMINS` | no | Comma-separated admin addresses |
| `ETHERSCAN_API_KEY` | no | Needed for `--verify` |

```shell
source .env
forge script script/Multicall.s.sol:MulticallScript \
  --rpc-url $RPC_URL --broadcast --verify
```

The script deploys the implementation and an `ERC1967Proxy`, sets `ADMINS`,
then transfers ownership to `OWNER`. Use the logged **proxy** address.

## Usage

```shell
export PROXY=<proxy address>
```

### Manage admins (owner)

```shell
cast send $PROXY "setAdmins(address[],bool[])" \
  "[0xAdmin1,0xAdmin2]" "[true,false]" \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast call $PROXY "isAdmins(address)(bool)" 0xAdmin1 --rpc-url $RPC_URL
```

### multicall (admin)

`targets`, `values`, `datas` must have equal length. Send `--value` equal
to the sum of `values`.

```shell
cast send $PROXY "multicall(address[],uint256[],bytes[])" \
  "[$TOKEN,0xRecipient]" \
  "[0,1000000000000000]" \
  "[$(cast calldata 'transfer(address,uint256)' 0xTo 100),0x]" \
  --value 0.001ether \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### multiview (anyone)

Returns `bytes[]`, one ABI-encoded result per call.

```shell
cast call $PROXY "multiview(address[],bytes[])(bytes[])" \
  "[$TOKEN,$TOKEN]" \
  "[$(cast calldata 'totalSupply()'),$(cast calldata 'decimals()')]" \
  --rpc-url $RPC_URL

cast abi-decode "f()(uint256)" <result>
```

From Solidity:

```solidity
bytes[] memory r = Multicall(payable(proxy)).multiview(targets, datas);
uint256 supply = abi.decode(r[0], (uint256));
```

### Upgrade (owner)

```shell
forge create src/Multicall.sol:Multicall \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
cast send $PROXY "upgradeTo(address)" <new implementation> \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

Keep the storage layout append-only when changing the contract.
