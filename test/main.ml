type test_mode =
  | Normal
  | Fmt
  | Opt
[@@warning "-37"]
(* TODO test Fmt *)

let count_total = ref 0

let count_total_failed = ref 0

let fmt = Format.err_formatter

let pp_red fmt s = Format.fprintf fmt "\x1b[31m%s\x1b[0m" s

let pp_green fmt s = Format.fprintf fmt "\x1b[32m%s\x1b[0m" s

let pp_ok () = Format.fprintf fmt "%a !@." pp_green "OK"

let pp_error msg = Format.fprintf fmt "%a: %s !@." pp_red "FAILED" msg

let test_file mode filename =
  let open Owi.Syntax in
  Format.fprintf fmt "testing %s: `%a`... "
    ( match mode with
    | Normal -> "file          "
    | Fmt -> "formatted file"
    | Opt -> "optimized file" )
    Fpath.pp filename;
  try
    let res =
      match mode with
      | Normal | Opt ->
        Owi.Parse.Script.from_file ~filename:(Fpath.to_string filename)
      | Fmt ->
        let* s = Owi.Cmd_fmt.format_file_to_string (Fpath.to_string filename) in
        Owi.Parse.Script.from_string s
    in
    match res with
    | Ok script -> begin
      match
        Owi.Script.exec script
          ~optimize:(match mode with Opt -> true | _ -> false)
          ~no_exhaustion:true
      with
      | Ok () as ok ->
        pp_ok ();
        ok
      | Error msg as error ->
        pp_error msg;
        error
    end
    | Error msg as e ->
      let msg = String.concat " | " @@ String.split_on_char '\n' msg in
      pp_error msg;
      e
  with e ->
    Error (Format.sprintf "unhandled exceptiond: `%s`" (Printexc.to_string e))

let test_directory d =
  let count_error = ref 0 in
  Format.fprintf fmt "testing directory     : `%a`@." Fpath.pp d;
  match Bos.OS.Dir.contents ~rel:false d with
  | Ok l ->
    let run mode file =
      match test_file mode file with
      | Ok () -> ()
      | Error _e ->
        incr count_error;
        incr count_total_failed
    in
    List.iter
      (fun file ->
        run Normal file;
        incr count_total;
        run Opt file;
        incr count_total
        (* TODO
           run Fmt file;
           incr count_total
        *) )
      (List.sort compare l);
    if !count_error > 0 then
      Error (Format.sprintf "%d test failed" !count_error)
    else Ok ()
  | Error (`Msg e) ->
    pp_error e;
    Error e

let () =
  let has_error = ref false in
  begin
    match test_directory Fpath.(v "passing") with
    | Ok () -> ()
    | Error e ->
      pp_error e;
      has_error := true
  end;
  begin
    match test_directory Fpath.(v "reference") with
    | Ok () -> ()
    | Error e ->
      pp_error e;
      has_error := true
  end;
  if Option.is_some @@ Sys.getenv_opt "OWIGC" then begin
    match test_directory Fpath.(v "gc") with
    | Ok () -> ()
    | Error e ->
      pp_error e;
      has_error := true
  end;
  Format.fprintf fmt "results : %d / %d !@."
    (!count_total - !count_total_failed)
    !count_total;
  if !has_error then exit 1
