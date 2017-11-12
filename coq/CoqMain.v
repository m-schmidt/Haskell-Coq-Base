Require Import String.
Require Import List.

Set Implicit Arguments.


(* Some kind of IO monad *)
Inductive IO (A: Type) : Type :=
  | Pure: A -> IO A.

Definition bind (A B: Type) (f: IO A) (g: A -> IO B) : IO B :=
  match f with
  | Pure x => g x
  end.

Notation "'do' X <- A ; B" :=
  (bind A (fun X => B))
  (at level 200, X ident, A at level 100, B at level 200).


(* Example IO actions, implemented in Haskell *)
Parameter putStr: string -> IO unit.
Parameter getLine: unit -> IO string.


(* Entry point of Coq code *)
Definition main : IO unit :=
  do _ <- putStr "What is your name?";
  do n <- getLine tt;
  putStr ("Hello " ++ n ++ "!")
  .
