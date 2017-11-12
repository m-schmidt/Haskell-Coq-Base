Require Import ExtrHaskellBasic.
Require Import ExtrHaskellString.
Require Import CoqMain.

Extraction Language Haskell.

(* Map custom Coq type 'IO' and the 'bind' function to Haskells IO monad and (>>=) from Prelude *)
Extract Inductive IO => "Prelude.IO" ["Prelude.IO"].
Extract Constant bind => "(Prelude.>>=)".

(* map Coq IO actions to Haskell Prelude functions, for getLine add an ignored argument *)
Extract Constant putStr  => "Prelude.putStrLn".
Extract Constant getLine => "(\_ -> Prelude.getLine)".

Cd "extraction".

Separate Extraction main.
