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

let () = mark_tag_used "windows";;
let windows = Sys.os_type = "Win32";;
if windows then tag_any ["windows"];;
let ccomptype = C.ccomptype
(*let () = if ccomptype <> "cc" then eprintf "ccomptype: %s@." ccomptype;;*)

let fp_cat oc f = with_input_file ~bin:true f (fun ic -> copy_chan ic oc)

(* Improve using the command module in Myocamlbuild_config
   with the variant version (`S, `A...) *)
let mkdll out files opts =
  let s = Command.string_of_command_spec in
  Cmd(Sh(Printf.sprintf "%s -o %s %s %s" C.mkdll out (s files) (s opts)))

let mkexe out files opts =
  let s = Command.string_of_command_spec in
  Cmd(Sh(Printf.sprintf "%s -o %s %s %s" C.mkexe out (s files) (s opts)))

let mklib out files opts =
  let s = Command.string_of_command_spec in
  Cmd(Sh(C.mklib out (s files) (s opts)))

let syslib x = A(C.syslib x);;
let syscamllib x =
  if ccomptype = "msvc" then A(Printf.sprintf "lib%s.lib" x)
  else A("-l"^x)

let ccoutput cc obj file =
  if ccomptype = "msvc" then
    Seq[Cmd(S[cc; A"-c"; Px file]);
        mv (Pathname.basename (Pathname.update_extension C.o file)) obj]
  else
    Cmd(S[cc; A"-c"; P file; A"-o"; Px obj])

let mkobj obj file opts =
  let tags = tags_of_pathname file++"c"++"compile"++ccomptype in
  let bytecc_with_opts = S[Sh C.bytecc; Sh C.bytecccompopts; opts; T tags] in
  ccoutput bytecc_with_opts obj file

let mknatobj obj file opts =
  let nativecc_with_opts = S[Sh C.nativecc; opts; Sh C.nativecccompopts] in
  ccoutput nativecc_with_opts obj file

let add_exe a =
  if not windows || Pathname.check_extension a "exe" then a
  else a-.-"exe";;

let add_exe_if_exists a =
  if not windows || Pathname.check_extension a "exe" then a
  else
    let exe = a-.-"exe" in
    if Pathname.exists exe then exe else a;;

let convert_command_for_windows_shell spec =
  if not windows then spec else
  let rec self specs acc =
    match specs with
    | N :: specs -> self specs acc
    | S[] :: specs -> self specs acc
    | S[x] :: specs -> self (x :: specs) acc
    | S specs :: specs' -> self (specs @ specs') acc
    | (P(a) | A(a)) :: specs ->
        let dirname = Pathname.dirname a in
        let basename = Pathname.basename a in
        let p =
          if dirname = Pathname.current_dir_name then Sh(add_exe_if_exists basename)
          else Sh(add_exe_if_exists (dirname ^ "\\" ^ basename)) in
        if String.contains_string basename 0 "ocamlrun" = None then
          List.rev (p :: acc) @ specs
        else
          self specs (p :: acc)
    | [] | (Px _ | T _ | V _ | Sh _ | Quote _) :: _ ->
        invalid_arg "convert_command_for_windows_shell: invalid atom in head position"
  in S(self [spec] [])

let convert_for_windows_shell solver () =
  convert_command_for_windows_shell (solver ())

let test_nt native byte =
  (Ocamlbuild_pack.My_std.sys_command (sprintf "test '%s' -nt '%s'" native byte)) = 0

