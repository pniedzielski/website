-------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UnicodeSyntax     #-}
import    Hakyll
-------------------------------------------------------------------------------

main ∷ IO ()
main = hakyll $ do
  match cachables $ do
    route idRoute
    compile copyFileCompiler

  match articles $ do
    route idRoute
    compile copyFileCompiler

  match res $ do
    route idRoute
    compile copyFileCompiler

      where cachables = fromList [ "index.html"
                                 , "serviceworker.js"
                                 , "pniedzielski.asc"
                                 , "feed.xml" ]
            articles  = "2016/**/*.html" .||.
                        "2017/**/*.html" .||.
                        "2018/**/*.html"
            res       = fromList [ "css/styles.css"
                                 , "images/favicon.ico"
                                 , "me.jpg" ]
