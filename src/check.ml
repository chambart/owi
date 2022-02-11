open Types

type env =
  { start : bool
  ; memory : bool
  ; funcs : bool
  ; tables : bool
  ; globals : bool
  }

let empty_env () =
  { start = false
  ; memory = false
  ; funcs = false
  ; tables = false
  ; globals = false
  }

let module_ m =
  let _env =
    List.fold_left
      (fun env -> function
        | MExport _e -> env
        | MFunc _f -> { env with funcs = true }
        | MStart _start ->
          if env.start then failwith "multiple start sections";
          { env with start = true }
        | MImport _i ->
          if env.funcs then failwith "import after function";
          if env.memory then failwith "import after memory";
          if env.tables then failwith "import after table";
          if env.globals then failwith "import after global";
          env
        | MData _d -> env
        | MElem _e -> env
        | MMem _m ->
          if env.memory then failwith "multiple memories are not allowed (yet)";
          { env with memory = true }
        | MType _t -> env
        | MGlobal _g -> { env with globals = true }
        | MTable _t -> { env with tables = true } )
      (empty_env ()) m.fields
  in
  ()

let script s = List.iter (function Module m -> module_ m | _ -> ()) s
