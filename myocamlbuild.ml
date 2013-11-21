(***********************************************************************)
(*                                                                     *)
(*                                OCaml                                *)
(*                                                                     *)
(*       Nicolas Pouillard, projet Gallium, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 2007 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

open Ocamlbuild_plugin
open Command
open Arch
open Format

module C = Myocamlbuild_config

let () = mark_tag_used "windows"
let windows = C.os_type = "Win32"
let () = if windows then tag_any ["windows"]

let add_exe a =
  if not windows || Pathname.check_extension a "exe" then a
  else a-.-"exe"

module Camlp4deps = struct
  let lexer = Genlex.make_lexer ["INCLUDE"; ";"; "="; ":"]

  let rec parse strm =
    match Stream.peek strm with
    | None -> []
    | Some(Genlex.Kwd "INCLUDE") ->
      Stream.junk strm;
      begin match Stream.peek strm with
      | Some(Genlex.String s) ->
        Stream.junk strm;
        s :: parse strm
      | _ -> invalid_arg "Camlp4deps parse failure"
      end
    | Some _ ->
      Stream.junk strm;
      parse strm

  let parse_file file =
    with_input_file file begin fun ic ->
      let strm = Stream.of_channel ic in
      parse (lexer strm)
    end

  let build_deps build file =
    let includes = parse_file file in
    List.iter Outcome.ignore_good (build (List.map (fun i -> [i]) includes));
end

let () =
  dispatch begin function
  | After_options ->
    Options.make_links := false;
    Options.use_ocamlfind := false

  | After_rules ->
    let hot_camlp4boot =
      "camlp4"/"boot"/"camlp4boot" ^
      if !Options.native_plugin then
        (* If we are using a native plugin, we might as well use a native preprocessor. *)
        ".native"
      else
        ".byte"
    in
    let cold_camlp4boot = "camlp4boot" (* The installed version *) in
    let cold_camlp4o = "camlp4o" (* The installed version *) in

    flag ["ocaml"; "ocamlyacc"] (A"-v");

    flag ["ocaml"; "compile"; "strict_sequence"] (A"-strict-sequence");

    let add_extensions extensions modules =
      List.fold_right begin fun x ->
        List.fold_right begin fun ext acc ->
          (x^ext) :: acc
        end extensions
      end modules []
    in

    dep ["camlp4boot"] [hot_camlp4boot];
    flag ["ocaml"; "pp"; "camlp4boot"] (P hot_camlp4boot);
    flag ["ocaml"; "pp"; "camlp4boot"; "native"] (S[A"-D"; A"OPT"]);
    flag ["ocaml"; "pp"; "camlp4boot"; "pp:dep"] (S[A"-D"; A"OPT"]);
    flag ["ocaml"; "pp"; "camlp4boot"; "pp:doc"] (S[A"-printer"; A"o"]);
    let exn_tracer = Pathname.pwd/"camlp4"/"boot"/"Camlp4ExceptionTracer.cmo" in
    if Pathname.exists exn_tracer then
      flag ["ocaml"; "pp"; "camlp4boot"; "exntracer"] (P exn_tracer);

    use_lib "camlp4/mkcamlp4" "camlp4/camlp4lib";

    ocaml_lib ~extern:true ~dir:"+compiler-libs" "ocamlcommon";
    ocaml_lib ~extern:true "ocamlbytecomp";

    let setup_arch arch =
      let annotated_arch = annotate arch in
      let (_include_dirs_table, _for_pack_table) = mk_tables annotated_arch in
      (* Format.eprintf "%a@." (Ocaml_arch.print_table (List.print pp_print_string)) include_dirs_table; *)
      iter_info begin fun i ->
        Pathname.define_context i.current_path i.include_dirs
      end annotated_arch
    in

    let camlp4_arch =
      dir "" [
        dir "camlp4" [
          dir "config" [];
          dir_pack "Camlp4" [
            dir_pack "Struct" [
              dir_pack "Grammar" [];
            ];
            dir_pack "Printers" [];
          ];
          dir_pack "Camlp4Top" [];
        ];
      ]
    in

    setup_arch camlp4_arch;

    Pathname.define_context "camlp4" ["camlp4/config"];
    Pathname.define_context "camlp4/boot" ["camlp4/config"];
    Pathname.define_context "camlp4/Camlp4Parsers" ["camlp4"; "camlp4/config"];
    Pathname.define_context "camlp4/Camlp4Printers" ["camlp4"; "camlp4/config"];
    Pathname.define_context "camlp4/Camlp4Filters" ["camlp4"; "camlp4/config"];
    Pathname.define_context "camlp4/Camlp4Top" ["camlp4"; "camlp4/config"];

    (* Some modules of camlp4 have the same names as ones from compiler-libs. For this
       reason we can't just -I +compiler-libs. Instead we copy the .cmi of the few modules
       of compiler-libs we are using to a local directory. *)

    let import = [
      "misc.cmi";
      "terminfo.cmi";
      "warnings.cmi";
      "location.cmi";
      "longident.cmi";
      "asttypes.cmi";
      "parsetree.cmi";
      "outcometree.cmi";
      "oprint.cmi";
      "config.cmi";
      "toploop.cmi";
    ] in

    List.iter
      (fun fn ->
         let prod = "camlp4" / "import" / fn in
         rule (Printf.sprintf "copy %s" fn)
           ~dep:"camlp4/import/.keepme"
           ~prod
           (fun _ _ -> cp (C.standard_library / "compiler-libs" / fn) prod))
      import;

    flag ["ocaml"; "compile"; "use_import"] & S[A "-I"; A "camlp4/import"];
    dep ["ocaml"; "compile"; "use_import"]
      (List.map (fun fn -> "camlp4" / "import" / fn) import);

    copy_rule "% -> %.exe" ~insert:`bottom "%" "%.exe";

    if windows then flag ["ocamlmklib"] (A"-custom");

    let p4  = Pathname.concat "camlp4" in
    let pa  = Pathname.concat (p4 "Camlp4Parsers") in
    let pr  = Pathname.concat (p4 "Camlp4Printers") in
    (*    let fi  = Pathname.concat (p4 "Camlp4Filters") in*)
    let top = Pathname.concat (p4 "Camlp4Top") in

    let pa_r  = pa "Camlp4OCamlRevisedParser" in
    let pa_o  = pa "Camlp4OCamlParser" in
    let pa_q  = pa "Camlp4QuotationExpander" in
    let pa_qc = pa "Camlp4QuotationCommon" in
    let pa_rq = pa "Camlp4OCamlRevisedQuotationExpander" in
    let pa_oq = pa "Camlp4OCamlOriginalQuotationExpander" in
    let pa_rp = pa "Camlp4OCamlRevisedParserParser" in
    let pa_op = pa "Camlp4OCamlParserParser" in
    let pa_g  = pa "Camlp4GrammarParser" in
    let pa_l  = pa "Camlp4ListComprehension" in
    let pa_macro = pa "Camlp4MacroParser" in
    let pa_debug = pa "Camlp4DebugParser" in

    let pr_dump  = pr "Camlp4OCamlAstDumper" in
    (*    let pr_r = pr "Camlp4OCamlRevisedPrinter" in
          let pr_o = pr "Camlp4OCamlPrinter" in*)
    let pr_a = pr "Camlp4AutoPrinter" in
    (*    let fi_exc = fi "Camlp4ExceptionTracer" in*)
    (*    let fi_meta = fi "MetaGenerator" in*)
    let camlp4_bin = p4 "Camlp4Bin" in
    let top_rprint = top "Rprint" in
    let top_top = top "Top" in
    let camlp4Profiler = p4 "Camlp4Profiler" in

    let camlp4lib_cma = p4 "camlp4lib.cma" in
    let camlp4lib_cmxa = p4 "camlp4lib.cmxa" in
    let camlp4lib_lib = p4 ("camlp4lib"^C.ext_lib) in

    let special_modules =
      if Sys.file_exists "./boot/Profiler.cmo" then [camlp4Profiler] else []
    in

    let mk_camlp4_top_lib name modules =
      let name = "camlp4"/name in
      let cma = name-.-"cma" in
      let deps = special_modules @ modules @ [top_top] in
      let cmos = add_extensions [".cmo"] deps in
      rule cma
        ~deps:(camlp4lib_cma::cmos)
        ~prods:[cma]
        ~insert:(`before "ocaml: mllib & cmo* -> cma")
        begin fun _ _ ->
          Cmd(S[!Options.ocamlc; A"-a"; T(tags_of_pathname cma++"ocaml"++"link"++"byte");
                P camlp4lib_cma; A"-linkall"; atomize cmos; A"-o"; Px cma])
        end
    in

    let mk_camlp4_bin name modules =
      let name = "camlp4"/name in
      let byte = name-.-"byte" in
      let native = name-.-"native" in
      let deps = special_modules @ modules @ [camlp4_bin] in
      let cmos = add_extensions [".cmo"] deps in
      let cmxs = add_extensions [".cmx"] deps in
      let objs = add_extensions [C.ext_obj] deps in
      rule byte
        ~deps:(camlp4lib_cma::cmos)
        ~prod:(add_exe byte)
        ~insert:(`before "ocaml: cmo* -> byte")
        begin fun _ _ ->
          Cmd(S[!Options.ocamlc; T(tags_of_pathname byte++"ocaml"++"link"++"byte");
                P camlp4lib_cma; A"-linkall"; atomize cmos; A"-o"; Px (add_exe byte)])
        end;
      rule native
        ~deps:(camlp4lib_cmxa :: camlp4lib_lib :: (cmxs @ objs))
        ~prod:(add_exe native)
        ~insert:(`before "ocaml: cmx* & o* -> native")
        begin fun _ _ ->
          Cmd(S[!Options.ocamlopt; T(tags_of_pathname native++"ocaml"++"link"++"native");
                P camlp4lib_cmxa; A"-linkall"; atomize cmxs; A"-o"; Px (add_exe native)])
        end
    in

    let mk_camlp4 name modules bin_mods top_mods =
      mk_camlp4_bin name (modules @ bin_mods);
      mk_camlp4_top_lib name (modules @ top_mods);
    in

    copy_rule "camlp4: boot/Camlp4Ast.ml -> Camlp4/Struct/Camlp4Ast.ml"
      ~insert:`top "camlp4/boot/Camlp4Ast.ml" "camlp4/Camlp4/Struct/Camlp4Ast.ml";

    dep ["ocaml"; "file:camlp4/Camlp4/Sig.ml"]
      ["camlp4/Camlp4/Camlp4Ast.partial.ml"];

    dep ["ocaml"; "compile"; "file:camlp4/Camlp4/Sig.ml"]
      ["camlp4/Camlp4/Camlp4Ast.partial.ml"];

    mk_camlp4_bin "camlp4" [];
    mk_camlp4 "camlp4boot"
      [pa_r; pa_qc; pa_q; pa_rp; pa_g; pa_macro; pa_debug; pa_l] [pr_dump] [top_rprint];
    mk_camlp4 "camlp4r"
      [pa_r; pa_rp] [pr_a] [top_rprint];
    mk_camlp4 "camlp4rf"
      [pa_r; pa_qc; pa_q; pa_rp; pa_g; pa_macro; pa_l] [pr_a] [top_rprint];
    mk_camlp4 "camlp4o"
      [pa_r; pa_o; pa_rp; pa_op] [pr_a] [];
    mk_camlp4 "camlp4of"
      [pa_r; pa_qc; pa_q; pa_o; pa_rp; pa_op; pa_g; pa_macro; pa_l] [pr_a] [];
    mk_camlp4 "camlp4oof"
      [pa_r; pa_o; pa_rp; pa_op; pa_qc; pa_oq; pa_g; pa_macro; pa_l] [pr_a] [];
    mk_camlp4 "camlp4orf"
      [pa_r; pa_o; pa_rp; pa_op; pa_qc; pa_rq; pa_g; pa_macro; pa_l] [pr_a] []
  | _ ->
    ()
  end
