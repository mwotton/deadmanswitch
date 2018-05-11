{-# LANGUAGE LambdaCase      #-}
{-# LANGUAGE RecordWildCards #-}
module Control.DeadmanSwitch where
import           Control.Concurrent       (forkIO, isEmptyMVar, killThread,
                                           newEmptyMVar, putMVar, readMVar)
import           Control.Concurrent.Async (async, cancel)
import           Control.Exception        (finally)
import           Control.Monad            (forM_, void)
import           System.IO                (hPrint, hPutStrLn, stderr)
import           System.Posix.Signals     (Handler (CatchOnce), SignalInfo (..),
                                           installHandler, raiseSignal, sigINT,
                                           sigTERM, signalProcess)

deadmanSwitch :: IO () -> IO () -> IO ()
deadmanSwitch switch action = do
  done <- newEmptyMVar
  let finalise = isEmptyMVar done >>= \case
        True -> putMVar done () >> switch
        False -> return ()

  (do m <- newEmptyMVar
      forM_ [sigINT, sigTERM] $ \sig ->
        installHandler sig (CatchOnce $ putMVar m ()) Nothing

      -- do we need to fork the action to a full process, or just another thread?
      pid <- async $ action  `finally` finalise
      readMVar m
      finalise
      cancel pid)  `finally` finalise
