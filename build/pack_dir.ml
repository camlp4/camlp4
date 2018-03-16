open StdLabels
open MoreLabels

module Sset = Set.Make(String)
module Smap = Map.Make(String)

let split_ext s =
  match String.index s '.' with
  | exception Not_found -> (s, "")
  | i ->
      (String.sub s ~pos:0 ~len:i,
       String.sub s ~pos:i ~len:(String.length s - i))

let split_words s =
  let rec skip_blanks i =
    if i = String.length s then
      []
    else
      match s.[i] with
      | ' ' | '\t' -> skip_blanks (i + 1)
      | _ -> parse_word i (i + 1)
  and parse_word i j =
    if j = String.length s then
      [String.sub s ~pos:i ~len:(j - i)]
    else
      match s.[j] with
      | ' ' | '\t' -> String.sub s ~pos:i ~len:(j - i) :: skip_blanks (j + 1)
      | _ -> parse_word i (j + 1)
  in
  skip_blanks 0

let () =
  let pp = Sys.argv.(1) in
  let odir = Sys.argv.(2) in
  let sub_dir = Sys.argv.(3) in
  let dir = Filename.concat odir sub_dir in
  let files =
    Sys.readdir dir
    |> Array.to_list
    |> List.filter ~f:(fun fn ->
        match snd (split_ext fn) with
        | ".ml" | ".mli" -> true
        | _ -> false)
    |> List.map ~f:(Filename.concat dir)
  in
  let modules =
    List.map files ~f:(fun s ->
        String.capitalize_ascii (Filename.basename (fst (split_ext s))))
    |> Sset.of_list
  in
  let rec read_deps ic acc =
    match input_line ic with
    | exception End_of_file -> begin
        match Unix.close_process_in ic with
        | WEXITED 0 -> acc
        | WEXITED n -> exit n
        | WSIGNALED n -> exit n
        | WSTOPPED _ -> assert false
      end
    | line ->
        let i = String.index line ':' in
        let unit =
          String.sub line ~pos:0 ~len:i
          |> Filename.basename
          |> split_ext
          |> fst
          |> String.capitalize_ascii
        in
        let deps =
          split_words (String.sub line ~pos:(i + 1)
                         ~len:(String.length line - (i + 1)))
          |> List.filter ~f:(fun m -> Sset.mem m modules)
        in
        read_deps ic ((unit, deps) :: acc)
  in
  let deps =
    let cmd =
      Printf.sprintf
        "ocamldep -modules -pp %s %s" pp (String.concat ~sep:" " files)
    in
    read_deps (Unix.open_process_in cmd) []
  in
  let prefix =
    String.split_on_char sub_dir ~sep:'/'
    |> List.map ~f:String.capitalize_ascii
    |> String.concat ~sep:"_"
  in
  let oc = open_out (Filename.concat odir (Printf.sprintf "jbuild.%s.gen" prefix)) in
  let pr fmt = Printf.fprintf oc (fmt ^^ "\n") in
  List.iter deps ~f:(fun (fn, deps) ->
      pr "";
      pr "(rule";
      let base = Filename.basename fn in
      pr " (with-stdout-to %s_%s" prefix base;
      pr "  (progn";
      List.iter deps ~f:(fun m ->
          pr {|   (echo "module %s = %s_%s\n")|} m prefix m);
      pr {|   (echo "# 1 \"%s\"\n")|} (Filename.concat dir base);
      pr  "   (cat %S))))" (Filename.concat sub_dir base))
