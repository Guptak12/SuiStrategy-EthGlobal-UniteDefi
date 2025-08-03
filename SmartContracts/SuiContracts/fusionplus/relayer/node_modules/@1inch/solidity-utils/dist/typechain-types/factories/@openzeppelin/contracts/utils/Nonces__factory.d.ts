import { type ContractRunner } from "ethers";
import type { Nonces, NoncesInterface } from "../../../../@openzeppelin/contracts/utils/Nonces";
export declare class Nonces__factory {
    static readonly abi: readonly [{
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "account";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "currentNonce";
            readonly type: "uint256";
        }];
        readonly name: "InvalidAccountNonce";
        readonly type: "error";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "owner";
            readonly type: "address";
        }];
        readonly name: "nonces";
        readonly outputs: readonly [{
            readonly internalType: "uint256";
            readonly name: "";
            readonly type: "uint256";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }];
    static createInterface(): NoncesInterface;
    static connect(address: string, runner?: ContractRunner | null): Nonces;
}
