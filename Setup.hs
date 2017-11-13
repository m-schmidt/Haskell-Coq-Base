import Control.Monad
import Data.Time.Clock
import Data.Maybe
import Distribution.PackageDescription
import Distribution.Simple
import Distribution.Simple.LocalBuildInfo
import Distribution.Simple.Setup
import System.Directory hiding (findFiles)
import System.Exit
import System.FilePath
import System.IO
import System.IO.Error
import System.Process hiding (env)


-- Simple build with custom hooks
main = defaultMainWithHooks simpleUserHooks { preBuild=preBuild', preClean=preClean' }

preBuild' :: Args -> BuildFlags -> IO HookedBuildInfo
preBuild' args flags = do
  needed <- extractionNeeded
  when needed makeExtraction
  (preBuild simpleUserHooks) args flags

preClean' :: Args -> CleanFlags -> IO HookedBuildInfo
preClean' args flags = do
    removeExtration
    (preClean simpleUserHooks) args flags


-- Source and extraction directory for Coq
coqDir = "coq"
extDir = "extraction"

-- Coq flags
coqIncludes = ["-R", coqDir, "main." ++ coqDir]
coqcFlags   = ["-noglob"]
coqtopFlags = ["-batch", "-load-vernac-source"]


-- Check whether a Coq extraction is needed
extractionNeeded :: IO Bool
extractionNeeded = do
  coqSources <- findFiles coqDir ".v"
  extSources <- findFiles extDir ".hs"
  case (coqSources, extSources) of
    ([], _) -> exitWithError "no Coq source files found."
    (_, []) -> return True
    _       -> do coqStamp <- youngest coqSources
                  extStamp <- oldest extSources
                  return $ coqStamp > extStamp


-- Search all files in directory 'dir' with extension 'ext'. Return list of full paths.
findFiles :: FilePath -> String -> IO [FilePath]
findFiles dir ext = map fullPath . filter hasExtension <$> listDirectory dir
  where
    fullPath     = (</>) dir
    hasExtension = (==) ext . takeExtension


-- Get the youngest modification time of a list of files
youngest :: [FilePath] -> IO UTCTime
youngest = fmap maximum . sequence . map getModificationTime


-- Get the oldest modification time of a list of files
oldest :: [FilePath] -> IO UTCTime
oldest = fmap minimum . sequence . map getModificationTime


-- Compile Coq files and make extraction to Haskell
makeExtraction :: IO ()
makeExtraction = do
  putStrLn "[Coq extraction]"
  coqSources <- findFiles coqDir ".v"
  mapM compile coqSources
  extract $ extDir </> "extraction.v"

  where
    compile f = execute "coqc" $ coqIncludes ++ coqcFlags ++ [f]
    extract f = execute "coqtop" $ coqIncludes ++ coqtopFlags ++ [f]


-- Remove extracted Haskell source files and Coq .vo files
removeExtration :: IO ()
removeExtration = do
  hs <- findFiles extDir ".hs"
  vo <- findFiles coqDir ".vo"
  mapM removeFile $ hs ++ vo
  return ()


-- Execute an external command and check its result status
execute :: FilePath -> [String] -> IO ()
execute cmd args = do
  putStrLn $ "- Running " ++ cmd ++ " " ++ last args
  (_,_,_,p) <- createProcess (proc cmd args) { std_in=Inherit, std_out=Inherit, std_err=Inherit }
  r         <- waitForProcess p
  when (r /= ExitSuccess) $ exitWithError $ "command '" ++ cmd ++ "' failed with exit code " ++ show (code r) ++ "."

  where
    code ExitSuccess     = 0
    code (ExitFailure n) = n


-- Abort with error message
exitWithError :: String -> IO a
exitWithError message = do
  hPutStrLn stderr ("Error: " ++ message)
  exitWith $ ExitFailure 1
