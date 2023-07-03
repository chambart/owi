open Types

let page_size = 65_536

type t =
  { id : int
  ; label : string option
  ; mutable limits : limits
  ; mutable data : bytes
  }

let fresh =
  let r = ref (-1) in
  fun () ->
    incr r;
    !r

let init ?label (typ : limits) : t =
  let data = Bytes.make (page_size * typ.min) '\x00' in
  { id = fresh (); label; limits = typ; data }

let update_memory mem data =
  let limits =
    { mem.limits with min = max mem.limits.min (Bytes.length data / page_size) }
  in
  mem.limits <- limits;
  mem.data <- data

let grow mem delta =
  let delta = Int32.to_int delta in
  let old_size = Bytes.length mem.data in
  let new_mem = Bytes.extend mem.data 0 delta in
  Bytes.fill new_mem old_size delta (Char.chr 0);
  update_memory mem new_mem

let fill mem pos len c =
  let pos = Int32.to_int pos in
  let len = Int32.to_int len in
  let c = Int32.to_int c |> Char.chr in
  if pos < 0 || pos + len >= Bytes.length mem.data then true
  else begin
    Bytes.fill mem.data pos len c;
    false
  end

let blit mem src_pos dst_pos len =
  let src_pos = Int32.to_int src_pos in
  let dst_pos = Int32.to_int dst_pos in
  let len = Int32.to_int len in
  if
    src_pos < 0 || dst_pos < 0
    || src_pos + len <= Bytes.length mem.data
    || dst_pos + len <= Bytes.length mem.data
  then true
  else begin
    Bytes.blit mem.data src_pos mem.data dst_pos len;
    false
  end

let get_data { data; _ } = data

let get_limit_max { limits; _ } = Option.map Int64.of_int limits.max

let get_limits { limits; _ } = limits

let store_8 mem ~addr n =
  let addr = Int32.to_int addr in
  let n = Int32.to_int n in
  Bytes.set_int8 mem.data addr n

let store_16 mem ~addr n =
  let addr = Int32.to_int addr in
  let n = Int32.to_int n in
  Bytes.set_int16_le mem.data addr n

let store_32 mem ~addr n =
  let addr = Int32.to_int addr in
  Bytes.set_int32_le mem.data addr n

let store_64 mem ~addr n =
  let addr = Int32.to_int addr in
  Bytes.set_int64_le mem.data addr n

let load_8_s mem addr =
  let addr = Int32.to_int addr in
  Int32.of_int @@ Bytes.get_int8 mem.data addr

let load_8_u mem addr =
  let addr = Int32.to_int addr in
  Int32.of_int @@ Bytes.get_uint8 mem.data addr

let load_16_s mem addr =
  let addr = Int32.to_int addr in
  Int32.of_int @@ Bytes.get_int16_le mem.data addr

let load_16_u mem addr =
  let addr = Int32.to_int addr in
  Int32.of_int @@ Bytes.get_uint16_le mem.data addr

let load_32 mem addr =
  let addr = Int32.to_int addr in
  Bytes.get_int32_le mem.data addr

let load_64 mem addr =
  let addr = Int32.to_int addr in
  Bytes.get_int64_le mem.data addr

let size_in_pages mem = Int32.of_int @@ (Bytes.length mem.data / page_size)

let size mem = Int32.of_int @@ Bytes.length mem.data
