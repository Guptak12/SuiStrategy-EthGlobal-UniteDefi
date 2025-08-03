import { type ContractRunner } from "ethers";
import type { IUniERC20Wrapper, IUniERC20WrapperInterface } from "../../../../../contracts/tests/mocks/UniERC20Helper.sol/IUniERC20Wrapper";
export declare class IUniERC20Wrapper__factory {
    static readonly abi: readonly [{
        readonly inputs: readonly [{
            readonly internalType: "address payable";
            readonly name: "from";
            readonly type: "address";
        }, {
            readonly internalType: "address";
            readonly name: "to";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "amount";
            readonly type: "uint256";
        }];
        readonly name: "transferFrom";
        readonly outputs: readonly [];
        readonly stateMutability: "payable";
        readonly type: "function";
    }];
    static createInterface(): IUniERC20WrapperInterface;
    static connect(address: string, runner?: ContractRunner | null): IUniERC20Wrapper;
}