let ar = A"ar";;

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
    Options.make_links := false

  | After_rules ->
    let hot_camlp4boot = "camlp4"/"boot"/"camlp4boot.byte" in
    let cold_camlp4boot = "camlp4boot" (* The installed version *) in
    let cold_camlp4o = "camlp4o" (* The installed version *) in

    flag ["ocaml"; "ocamlyacc"] (A"-v");

    flag ["ocaml"; "compile"; "strict_sequence"] (A"-strict-sequence");

    let add_extensions extensions modules =
      List.fold_right begin fun x ->
        List.fold_right begin fun ext acc ->
          x-.-ext :: acc
        end extensions
      end modules []
    in

    flag ["ocaml"; "pp"; "camlp4boot"] (P hot_camlp4boot);
    flag ["ocaml"; "pp"; "camlp4boot"; "native"] (S[A"-D"; A"OPT"]);
    flag ["ocaml"; "pp"; "camlp4boot"; "pp:dep"] (S[A"-D"; A"OPT"]);
    flag ["ocaml"; "pp"; "camlp4boot"; "pp:doc"] (S[A"-printer"; A"o"]);
    let exn_tracer = Pathname.pwd/"camlp4"/"boot"/"Camlp4ExceptionTracer.cmo" in
    if Pathname.exists exn_tracer then
      flag ["ocaml"; "pp"; "camlp4boot"; "exntracer"] (P exn_tracer);

    use_lib "camlp4/mkcamlp4" "camlp4/camlp4lib";

    ocaml_lib ~extern:true "unix";
    ocaml_lib ~extern:true "dynlink";
    ocaml_lib ~extern:true "str";
    ocaml_lib ~extern:true "toplevel";

    let setup_arch arch =
      let annotated_arch = annotate arch in
      let (_include_dirs_table, _for_pack_table) = mk_tables annotated_arch in
      (* Format.eprintf "%a@." (Ocaml_arch.print_table (List.print pp_print_string)) include_dirs_table; *)
      iter_info begin fun i ->
        Pathname.define_context i.current_path i.include_dirs
      end annotated_arch;

      let camlp4_arch =
        dir "" [
          dir "camlp4" [
            dir "build" [];
            dir_pack "Camlp4" [
              dir_pack "Struct" [
                dir_pack "Grammar" [];
              ];
              dir_pack "Printers" [];
            ];
            dir_pack "Camlp4Top" [];
          ];
        ];

        setup_arch camlp4_arch;

        Pathname.define_context "camlp4/boot" ["camlp4"];
        Pathname.define_context "camlp4/Camlp4Parsers" ["camlp4"];
        Pathname.define_context "camlp4/Camlp4Printers" ["camlp4"];
        Pathname.define_context "camlp4/Camlp4Filters" ["camlp4"];
        Pathname.define_context "camlp4/Camlp4Top" ["camlp4"];

        (* Temporary rule, waiting for a full usage of ocamlbuild *)
        copy_rule "Temporary rule, waiting for a full usage of ocamlbuild" "%.mlbuild" "%.ml";

        copy_rule' ~insert:`bottom "%" "%.exe";

        if windows then flag ["ocamlmklib"] (A"-custom");

        let p4  = Pathname.concat "camlp4" in
        let pa  = Pathname.concat (p4 "Camlp4Parsers") in
        let pr  = Pathname.concat (p4 "Camlp4Printers") in
        let fi  = Pathname.concat (p4 "Camlp4Filters") in
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
        let pr_r = pr "Camlp4OCamlRevisedPrinter" in
        let pr_o = pr "Camlp4OCamlPrinter" in
        let pr_a = pr "Camlp4AutoPrinter" in
        let fi_exc = fi "Camlp4ExceptionTracer" in
        let fi_meta = fi "MetaGenerator" in
        let camlp4_bin = p4 "Camlp4Bin" in
        let top_rprint = top "Rprint" in
        let top_top = top "Top" in
        let camlp4Profiler = p4 "Camlp4Profiler" in

        let camlp4lib_cma = p4 "camlp4lib.cma" in
        let camlp4lib_cmxa = p4 "camlp4lib.cmxa" in
        let camlp4lib_lib = p4 ("camlp4lib"-.-C.a) in

        let special_modules =
          if Sys.file_exists "./boot/Profiler.cmo" then [camlp4Profiler] else []
        in

        let camlp4_import_list =
          ["utils/misc.ml";
           "utils/terminfo.ml";
           "utils/warnings.ml";
           "parsing/location.ml";
           "parsing/longident.ml";
           "parsing/asttypes.mli";
           "parsing/parsetree.mli";
           "parsing/ast_helper.ml";
           "typing/outcometree.mli";
           "typing/oprint.ml";
           "myocamlbuild_config.ml";
           "utils/config.mlbuild"]
        in

        rule "camlp4/Camlp4_import.ml"
          ~deps:camlp4_import_list
          ~prod:"camlp4/Camlp4_import.ml"
          begin fun _ _ ->
            Echo begin
              List.fold_right begin fun path acc ->
                let modname = module_name_of_pathname path in
                "module " :: modname :: " = struct\n" :: Pathname.read path :: "\nend;\n" :: acc
              end camlp4_import_list [],
              "camlp4/Camlp4_import.ml"
            end
          end;

        let mk_camlp4_top_lib name modules =
          let name = "camlp4"/name in
          let cma = name-.-"cma" in
          let deps = special_modules @ modules @ [top_top] in
          let cmos = add_extensions ["cmo"] deps in
          rule cma
            ~deps:(camlp4lib_cma::cmos)
            ~prods:[cma]
            ~insert:(`before "ocaml: mllib & cmo* -> cma")
            begin fun _ _ ->
              Cmd(S[ocamlc; A"-a"; T(tags_of_pathname cma++"ocaml"++"link"++"byte");
                    P camlp4lib_cma; A"-linkall"; atomize cmos; A"-o"; Px cma])
            end
        in

        let mk_camlp4_bin name ?unix:(link_unix=true) modules =
          let name = "camlp4"/name in
          let byte = name-.-"byte" in
          let native = name-.-"native" in
          let unix_cma, unix_cmxa, include_unix =
            if link_unix
            then A"unix.cma", A"unix.cmxa", S[A"-I"; P unix_dir]
            else N,N,N in
          let dep_unix_byte, dep_unix_native =
            if link_unix && not mixed
            then [unix_dir/"unix.cma"],
                 [unix_dir/"unix.cmxa"; unix_dir/"unix"-.-C.a]
            else [],[] in
          let deps = special_modules @ modules @ [camlp4_bin] in
          let cmos = add_extensions ["cmo"] deps in
          let cmxs = add_extensions ["cmx"] deps in
          let objs = add_extensions [C.o] deps in
          let dep_dynlink_byte, dep_dynlink_native =
            if mixed
            then [], []
            else [dynlink_dir/"dynlink.cma"],
                 [dynlink_dir/"dynlink.cmxa"; dynlink_dir/"dynlink"-.-C.a]
          in
          rule byte
            ~deps:(camlp4lib_cma::cmos @ dep_unix_byte @ dep_dynlink_byte)
            ~prod:(add_exe byte)
            ~insert:(`before "ocaml: cmo* -> byte")
            begin fun _ _ ->
              Cmd(S[ocamlc; A"-I"; P dynlink_dir; A "dynlink.cma"; include_unix; unix_cma;
                    T(tags_of_pathname byte++"ocaml"++"link"++"byte");
                    P camlp4lib_cma; A"-linkall"; atomize cmos; A"-o"; Px (add_exe byte)])
            end;
          rule native
            ~deps:(camlp4lib_cmxa :: camlp4lib_lib :: (cmxs @ objs @ dep_unix_native @ dep_dynlink_native))
            ~prod:(add_exe native)
            ~insert:(`before "ocaml: cmx* & o* -> native")
            begin fun _ _ ->
              Cmd(S[ocamlopt; A"-I"; P dynlink_dir; A "dynlink.cmxa"; include_unix; unix_cmxa;
                    T(tags_of_pathname native++"ocaml"++"link"++"native");
                    P camlp4lib_cmxa; A"-linkall"; atomize cmxs; A"-o"; Px (add_exe native)])
            end
        in

        let mk_camlp4 name ?unix modules bin_mods top_mods =
          mk_camlp4_bin name ?unix (modules @ bin_mods);
          mk_camlp4_top_lib name (modules @ top_mods);
        in

        copy_rule "camlp4: boot/Camlp4Ast.ml -> Camlp4/Struct/Camlp4Ast.ml"
          ~insert:`top "camlp4/boot/Camlp4Ast.ml" "camlp4/Camlp4/Struct/Camlp4Ast.ml";

        rule "camlp4: Camlp4/Struct/Lexer.ml -> boot/Lexer.ml"
          ~prod:"camlp4/boot/Lexer.ml"
          ~dep:"camlp4/Camlp4/Struct/Lexer.ml"
          begin fun _ _ ->
            Cmd(S[P cold_camlp4o; P"camlp4/Camlp4/Struct/Lexer.ml";
                  A"-printer"; A"r"; A"-o"; Px"camlp4/boot/Lexer.ml"])
          end;

        dep ["ocaml"; "file:camlp4/Camlp4/Sig.ml"]
          ["camlp4/Camlp4/Camlp4Ast.partial.ml"];

        rule "camlp4: ml4 -> ml"
          ~prod:"%.ml"
          ~dep:"%.ml4"
          begin fun env build ->
            let ml4 = env "%.ml4" and ml = env "%.ml" in
            Camlp4deps.build_deps build ml4;
            Cmd(S[P cold_camlp4boot; A"-impl"; P ml4; A"-printer"; A"o";
                  A"-D"; A"OPT"; A"-o"; Px ml])
          end;

        rule "camlp4: mlast -> ml"
          ~prod:"%.ml"
          ~deps:["%.mlast"; "camlp4/Camlp4/Camlp4Ast.partial.ml"]
          begin fun env _ ->
            let mlast = env "%.mlast" and ml = env "%.ml" in
            (* Camlp4deps.build_deps build mlast; too hard to lex *)
            Cmd(S[P cold_camlp4boot;
                  A"-printer"; A"r";
                  A"-filter"; A"map";
                  A"-filter"; A"fold";
                  A"-filter"; A"meta";
                  A"-filter"; A"trash";
                  A"-impl"; P mlast;
                  A"-o"; Px ml])
          end;

        dep ["ocaml"; "compile"; "file:camlp4/Camlp4/Sig.ml"]
          ["camlp4/Camlp4/Camlp4Ast.partial.ml"];

        mk_camlp4_bin "camlp4" [];
        mk_camlp4 "camlp4boot" ~unix:false
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
          [pa_r; pa_o; pa_rp; pa_op; pa_qc; pa_rq; pa_g; pa_macro; pa_l] [pr_a] [];
  | _ ->
    ()
  end
