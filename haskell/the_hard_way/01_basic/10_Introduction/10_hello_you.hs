main = do
    print "What is your name?"
    name <- getline
    print ("Hello " ++ name ++ "!")