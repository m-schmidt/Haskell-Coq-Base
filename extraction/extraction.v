Require Import ExtrHaskellBasic.
Require Import ExtrHaskellString.
Require Import CoqMain.

Extraction Language Haskell.

(* map custom Coq type 'IO' and the 'bind' function to Haskell's IO monad and (>>=) from Prelude *)
Extract Inductive IO  => "Prelude.IO" ["Prelude.IO"].
Extract Constant bind => "(Prelude.>>=)".

(* map Coq IO actions to Haskell Prelude functions, for getLine add an ignored argument *)
Extract Constant putStrLn => "Prelude.putStrLn".
Extract Constant getLine  => "(\_ -> Prelude.getLine)".

Cd "extraction".

Separate Extraction main.
