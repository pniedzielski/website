-------------------------------------------------------------------------------
--                      PNIEDZIELSKI.NET SITE GENERATOR                      --
--                      -------------------------------                      --
--                                                                           --
-- Copyright © 2018, Patrick M. Niedzielski <patrick@pniedzielski.net>.      --
-- See LICENSE file for copying information.                                 --
--                                                                           --
-- TABLE OF CONTENTS:                                                        --
--     1. Compile templates                                                  --
--     2. Home page                                                          --
--     3. Articles                                                           --
--     4. Static resources                                                   --
--                                                                           --
-- APPENDICES:                                                               --
--     A. Behaviors                                                          --
--     B. Compliers                                                          --
--     C. Contexts                                                           --
--                                                                           --
-------------------------------------------------------------------------------


{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UnicodeSyntax     #-}

import    Hakyll
import    Prelude.Unicode
import    Control.Monad.Unicode
import    Data.Monoid.Unicode
import    Data.List
import    Data.Maybe
import    System.FilePath

main ∷ IO ()
main = hakyll $ do


-------------------------------------------------------------------------------
--                                                      1. COMPILE TEMPLATES --
-------------------------------------------------------------------------------


  match "templates/*" $ compile templateBodyCompiler


-------------------------------------------------------------------------------
--                                                              2. HOME PAGE --
-------------------------------------------------------------------------------


  match "index.html" $ do
    route idRoute
    compile $ getResourceBody
      ≫= indentBodyBy 4
      ≫= loadAndApplyTemplate "templates/default.html"
           (constField "url" "/" ⊕ defaultContext)


-------------------------------------------------------------------------------
--                                                               3. ARTICLES --
-------------------------------------------------------------------------------


  match (    "2016/**/*.html"
        .||. "2017/**/*.html"
        .||. "2018/**/*.html") $ do
    postBehavior


-------------------------------------------------------------------------------
--                                                       4. STATIC RESOURCES --
-------------------------------------------------------------------------------


  match (fromList [ "css/styles.css"   , "images/favicon.ico"
                  , "me.jpg"           , "serviceworker.js"
                  , "pniedzielski.asc" , "feed.xml"           ])
    staticBehavior


-------------------------------------------------------------------------------
--                                                              A. BEHAVIORS --
-------------------------------------------------------------------------------


-- Copy a file without modifying it.
staticBehavior ∷ Rules ()
staticBehavior = do
  route   idRoute
  compile copyFileCompiler

-- Generate a post.
postBehavior ∷ Rules ()
postBehavior = do
  route idRoute
  compile $ getResourceBody
    ≫= indentBodyBy 4
    ≫= loadAndApplyTemplate "templates/default.html"
         ( titleWithSiteName
         ⊕ dropUrlExtension "url"
         ⊕ defaultContext)


-------------------------------------------------------------------------------
--                                                              B. COMPILERS --
-------------------------------------------------------------------------------


-- Indent the body of a resource by 𝑛 spaces.
indentBodyBy ∷ Int → Item String → Compiler (Item String)
indentBodyBy n = withItemBody $ return ∘ indent
  where indentLine "" = ""
        indentLine s  = (replicate n ' ') ⧺ s
        indent        = intercalate "\n" ∘ fmap indentLine ∘ lines


-------------------------------------------------------------------------------
--                                                               C. CONTEXTS --
-------------------------------------------------------------------------------


-- Drops the extension from a URI field.
dropUrlExtension ∷ String → Context a
dropUrlExtension key = mapContext dropExtension $ urlField key

-- Returns a context with the post URI lacking the final .html.
titleWithSiteName ∷ Context a
titleWithSiteName = field "title" $ \item → do
    metadata ← getMetadata (itemIdentifier item)
    return $ fromMaybe "pniedzielski" $
      do title ← lookupString "title" metadata
         return $ title ⧺ " • pniedzielski"
