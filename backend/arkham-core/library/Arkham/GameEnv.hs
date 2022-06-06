module Arkham.GameEnv where

import Arkham.Prelude

import Arkham.Classes.Depth
import Arkham.Classes.GameLogger
import Arkham.Classes.HasQueue
import {-# SOURCE #-} Arkham.Game
import Arkham.Message
import Arkham.SkillTest.Base
import Control.Monad.Random.Lazy hiding ( filterM, foldM, fromList )

newtype GameT a = GameT {unGameT :: ReaderT GameEnv IO a}
  deriving newtype (MonadReader GameEnv, Functor, Applicative, Monad, MonadIO)

runGameEnvT :: MonadIO m => GameEnv -> GameT a -> m a
runGameEnvT gameEnv = liftIO . flip runReaderT gameEnv . unGameT

data GameEnv = GameEnv
  { gameEnvGame :: Game
  , gameEnvQueue :: IORef [Message]
  , gameRandomGen :: IORef StdGen
  , gameLogger :: Text -> IO ()
  , gameDepthLock :: IORef Int
  }

instance HasStdGen GameEnv where
  genL = lens gameRandomGen $ \m x -> m { gameRandomGen = x }

instance HasGame GameT where
  getGame = asks $ gameEnvGame

instance HasQueue GameEnv where
  messageQueue = lens gameEnvQueue $ \m x -> m { gameEnvQueue = x }

instance HasDepth GameEnv where
  depthL = lens gameDepthLock $ \m x -> m { gameDepthLock = x }

instance HasGameLogger GameEnv where
  gameLoggerL = lens gameLogger $ \m x -> m { gameLogger = x }

toGameEnv
  :: ( HasGameRef env
     , HasQueue env
     , HasStdGen env
     , HasGameLogger env
     , MonadReader env m
     , MonadIO m
     )
  => m GameEnv
toGameEnv = do
  game <- readIORef =<< view gameRefL
  gen <- view genL
  queueRef <- view messageQueue
  logger <- view gameLoggerL
  depthLock <- newIORef 0
  pure $ GameEnv game queueRef gen logger depthLock

instance MonadRandom GameT where
  getRandomR lohi = do
    ref <- view genL
    atomicModifyIORef' ref (swap . randomR lohi)
  getRandom = do
    ref <- view genL
    atomicModifyIORef' ref (swap . random)
  getRandomRs lohi = do
    ref <- view genL
    gen <- atomicModifyIORef' ref split
    pure $ randomRs lohi gen
  getRandoms = do
    ref <- view genL
    gen <- atomicModifyIORef' ref split
    pure $ randoms gen

getSkillTest :: GameT (Maybe SkillTest)
getSkillTest = asks $ gameSkillTest . gameEnvGame
