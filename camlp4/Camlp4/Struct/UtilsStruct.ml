(* Imported from typing/oprint.ml *)

value valid_float_lexeme s =
  let l = String.length s in
  let rec loop i =
    if i >= l then s ^ "." else
      match s.[i] with
        [ '0' .. '9' | '-' -> loop (i+1)
        | _ -> s ]
  in loop 0
;

value float_repres f =
  match classify_float f with
    [ FP_nan -> "nan"
    | FP_infinite ->
      if f < 0.0 then "neg_infinity" else "infinity"
    | _ ->
      let float_val =
        let s1 = Printf.sprintf "%.12g" f in
        if f = float_of_string s1 then s1 else
          let s2 = Printf.sprintf "%.15g" f in
          if f = float_of_string s2 then s2 else
            Printf.sprintf "%.18g" f
      in valid_float_lexeme float_val ]
;
