import type { BaseContract, BigNumberish, BytesLike, FunctionFragment, Result, Interface, AddressLike, ContractRunner, ContractMethod, Listener } from "ethers";
import type { TypedContractEvent, TypedDeferredTopicFilter, TypedEventLog, TypedListener, TypedContractMethod } from "../../common";
export interface ECDSATestInterface extends Interface {
    getFunction(nameOrSignature: "isValidSignature" | "isValidSignature65" | "isValidSignature_r_vs" | "isValidSignature_v_r_s" | "recover" | "recoverOrIsValidSignature" | "recoverOrIsValidSignature65" | "recoverOrIsValidSignature_r_vs" | "recoverOrIsValidSignature_v_r_s" | "recover_r_vs" | "recover_v_r_s" | "toEthSignedMessageHash" | "toTypedDataHash"): FunctionFragment;
    encodeFunctionData(functionFragment: "isValidSignature", values: [AddressLike, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "isValidSignature65", values: [AddressLike, BytesLike, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "isValidSignature_r_vs", values: [AddressLike, BytesLike, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "isValidSignature_v_r_s", values: [AddressLike, BytesLike, BigNumberish, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "recover", values: [BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "recoverOrIsValidSignature", values: [AddressLike, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "recoverOrIsValidSignature65", values: [AddressLike, BytesLike, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "recoverOrIsValidSignature_r_vs", values: [AddressLike, BytesLike, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "recoverOrIsValidSignature_v_r_s", values: [AddressLike, BytesLike, BigNumberish, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "recover_r_vs", values: [BytesLike, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "recover_v_r_s", values: [BytesLike, BigNumberish, BytesLike, BytesLike]): string;
    encodeFunctionData(functionFragment: "toEthSignedMessageHash", values: [BytesLike]): string;
    encodeFunctionData(functionFragment: "toTypedDataHash", values: [BytesLike, BytesLike]): string;
    decodeFunctionResult(functionFragment: "isValidSignature", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "isValidSignature65", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "isValidSignature_r_vs", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "isValidSignature_v_r_s", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "recover", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "recoverOrIsValidSignature", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "recoverOrIsValidSignature65", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "recoverOrIsValidSignature_r_vs", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "recoverOrIsValidSignature_v_r_s", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "recover_r_vs", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "recover_v_r_s", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "toEthSignedMessageHash", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "toTypedDataHash", data: BytesLike): Result;
}
export interface ECDSATest extends BaseContract {
    connect(runner?: ContractRunner | null): ECDSATest;
    waitForDeployment(): Promise<this>;
    interface: ECDSATestInterface;
    queryFilter<TCEvent extends TypedContractEvent>(event: TCEvent, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    queryFilter<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TypedEventLog<TCEvent>>>;
    on<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    on<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(event: TCEvent, listener: TypedListener<TCEvent>): Promise<this>;
    once<TCEvent extends TypedContractEvent>(filter: TypedDeferredTopicFilter<TCEvent>, listener: TypedListener<TCEvent>): Promise<this>;
    listeners<TCEvent extends TypedContractEvent>(event: TCEvent): Promise<Array<TypedListener<TCEvent>>>;
    listeners(eventName?: string): Promise<Array<Listener>>;
    removeAllListeners<TCEvent extends TypedContractEvent>(event?: TCEvent): Promise<this>;
    isValidSignature: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        signature: BytesLike
    ], [
        boolean
    ], "view">;
    isValidSignature65: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    isValidSignature_r_vs: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    isValidSignature_v_r_s: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        v: BigNumberish,
        r: BytesLike,
        s: BytesLike
    ], [
        boolean
    ], "view">;
    recover: TypedContractMethod<[
        hash: BytesLike,
        signature: BytesLike
    ], [
        string
    ], "view">;
    recoverOrIsValidSignature: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        signature: BytesLike
    ], [
        boolean
    ], "view">;
    recoverOrIsValidSignature65: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    recoverOrIsValidSignature_r_vs: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    recoverOrIsValidSignature_v_r_s: TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        v: BigNumberish,
        r: BytesLike,
        s: BytesLike
    ], [
        boolean
    ], "view">;
    recover_r_vs: TypedContractMethod<[
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        string
    ], "view">;
    recover_v_r_s: TypedContractMethod<[
        hash: BytesLike,
        v: BigNumberish,
        r: BytesLike,
        s: BytesLike
    ], [
        string
    ], "view">;
    toEthSignedMessageHash: TypedContractMethod<[
        hash: BytesLike
    ], [
        string
    ], "view">;
    toTypedDataHash: TypedContractMethod<[
        domainSeparator: BytesLike,
        structHash: BytesLike
    ], [
        string
    ], "view">;
    getFunction<T extends ContractMethod = ContractMethod>(key: string | FunctionFragment): T;
    getFunction(nameOrSignature: "isValidSignature"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        signature: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "isValidSignature65"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "isValidSignature_r_vs"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "isValidSignature_v_r_s"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        v: BigNumberish,
        r: BytesLike,
        s: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "recover"): TypedContractMethod<[
        hash: BytesLike,
        signature: BytesLike
    ], [
        string
    ], "view">;
    getFunction(nameOrSignature: "recoverOrIsValidSignature"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        signature: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "recoverOrIsValidSignature65"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "recoverOrIsValidSignature_r_vs"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "recoverOrIsValidSignature_v_r_s"): TypedContractMethod<[
        signer: AddressLike,
        hash: BytesLike,
        v: BigNumberish,
        r: BytesLike,
        s: BytesLike
    ], [
        boolean
    ], "view">;
    getFunction(nameOrSignature: "recover_r_vs"): TypedContractMethod<[
        hash: BytesLike,
        r: BytesLike,
        vs: BytesLike
    ], [
        string
    ], "view">;
    getFunction(nameOrSignature: "recover_v_r_s"): TypedContractMethod<[
        hash: BytesLike,
        v: BigNumberish,
        r: BytesLike,
        s: BytesLike
    ], [
        string
    ], "view">;
    getFunction(nameOrSignature: "toEthSignedMessageHash"): TypedContractMethod<[hash: BytesLike], [string], "view">;
    getFunction(nameOrSignature: "toTypedDataHash"): TypedContractMethod<[
        domainSeparator: BytesLike,
        structHash: BytesLike
    ], [
        string
    ], "view">;
    filters: {};
}
