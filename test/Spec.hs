import           Control.Concurrent    (forkIO, killThread, threadDelay)
import           Control.DeadmanSwitch (deadmanSwitch)
import           Control.Exception     (handle)
import           Control.Monad         (forever)
import           Data.IORef            (atomicModifyIORef', newIORef, readIORef,
                                        writeIORef)
import           Data.Semigroup        ((<>))
import           System.Directory      (removeFile)
import           System.IO.Temp        (emptySystemTempFile)
import           System.Posix.Process  (forkProcess)
import           System.Posix.Signals  (sigTERM, signalProcess)
import           Test.Hspec

main = hspec spec

graffiti = "kilroy wuz here"

tally ref = atomicModifyIORef' ref (\x -> (x <> "1", ()))

spec :: Spec
spec = do
  describe "normal exceptions" $ do
    it "async kill" $ do
      x <- newIORef ""
      threadId <- forkIO $ deadmanSwitch (tally x)
                    $ forever $ threadDelay 1000000
      killThread threadId

      readIORef x `shouldReturn` "1"

    it "internal exception" $ do
      x <- newIORef ""
      readIORef x `shouldReturn` ""
      threadId <- forkIO $ deadmanSwitch (tally x)
                    $ error "oops"
      killThread threadId

      readIORef x `shouldReturn` "1"
  describe "external" $ do
    it "unix signal" $ do
      fp <- emptySystemTempFile "deadDrop"

      pid <- forkProcess $ deadmanSwitch (appendFile fp graffiti) $ forever $ threadDelay 1000000
      -- haaaaack
      threadDelay 10000
      signalProcess sigTERM pid
      threadDelay 10000
      readFile fp `shouldReturn` graffiti
      removeFile fp
