/*
  Remember that functions can call functions?
  They can call themselves too. But only with a special keyword.

  Try changing "let rec" to "let" and you'll see the following compiler error:
  "The value addEveryNumberUpTo can't be found"
 */
let rec addEveryNumberUpTo = x => {
  /* make sure we don't call this on negative numbers! */
  assert (x >= 0);
  switch (x) {
  | 0 => 0
  | _ => x + addEveryNumberUpTo(x - 1)
  };
};

/*
  Let's write a function to multiply every number up to x.
  Remember: [factorial 0] is 1
 */
let rec factorial = x => {
  assert (x >= 0);
  switch (x) {
  | 0 => 1
  | _ => x * factorial(x - 1)
  }
};

let rec tailFactorialRec: (int64, int64) => int64 = (x, accum) => {
  switch (x) {
  | 1L => accum
  | _ => tailFactorialRec(Int64.sub(x, 1L), Int64.mul(accum, x));
  }
};

let tailFactorial: int64 => int64 = x => {
  assert(x >= 0L);
  tailFactorialRec(x, 1L);
};

Test.runAll([
  (factorial(0) == 1, "factorial"),
  (factorial(5) == 120, "factorial"),
  (tailFactorial(5L) == 120L, "tailFactorial"),
  (tailFactorial(20L) == tailFactorial(20L), "tailFactorial"),
]);