(* Generate Camlp4_import with values taken from compiler-libs. We don't want
   implementation dependencies on compiler-libs to avoid problems in the toplevel. *)

let () =
  let oc = open_out "camlp4/config/Camlp4_import.ml" in
  Printf.fprintf oc "\
let standard_library = %S
let ast_intf_magic_number = %S
let ast_impl_magic_number = %S
"
    Config.standard_library
    Config.ast_intf_magic_number
    Config.ast_impl_magic_number;
  close_out oc
