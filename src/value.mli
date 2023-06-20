(** Module to define externref values in OCaml. You should look in the `example`
    directory to understand how to use this before reading the code... *)

type ('a, 'b) eq = ('a, 'b) Type_id.eq

type externref = E : 'a Type_id.ty * 'a -> externref

module Func : sig
  type _ telt =
    | I32 : Int32.t telt
    | I64 : Int64.t telt
    | F32 : Float32.t telt
    | F64 : Float64.t telt
    | Externref : 'a Type_id.ty -> 'a telt

  type _ rtype =
    | R0 : unit rtype
    | R1 : 'a telt -> 'a rtype
    | R2 : 'a telt * 'b telt -> ('a * 'b) rtype
    | R3 : 'a telt * 'b telt * 'c telt -> ('a * 'b * 'c) rtype
    | R4 : 'a telt * 'b telt * 'c telt * 'd telt -> ('a * 'b * 'c * 'd) rtype

  type (_, _) atype =
    | Arg : 'a telt * ('b, 'r) atype -> ('a -> 'b, 'r) atype
    | NArg : string * 'a telt * ('b, 'r) atype -> ('a -> 'b, 'r) atype
    | Res : ('r, 'r) atype

  type _ func_type = Func : ('f, 'r) atype * 'r rtype -> 'f func_type

  type extern_func = Extern_func : 'a func_type * 'a -> extern_func

  type 'a t =
    | WASM of int * Simplified.func * 'a
    | Extern of extern_func

  val typ : 'a t -> Simplified.func_type

  val wasm : Simplified.func -> 'a -> 'a t
end

type 'env ref_value =
  | Externref of externref option
  | Funcref of 'env Func.t option
  | Arrayref of unit array option

type 'a t =
  | I32 of Int32.t
  | I64 of Int64.t
  | F32 of Float32.t
  | F64 of Float64.t
  | Ref of 'a ref_value

val cast_ref : externref -> 'a Type_id.ty -> 'a option

val of_instr : Simplified.instr -> _ t

val to_instr : _ t -> Simplified.instr

val ref_null' : Simplified.heap_type -> 'a ref_value

val ref_null : Simplified.heap_type -> 'a t

val ref_func : 'a Func.t -> 'a t

val is_ref_null : 'a ref_value -> bool

val pp : Format.formatter -> 'a t -> unit
