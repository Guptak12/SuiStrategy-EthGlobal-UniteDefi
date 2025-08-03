import { type ContractRunner } from "ethers";
import type { ICreate3Deployer, ICreate3DeployerInterface } from "../../../contracts/interfaces/ICreate3Deployer";
export declare class ICreate3Deployer__factory {
    static readonly abi: readonly [{
        readonly inputs: readonly [{
            readonly internalType: "bytes32";
            readonly name: "salt";
            readonly type: "bytes32";
        }];
        readonly name: "addressOf";
        readonly outputs: readonly [{
            readonly internalType: "address";
            readonly name: "";
            readonly type: "address";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "bytes32";
            readonly name: "salt";
            readonly type: "bytes32";
        }, {
            readonly internalType: "bytes";
            readonly name: "code";
            readonly type: "bytes";
        }];
        readonly name: "deploy";
        readonly outputs: readonly [{
            readonly internalType: "address";
            readonly name: "";
            readonly type: "address";
        }];
        readonly stateMutability: "nonpayable";
        readonly type: "function";
    }];
    static createInterface(): ICreate3DeployerInterface;
    static connect(address: string, runner?: ContractRunner | null): ICreate3Deployer;
}
