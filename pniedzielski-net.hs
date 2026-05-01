-------------------------------------------------------------------------------
--                      PNIEDZIELSKI.NET SITE GENERATOR                      --
--                      -------------------------------                      --
--                                                                           --
-- Copyright © 2018, 2020, Patrick M. Niedzielski                            --
--   <patrick@pniedzielski.net>.                                             --
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


import Hakyll
import Data.List (intercalate)
import Data.List.NonEmpty (nonEmpty)
import Data.List.NonEmpty qualified as NE
import Data.Maybe
import System.FilePath
import Data.ByteString.Lazy qualified as LBS
import Network.Wai.Application.Static qualified as W
import WaiAppStatic.Types (LookupResult(..), fromPiece, unsafeToPiece)

configuration :: Configuration
configuration = defaultConfiguration
  { previewSettings = \root ->
      let base    = W.defaultFileServerSettings root
          tryHtml = maybe (return LRNotFound) $ \pathPieces ->
            let prefix    = NE.init pathPieces
                lastPiece = NE.last pathPieces
                htmlPiece = unsafeToPiece (fromPiece lastPiece <> ".html")
            in W.ssLookupFile base (prefix ++ [htmlPiece])
      in base { W.ssLookupFile = \pieces ->
           W.ssLookupFile base pieces >>= \case
             LRNotFound -> tryHtml (nonEmpty pieces)
             other      -> return other
         }
  }

main :: IO ()
main = hakyllWith configuration $ do


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
      >>= indentBodyBy 4
      >>= loadAndApplyTemplate "templates/default.html"
           (constField "url" "/" <> defaultContext)
      >>= saveSnapshot "brotli"
    version "brotli" brotliBehavior


-------------------------------------------------------------------------------
--                                                               3. ARTICLES --
-------------------------------------------------------------------------------


  match (    "2016/**/*.html"
        .||. "2017/**/*.html"
        .||. "2018/**/*.html"
        .||. "2019/**/*.html")
    postBehavior


-------------------------------------------------------------------------------
--                                                       4. STATIC RESOURCES --
-------------------------------------------------------------------------------


  match (fromList [ "css/styles.css"   , "images/favicon.ico"
                  , "images/me.jpg"    , "serviceworker.js"
                  , "pniedzielski.asc" , "feed.xml"           ])
    staticBehavior


-------------------------------------------------------------------------------
--                                                              A. BEHAVIORS --
-------------------------------------------------------------------------------


-- Brotli compress a file
brotliBehavior :: Rules ()
brotliBehavior = do
  route   $ addExtension' ".br"
  compile $ getResourceLBS >>= brotli
  where
    addExtension' extension = customRoute $
      (`addExtension` extension) . toFilePath


-- Copy a file without modifying it.
staticBehavior :: Rules ()
staticBehavior = do
  route   $ idRoute
  compile $ copyFileCompiler >>= saveSnapshot "brotli"
  version "brotli" brotliBehavior


-- Generate a post.
postBehavior :: Rules ()
postBehavior = do
  route   $ idRoute
  compile $ getResourceBody
    >>= indentBodyBy 4
    >>= loadAndApplyTemplate "templates/default.html"
         ( titleWithSiteName
         <> dropUrlExtension "url"
         <> defaultContext)
    >>= saveSnapshot "brotli"
  version "brotli" brotliBehavior


-------------------------------------------------------------------------------
--                                                              B. COMPILERS --
-------------------------------------------------------------------------------


-- Indent the body of a resource by 𝑛 spaces.
indentBodyBy :: Int -> Item String -> Compiler (Item String)
indentBodyBy n = withItemBody $ return . indent
  where indentLine "" = ""
        indentLine s  = (replicate n ' ') ++ s
        indent        = intercalate "\n" . fmap indentLine . lines

-- Brotli compress a resource.
brotli :: Item LBS.ByteString -> Compiler (Item LBS.ByteString)
brotli = withItemBody $ unixFilterLBS "brotli" ["-9", "-c"]


-------------------------------------------------------------------------------
--                                                               C. CONTEXTS --
-------------------------------------------------------------------------------


-- Drops the extension from a URI field.
dropUrlExtension :: String -> Context a
dropUrlExtension key = mapContext dropExtension $ urlField key

-- Returns a context with the post URI lacking the final .html.
titleWithSiteName :: Context a
titleWithSiteName = field "title" $ \item -> do
    metadata <- getMetadata (itemIdentifier item)
    return $ fromMaybe "pniedzielski" $
      do title <- lookupString "title" metadata
         return $ title ++ " • pniedzielski"
