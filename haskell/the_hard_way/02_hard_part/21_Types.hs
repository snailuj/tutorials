{-# LANGUAGE GADTs #-}

type Name   = String
type Colour = String

showInfos :: Name -> Colour -> String
showInfos name colour = "Name: " ++ name
    ++ ", Colour: " ++ colour

name :: Name
name = "Robin"
colour :: Colour
colour = "Blue"

data ImprovedName = NameMake String
data ImprovedColour = ColourMake String

showInfosV2 :: ImprovedName -> ImprovedColour -> String
showInfosV2 (NameMake name) (ColourMake colour) = 
    "Name: " ++ name ++ ", Colour: " ++ colour

nameV2 = NameMake "Robin"
colourV2 = ColourMake "Blue"

-- More serious example:
data Complex a = Num a => Complex a a
--    ^^^         ^^^        ^^^
--     |- name     |          |
--                 |- class   |
--                            |- constructor
--
-- Type "Complex a" has a constructor that accepts two
-- parameters, both of type `a` and deriving Num

-- Records:
-- data DataTypeName a = Num a => DataConstructor {
--     field1 :: a,
--     field2 :: a,
--     field3 :: Integer
-- }

data Complex2 a = Num a => Complex2 { real :: a, img :: a}

-- Make your own List, verbose version:
-- data List a =
--     Empty 
--     | Cons a (List a)
-- example: let lit = Cons 0 (Cons 1 Empty)

-- New syntactic construct: fixity declarations. When we define functions as
-- operators, we can use that to give them a fixity (but we don't have to). A
-- fixity states how tightly the operator binds and whether it's left-associative
-- or right-associative. For instance, *'s fixity is infixl 7 * and +'s fixity is
-- infixl 6. That means that they're both left-associative (4 * 3 * 2 is (4 * 3) * 2)
-- but * binds tighter than +, because it has a greater fixity, so 5 * 4 + 3 is (5 * 4) + 3.
infixr 5 :-:
data List a = 
    Nil 
    | a :-: (List a) deriving (Show, Read, Eq, Ord)

-- concatenation with `+++`
infixr 5 +++
(+++) :: List a -> List a -> List a
Nil +++ ys = ys
(x :-: xs) +++ ys = x :-: (xs +++ ys) --pattern match on prev defined operator

toList [] = Nil
toList (x:xs) = x :-: toList xs

data BinTree a =
    Empty
    | Node a (BinTree a) (BinTree a)
    deriving (Eq,Ord,Show)

treeFromList :: (Ord a) => [a] -> BinTree a
treeFromList [] = Empty
treeFromList (x:xs) = Node x (treeFromList (filter (<x) xs))
                             (treeFromList (filter (>x) xs))

nullTree = Node 0 nullTree nullTree
treeTakeDepth _ Empty = Empty
treeTakeDepth 0 _     = Empty
treeTakeDepth n (Node x left right) = let
    nl = treeTakeDepth (n-1) left
    nr = treeTakeDepth (n-1) right
    in
        Node x nl nr

iTree = Node 0 (dec iTree) (inc iTree)
        where
            dec (Node x l r) = Node (x-1) (dec l) (dec r)
            inc (Node x l r) = Node (x+1) (inc l) (inc r)

treeMap :: (a -> b) -> BinTree a -> BinTree b
treeMap f Empty = Empty
treeMap f (Node x l r) = Node (f x) (treeMap f l) (treeMap f r)
--          ^^^
--           |-------- destructuring the current Node

iTree2 :: BinTree Int
iTree2 = Node 0 (treeMap (\x -> x - 1) iTree2)
                (treeMap (\x -> x + 1) iTree2)

main = do
    let c = Complex2 1.0 2.0
    let z = Complex2 { real = 3, img = 4 }
    putStrLn $ "z::img = " ++ (show . img) z ++ ", c::real = " ++ (show . real) c

    let l = 1 :-: 2 :-: 3 :-: Nil
    putStrLn $ show l

    let m = 4 :-: 5 :-: 6 :-: 7 :-: Nil
    (putStrLn . show) $ l +++ m

    let n = toList [10, 20, 30]
    putStrLn $ show n

    print $ treeTakeDepth 4 nullTree
    print $ treeTakeDepth 4 iTree2