import type { BaseContract, BigNumberish, BytesLike, FunctionFragment, Result, Interface, ContractRunner, ContractMethod, Listener } from "ethers";
import type { TypedContractEvent, TypedDeferredTopicFilter, TypedEventLog, TypedListener, TypedContractMethod } from "../../../common";
export interface AddressLibMockInterface extends Interface {
    getFunction(nameOrSignature: "get" | "getFlag" | "getUint32" | "getUint64"): FunctionFragment;
    encodeFunctionData(functionFragment: "get", values: [BigNumberish]): string;
    encodeFunctionData(functionFragment: "getFlag", values: [BigNumberish, BigNumberish]): string;
    encodeFunctionData(functionFragment: "getUint32", values: [BigNumberish, BigNumberish]): string;
    encodeFunctionData(functionFragment: "getUint64", values: [BigNumberish, BigNumberish]): string;
    decodeFunctionResult(functionFragment: "get", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getFlag", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUint32", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUint64", data: BytesLike): Result;
}
export interface AddressLibMock extends BaseContract {
    connect(runner?: ContractRunner | null): AddressLibMock;
    waitForDeployment(): Promise<this>;
    interface: AddressLibMockInterface;
    queryFilter<TCEvent extends TypedContractEvent>(event: TCEvent, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    queryFilter<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    on<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    on<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    listeners<TCEvent extends TypedContractEvent>(event: TCEvent): Promise<Array<TypedListener<TCEvent>>>;
    listeners(eventName?: string): Promise<Array<Listener>>;
    removeAllListeners<TCEvent extends TypedContractEvent>(event?: TCEvent): Promise<this>;
    get: TypedContractMethod<[a: BigNumberish], [string], "view">;
    getFlag: TypedContractMethod<[
        a: BigNumberish,
        flag: BigNumberish
    ], [
        boolean
    ], "view">;
    getUint32: TypedContractMethod<[
        a: BigNumberish,
        offset: BigNumberish
    ], [
        bigint
    ], "view">;
    getUint64: TypedContractMethod<[
        a: BigNumberish,
        offset: BigNumberish
    ], [
        bigint
    ], "view">;
    getFunction<T extends ContractMethod = ContractMethod>(key: string | FunctionFragment): T;
    getFunction(nameOrSignature: "get"): TypedContractMethod<[a: BigNumberish], [string], "view">;
    getFunction(nameOrSignature: "getFlag"): TypedContractMethod<[
        a: BigNumberish,
        flag: BigNumberish
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "getUint32"): TypedContractMethod<[
        a: BigNumberish,
        offset: BigNumberish
    ], [
        bigint
    ], "view">;
    getFunction(nameOrSignature: "getUint64"): TypedContractMethod<[
        a: BigNumberish,
        offset: BigNumberish
    ], [
        bigint
    ], "view">;
    filters: {};
}
