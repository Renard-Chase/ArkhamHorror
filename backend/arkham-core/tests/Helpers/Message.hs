module Helpers.Message where

import ClassyPrelude

import Arkham.Types.Asset
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Enemy
import Arkham.Types.Event
import Arkham.Types.Investigator
import Arkham.Types.Location
import Arkham.Types.Message
import Arkham.Types.SkillType

playEvent :: Investigator -> Event -> Message
playEvent i e = InvestigatorPlayEvent (getId () i) (getId () e)

moveTo :: Investigator -> Location -> Message
moveTo i l = MoveTo (getId () i) (getId () l)

moveFrom :: Investigator -> Location -> Message
moveFrom i l = MoveFrom (getId () i) (getId () l)

moveAllTo :: Location -> Message
moveAllTo = MoveAllTo . getId ()

enemySpawn :: Location -> Enemy -> Message
enemySpawn l e = EnemySpawn (getId () l) (getId () e)

loadDeck :: Investigator -> [PlayerCard] -> Message
loadDeck i cs = LoadDeck (getId () i) cs

addToHand :: Investigator -> Card -> Message
addToHand i card = AddToHand (getId () i) card

chooseEndTurn :: Investigator -> Message
chooseEndTurn i = ChooseEndTurn (getId () i)

enemyAttack :: Investigator -> Enemy -> Message
enemyAttack i e = EnemyAttack (getId () i) (getId () e)

fightEnemy :: Investigator -> Enemy -> Message
fightEnemy i e = FightEnemy (getId () i) (getId () e) SkillCombat [] [] False

playAsset :: Investigator -> Asset -> Message
playAsset i a = InvestigatorPlayAsset
  (getId () i)
  (getId () a)
  (slotsOf a)
  (toList $ getTraits a)

drawCards :: Investigator -> Int -> Message
drawCards i n = DrawCards (getId () i) n False