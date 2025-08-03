import type { BaseContract, BytesLike, FunctionFragment, Result, Interface, AddressLike, ContractRunner, ContractMethod, Listener } from "ethers";
import type { TypedContractEvent, TypedDeferredTopicFilter, TypedEventLog, TypedListener, TypedContractMethod } from "../../../common";
export interface PermitableMockInterface extends Interface {
    getFunction(nameOrSignature: "mockPermit" | "mockPermitCompact"): FunctionFragment;
    encodeFunctionData(functionFragment: "mockPermit", values: [AddressLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "mockPermitCompact", values: [AddressLike, BytesLike]): string;
    decodeFunctionResult(functionFragment: "mockPermit", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "mockPermitCompact", data: BytesLike): Result;
}
export interface PermitableMock extends BaseContract {
    connect(runner?: ContractRunner | null): PermitableMock;
    waitForDeployment(): Promise<this>;
    interface: PermitableMockInterface;
    queryFilter<TCEvent extends TypedContractEvent>(event: TCEvent, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    queryFilter<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    on<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    on<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    listeners<TCEvent extends TypedContractEvent>(event: TCEvent): Promise<Array<TypedListener<TCEvent>>>;
    listeners(eventName?: string): Promise<Array<Listener>>;
    removeAllListeners<TCEvent extends TypedContractEvent>(event?: TCEvent): Promise<this>;
    mockPermit: TypedContractMethod<[
        token: AddressLike,
        permit: BytesLike
    ], [
        void
    ], "nonpayable">;
    mockPermitCompact: TypedContractMethod<[
        token: AddressLike,
        permit: BytesLike
    ], [
        void
    ], "nonpayable">;
    getFunction<T extends ContractMethod = ContractMethod>(key: string | FunctionFragment): T;
    getFunction(nameOrSignature: "mockPermit"): TypedContractMethod<[
        token: AddressLike,
        permit: BytesLike
    ], [
        void
    ], "nonpayable">;
    getFunction(nameOrSignature: "mockPermitCompact"): TypedContractMethod<[
        token: AddressLike,
        permit: BytesLike
    ], [
        void
    ], "nonpayable">;
    filters: {};
}
