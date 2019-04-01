
module type PrintableType = {
    type t;
    let print: t => string;
};

/**
 * This interface is not tied to the functor, a good thing!
 * But means it can't refer directly to Fst.t and Snd.t.
 * Instead we will use trickery to modify the interface when we declare the functor.
 * See Make and Make2 below.
 */ 
module type S = {
    type fst;
    type snd;
    type t;
    let make: (fst, snd) => t;
    let print: (t) => string;
};

/**
 * This functor uses /sharing constraints/ to bring Fst and Snd module types into 
 * the type scope, but leaves S unmodified. We then have to rewrite the type definitions
 * inside S manually.
 *
 * Sharing constraints enable us to USE the interface S when declaring
 * the return type of Make. Make's return type is now:
 * {
 *     type fst = Fst.t;
 *     type snd = Snd.t;
 *     type t;
 *     let make: (fst, snd) => t;
 *     let print: (t) => string;
 * }
 *
 * Note that the compiler knows how to type-check parameters to `make` because
 * Fst.t and Snd.t are shared into this interface.
 */
module Make = (Fst: PrintableType, Snd: PrintableType)
: (S /* sharing constraints, bring Fst and Snd into scope --> */ with type fst = Fst.t and type snd = Snd.t) => {
    type fst = Fst.t; /* rewrite the type definition */
    type snd = Snd.t; /* rewrite the type definition */
    type t = (fst, snd);
    let make = (f: fst, s: snd) => (f, s);
    let print = ((f, s): t) =>
        "(" ++ Fst.print(f) ++ ", " ++ Snd.print(s) ++ ")";
};

/**
 * This functor uses /destructive substitutions/ to bring the module types
 * into scope, implicitly overwriting them in the derivation of S. They remove
 * `fst` and `snd` from S entirely. The rewritten interface as used by the
 * return type of Make now actually has the signature:
 * {
 *     type t;
 *     let make: (Fst.t, Snd.t) => t;
 *     let print: (t) => string;
 * }
 * Exactly the same as if we declared the interface for the whole functor:
 * module S
 * 
 */
module Make2 = (Fst: PrintableType, Snd: PrintableType)
: (S with type fst := Fst.t and type snd := Snd.t) => {
    type t = (Fst.t, Snd.t);
    let make = (f: Fst.t, s: Snd.t) => (f, s);
    let print = ((f, s): t) =>
        "(" ++ Fst.print(f) ++ ", " ++ Snd.print(s) ++ ")";
}