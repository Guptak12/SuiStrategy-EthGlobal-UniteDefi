import type { BaseContract, BigNumberish, BytesLike, FunctionFragment, Result, Interface, AddressLike, ContractRunner, ContractMethod, Listener } from "ethers";
import type { TypedContractEvent, TypedDeferredTopicFilter, TypedEventLog, TypedListener, TypedContractMethod } from "../../../../common";
export interface SafeERC20WrapperInterface extends Interface {
    getFunction(nameOrSignature: "allowance" | "approve" | "balanceOf" | "decreaseAllowance" | "increaseAllowance" | "permit" | "setAllowance" | "transfer" | "transferFrom" | "transferFromUniversal"): FunctionFragment;
    encodeFunctionData(functionFragment: "allowance", values?: undefined): string;
    encodeFunctionData(functionFragment: "approve", values: [BigNumberish]): string;
    encodeFunctionData(functionFragment: "balanceOf", values?: undefined): string;
    encodeFunctionData(functionFragment: "decreaseAllowance", values: [BigNumberish]): string;
    encodeFunctionData(functionFragment: "increaseAllowance", values: [BigNumberish]): string;
    encodeFunctionData(functionFragment: "permit", values: [
        AddressLike,
        AddressLike,
        BigNumberish,
        BigNumberish,
        BigNumberish,
        BytesLike,
        BytesLike
    ]): string;
    encodeFunctionData(functionFragment: "setAllowance", values: [BigNumberish]): string;
    encodeFunctionData(functionFragment: "transfer", values?: undefined): string;
    encodeFunctionData(functionFragment: "transferFrom", values?: undefined): string;
    encodeFunctionData(functionFragment: "transferFromUniversal", values: [boolean]): string;
    decodeFunctionResult(functionFragment: "allowance", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "approve", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "balanceOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "decreaseAllowance", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "increaseAllowance", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "permit", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "setAllowance", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "transfer", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "transferFrom", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "transferFromUniversal", data: BytesLike): Result;
}
export interface SafeERC20Wrapper extends BaseContract {
    connect(runner?: ContractRunner | null): SafeERC20Wrapper;
    waitForDeployment(): Promise<this>;
    interface: SafeERC20WrapperInterface;
    queryFilter<TCEvent extends TypedContractEvent>(event: TCEvent, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    queryFilter<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    on<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    on<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    listeners<TCEvent extends TypedContractEvent>(event: TCEvent): Promise<Array<TypedListener<TCEvent>>>;
    listeners(eventName?: string): Promise<Array<Listener>>;
    removeAllListeners<TCEvent extends TypedContractEvent>(event?: TCEvent): Promise<this>;
    allowance: TypedContractMethod<[], [bigint], "view">;
    approve: TypedContractMethod<[amount: BigNumberish], [void], "nonpayable">;
    balanceOf: TypedContractMethod<[], [bigint], "view">;
    decreaseAllowance: TypedContractMethod<[
        amount: BigNumberish
    ], [
        void
    ], "nonpayable">;
    increaseAllowance: TypedContractMethod<[
        amount: BigNumberish
    ], [
        void
    ], "nonpayable">;
    permit: TypedContractMethod<[
        arg0: AddressLike,
        arg1: AddressLike,
        arg2: BigNumberish,
        arg3: BigNumberish,
        arg4: BigNumberish,
        arg5: BytesLike,
        arg6: BytesLike
    ], [
        void
    ], "nonpayable">;
    setAllowance: TypedContractMethod<[
        allowance_: BigNumberish
    ], [
        void
    ], "nonpayable">;
    transfer: TypedContractMethod<[], [void], "nonpayable">;
    transferFrom: TypedContractMethod<[], [void], "nonpayable">;
    transferFromUniversal: TypedContractMethod<[
        permit2: boolean
    ], [
        void
    ], "nonpayable">;
    getFunction<T extends ContractMethod = ContractMethod>(key: string | FunctionFragment): T;
    getFunction(nameOrSignature: "allowance"): TypedContractMethod<[], [bigint], "view">;
    getFunction(nameOrSignature: "approve"): TypedContractMethod<[amount: BigNumberish], [void], "nonpayable">;
    getFunction(nameOrSignature: "balanceOf"): TypedContractMethod<[], [bigint], "view">;
    getFunction(nameOrSignature: "decreaseAllowance"): TypedContractMethod<[amount: BigNumberish], [void], "nonpayable">;
    getFunction(nameOrSignature: "increaseAllowance"): TypedContractMethod<[amount: BigNumberish], [void], "nonpayable">;
    getFunction(nameOrSignature: "permit"): TypedContractMethod<[
        arg0: AddressLike,
        arg1: AddressLike,
        arg2: BigNumberish,
        arg3: BigNumberish,
        arg4: BigNumberish,
        arg5: BytesLike,
        arg6: BytesLike
    ], [
        void
    ], "nonpayable">;
    getFunction(nameOrSignature: "setAllowance"): TypedContractMethod<[allowance_: BigNumberish], [void], "nonpayable">;
    getFunction(nameOrSignature: "transfer"): TypedContractMethod<[], [void], "nonpayable">;
    getFunction(nameOrSignature: "transferFrom"): TypedContractMethod<[], [void], "nonpayable">;
    getFunction(nameOrSignature: "transferFromUniversal"): TypedContractMethod<[permit2: boolean], [void], "nonpayable">;
    filters: {};
}
