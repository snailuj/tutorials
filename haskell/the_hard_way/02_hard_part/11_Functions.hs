import Data.List (foldl')
-- Given a list of integers, return the sum of the even numbers in the list.
-- e.g. [1,2,3,4,5] => 2 + 4 => 6

-- Version 1
evenSum :: [Integer] -> Integer
evenSum ls = accumSum 0 ls

accumSum n ls = if ls == []
                    then n
                    else let x = head ls
                             xs = tail ls
                        in if even x
                            then accumSum (n + x) xs
                            else accumSum n xs

-- with pattern matching and eta-reduction
evenSumV2 :: Integral a => [a] -> a
evenSumV2 = accumSumV2 0
    where 
        accumSumV2 n [] = n
        accumSumV2 n (x:xs) = 
            if even x
                then accumSumV2 (n+x) xs
                else accumSumV2 n xs

-- with filter
evenSumV3 :: Integral a => [a] -> a
evenSumV3 l = accum 0 (filter even l)
    where
        accum n [] = n
        accum n (x:xs) = accum (n+x) xs

-- with foldl
evenSumV4 :: Integral a => [a] -> a
evenSumV4 l = foldl' (+) 0 (filter even l)

-- with eta reduction again (thanks, function composition operator!)
evenSumV5 :: Integral a => [a] -> a
evenSumV5 = (foldl' (+) 0) . (filter even)

sum' :: (Num a) => [a] -> a
sum' = foldl' (+) 0
evens :: Integral a => [a] -> [a]
evens = filter even
evenSumV6 = sum' . evens

squares :: Num a => [a] -> [a]
squares = map (^2)

squareEvenSum = sum' . evens . squares