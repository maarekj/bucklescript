(* OCamlScript compiler
 * Copyright (C) 2015-2016 Bloomberg Finance L.P.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(* Author: Hongbo Zhang  *)




module E = Js_helper.Exp

module A = struct 

  let const_char (i : char) = 
    E.str (String.make 1 i)

  let caml_char_of_int ?comment (v : J.expression)  =  
    E.char_of_int ?comment v

  let caml_char_to_int ?comment v =  
    E.char_to_int ?comment v

  (* string [s[i]] expects to return a [ocaml_char] *)
  let ref_string e e1 = 
    E.string_access e e1

  (* [s[i]] excepts to return a [ocaml_char]
     We use normal array for [bytes]
     TODO: we can use [Buffer] in the future 
   *)
  let ref_byte e e0  =
    E.char_of_int (E.access  e  e0)

  (* {Bytes.set : bytes -> int -> char -> unit }*)
  let set_byte  e e0 e1 = 
    E.assign (E.access e e0)  (E.char_to_int e1)

(*
   Note that [String.fromCharCode] also works, but it only 
   work for small arrays, however, for {bytes_to_string} it is likely the bytes 
   will become big
   {[
   String.fromCharCode.apply(null,[87,97])
   "Wa"
   String.fromCharCode(87,97)
   "Wa" 
   ]}
   This does not work for large arrays
   {[
   String.fromCharCode.apply(null, prim = Array[1048576]) 
   Maxiume call stack size exceeded
   ]}
 *)

  let bytes_to_string e = 
    E.runtime_call Js_helper.string "bytes_to_string" [e]

  let bytes_of_string s =
    E.runtime_call Js_helper.string "bytes_of_string" [s]
end

(* We use module B for string compilation, once the upstream can make changes to the 
    patten match of range patterns, we can use module [A] which means [char] is [string] in js, 
    currently, it follows the same patten of ocaml, [char] is [int]
 *)

module B = struct 

  let const_char (i : char) = 
    E.int  ~comment:("\"" ^ Ext_string.escaped (String.make 1 i) ^ "\"") 
      ~c:i (Char.code i)

  let caml_char_of_int ?comment (v : J.expression)  =  v

  let caml_char_to_int ?comment v =  v

  (* string [s[i]] expects to return a [ocaml_char] *)
  let ref_string e e1 = 
    E.char_to_int (E.string_access e e1)

  (* [s[i]] excepts to return a [ocaml_char]
     We use normal array for [bytes]
     TODO: we can use [Buffer] in the future 
   *)
  let ref_byte e e0  = E.access  e  e0

  (* {Bytes.set : bytes -> int -> char -> unit }*)
  let set_byte  e e0 e1 = 
    E.assign (E.access e e0)  e1

(**
   Note that [String.fromCharCode] also works, but it only 
   work for small arrays, however, for {bytes_to_string} it is likely the bytes 
   will become big
   {[
   String.fromCharCode.apply(null,[87,97])
   "Wa"
   String.fromCharCode(87,97)
   "Wa" 
   ]}
   This does not work for large arrays
   {[
   String.fromCharCode.apply(null, prim = Array[1048576]) 
   Maxiume call stack size exceeded
   ]}
 *)

  let bytes_to_string e = 
    E.runtime_call Js_helper.string "bytes_to_string" [e]

  let bytes_of_string s =
    E.runtime_call Js_helper.string "bytes_of_string" [s]
end

(* include A *)
include B
