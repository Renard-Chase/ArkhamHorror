import api from '@/api';
import { gameDecoder } from '@/arkham/types/Game';
import { Difficulty } from '@/arkham/types/Difficulty';

export const fetchGame = (gameId: string) => api
  .get(`arkham/games/${gameId}`)
  .then((resp) => {
    const { investigatorId, game } = resp.data;
    return gameDecoder
      .decodePromise(game)
      .then((gameData) => Promise.resolve({ investigatorId, game: gameData }));
  });

export const updateGame = (gameId: string, choice: number) => api
  .put(`arkham/games/${gameId}`, { choice })
  .then((resp) => gameDecoder.decodePromise(resp.data));

export const fetchGameRaw = (gameId: string) => api
  .get(`arkham/games/${gameId}`)
  .then((resp) => resp.data);

export const updateGameRaw = (gameId: string, gameJson: string) => api
  .put(`arkham/games/${gameId}/raw`, { gameJson });

export const newGame = (deckIds: string[], scenarioId: string, difficulty: Difficulty) => api
  .post('arkham/games', { deckIds, scenarioId, difficulty })
  .then((resp) => gameDecoder.decodePromise(resp.data));
