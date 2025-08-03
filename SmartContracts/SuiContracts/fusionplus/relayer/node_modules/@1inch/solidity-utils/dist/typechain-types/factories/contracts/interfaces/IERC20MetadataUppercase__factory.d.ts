import { type ContractRunner } from "ethers";
import type { IERC20MetadataUppercase, IERC20MetadataUppercaseInterface } from "../../../contracts/interfaces/IERC20MetadataUppercase";
export declare class IERC20MetadataUppercase__factory {
    static readonly abi: readonly [{
        readonly inputs: readonly [];
        readonly name: "NAME";
        readonly outputs: readonly [{
            readonly internalType: "string";
            readonly name: "";
            readonly type: "string";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [];
        readonly name: "SYMBOL";
        readonly outputs: readonly [{
            readonly internalType: "string";
            readonly name: "";
            readonly type: "string";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }];
    static createInterface(): IERC20MetadataUppercaseInterface;
    static connect(address: string, runner?: ContractRunner | null): IERC20MetadataUppercase;
}
