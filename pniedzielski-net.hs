-------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UnicodeSyntax     #-}
import    Hakyll
import    Prelude.Unicode
import    Control.Monad.Unicode
import    Data.Monoid.Unicode
import    Data.List
-------------------------------------------------------------------------------

main ∷ IO ()
main = hakyll $ do
  match "templates/*" $ compile templateBodyCompiler

  match "index.html" $ do
    route idRoute
    compile $ getResourceBody
      ≫= indentBodyBy 4
      ≫= loadAndApplyTemplate "templates/default.html"
           (constField "url" "/" ⊕ defaultContext)

  match cachables $ do
    route idRoute
    compile copyFileCompiler

  match articles $ do
    route idRoute
    compile copyFileCompiler

  match res $ do
    route idRoute
    compile copyFileCompiler

      where cachables = fromList [ "serviceworker.js"
                                 , "pniedzielski.asc"
                                 , "feed.xml" ]
            articles  = "2016/**/*.html" .||.
                        "2017/**/*.html" .||.
                        "2018/**/*.html"
            res       = fromList [ "css/styles.css"
                                 , "images/favicon.ico"
                                 , "me.jpg" ]

-------------------------------------------------------------------------------

-- Indent the body of a resource by 𝑛 spaces.
indentBodyBy ∷ Int → Item String → Compiler (Item String)
indentBodyBy n = withItemBody $ return ∘ indent
  where indentLine "" = ""
        indentLine s  = (replicate n ' ') ⧺ s
        indent        = intercalate "\n" ∘ fmap indentLine ∘ lines
