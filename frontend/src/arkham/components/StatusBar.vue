<script lang="ts" setup>
import { computed, inject } from 'vue';
import type { Game } from '@/arkham/types/Game';
import * as ArkhamGame from '@/arkham/types/Game';
import type { Message } from '@/arkham/types/Message';
import { MessageType } from '@/arkham/types/Message';
import { QuestionType } from '@/arkham/types/Question';

export interface Props {
  game: Game
  investigatorId: string
}

const props = defineProps<Props>()
const emit = defineEmits(['choose'])
const choices = computed(() => ArkhamGame.choices(props.game, props.investigatorId))

const question = computed(() => props.game.question[props.investigatorId])

const choose = (idx: number) => emit('choose', idx)

const applyResultsAction = computed(() => {
  return choices.value.findIndex((c) => c.tag === "SkillTestApplyResultsButton");
})

const skillTestResults = computed(() => props.game.skillTestResults)

const baseUrl = inject('baseUrl')
const cardLabelImage = (cardCode: string) => {
  return `${baseUrl}/img/arkham/cards/${cardCode.replace('c', '')}.jpg`;
}

const portraitLabelImage = (investigatorId: string) => {
  return `${baseUrl}/img/arkham/portraits/${investigatorId.replace('c', '')}.jpg`;
}

const cardLabels = computed(() =>
  choices.value.
    flatMap<[Message, number][]>((choice, index) => {
      return choice.tag === "CardLabel" ? [[choice, index]] : []
    }))

const tokenOperator = computed(() => (skillTestResults.value?.skillTestResultsTokensValue || 0) < 0 ? '-' : '+')

const testResult = computed(() => {
  const result = skillTestResults.value
  if (result !== null) {
    const {skillTestResultsSkillValue, skillTestResultsIconValue, skillTestResultsTokensValue, skillTestResultsDifficulty} = result
    return skillTestResultsSkillValue + skillTestResultsIconValue + skillTestResultsTokensValue - skillTestResultsDifficulty
  } else {
    return null
  }
})
</script>

<template>
  <section class="status-bar">
    <div v-if="skillTestResults" class="skill-test-results">
      <dl>
        <dt>Modified Skill Value (skill value + icon value - tokens):</dt>
        <dd>
          {{skillTestResults.skillTestResultsSkillValue}}
          + {{skillTestResults.skillTestResultsIconValue}}
          {{tokenOperator}}
          {{Math.abs(skillTestResults.skillTestResultsTokensValue)}}
        </dd>
        <dt>Modified Difficulty:</dt>
        <dd>{{skillTestResults.skillTestResultsDifficulty}}</dd>
        <dt>Result:</dt>
        <dd v-if="testResult >= 0">
          Succeed by {{testResult}}
        </dd>
        <dd v-else>
          Fail by {{testResult - (skillTestResults.skillTestResultsResultModifiers || 0)}}
        </dd>
      </dl>
    </div>

    <div v-if="skillTestResults" class="skill-test-results-break"></div>

    <div v-if="cardLabels.length > 0">
      <template v-for="[choice, index] in cardLabels" :key="index">
        <a href='#' @click.prevent="choose(index)">
          <img class="card" :src="cardLabelImage(choice.cardCode)"/>
        </a>
      </template>
    </div>

    <div class="question-label" v-if="question && question.tag === 'QuestionLabel'">
      <p>{{question.label}}</p>
      <div class="label-choices">
        <template v-for="(choice, index) in question.question.choices" :key="index">
          <template v-if="choice.tag === MessageType.TOOLTIP_LABEL">
            <button @click="choose(index)" v-tooltip="choice.contents[1]">{{choice.contents[0]}}</button>
          </template>
          <template v-if="choice.tag === 'PortraitLabel'">
            <a href='#' @click.prevent="choose(index)">
              <img class="portrait card active" :src="portraitLabelImage(choice.investigatorId)"/>
            </a>
          </template>
        </template>
      </div>
    </div>

    <div class="intro-text" v-if="question && question.tag === QuestionType.READ">
      <h1 v-if="question.flavorText.title">{{question.flavorText.title}}</h1>
      <p
        v-for="(paragraph, index) in question.flavorText.body"
        :key="index"
      >{{paragraph}}</p>
    </div>


    <div class="choices">
      <template v-for="(choice, index) in choices" :key="index">
        <div v-if="choice.tag === MessageType.DONE">
          <button @click="choose(index)">{{choice.label}}</button>
        </div>
        <div v-if="choice.tag === MessageType.LABEL">
          <button v-if="choice.label == 'Choose {skull}'" @click="choose(index)">
            Choose <i class="iconSkull"></i>
          </button>
          <button v-else-if="choice.label == 'Choose {cultist}'" @click="choose(index)">
            Choose <i class="iconCultist"></i>
          </button>
          <button v-else-if="choice.label == 'Choose {tablet}'" @click="choose(index)">
            Choose <i class="iconTablet"></i>
          </button>
          <button v-else-if="choice.label == 'Choose {elderThing}'" @click="choose(index)">
            Choose <i class="iconElderThing"></i>
          </button>
          <button v-else @click="choose(index)">{{choice.label}}</button>
        </div>

        <a
          v-if="choice.tag === MessageType.SKILL_LABEL"
          class="button"
          @click="choose(index)"
        >
          Use <i :class="`icon${choice.skillType}`"></i>
        </a>

        <button
          v-if="applyResultsAction !== -1"
          @click="choose(applyResultsAction)"
        >Apply Results</button>
      </template>
    </div>
  </section>
</template>

<style scoped lang="scss">
i {
  font-family: 'Arkham';
  speak: none;
  font-style: normal;
  font-weight: normal;
  font-variant: normal;
  text-transform: none;
  line-height: 1;
  -webkit-font-smoothing: antialiased;
  position: relative;

}

i.iconSkull {
  &:before {
    font-family: "Arkham";
    content: "\004E";
  }
}

i.iconCultist {
  &:before {
    font-family: "Arkham";
    content: "\0042";
  }
}

i.iconTablet {
  &:before {
    font-family: "Arkham";
    content: "\0056";
  }
}

i.iconElderThing {
  &:before {
    font-family: "Arkham";
    content: "\0043";
  }
}

i.iconSkillWillpower {
  &:before {
    font-family: "Arkham";
    content: "\0041";
  }
}

i.iconSkillIntellect {
  &:before {
    font-family: "Arkham";
    content: "\0046";
  }
}

i.iconSkillCombat {
  &:before {
    font-family: "Arkham";
    content: "\0044";
  }
}

i.iconSkillAgility {
  &:before {
    font-family: "Arkham";
    content: "\0053";
  }
}

section {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  padding: 5px;
  background: #2D6153;
}

.button {
  display: inline-block;
  padding: 5px 10px;
  margin: 2px;
  background-color: #333;
  color: white;
  border: 1px solid #666;
  cursor: pointer;

  &:hover {
    background-color: #111;
  }

  &:active {
    background-color: #666;
    border-color: #111;
  }
}

.intro-text {
  background-color: #DFDAD8;
  padding: 10px;
  margin: 10px;
  border-radius: 2px;
  box-sizing: border-box;
  h1 {
    font-family: "Teutonic";
    font-weight: 500;
    color: #38615F;
    margin: 0;
    padding-bottom: 2px;
    margin-bottom: 10px;
    border-bottom: 1px solid #38615f;
    &::after {
      display: block;
      content: " ";
      margin-top: 2px;
      border-bottom: 1px solid #38615f;
    }
  }

  p {
    margin: 10px;
  }
}

.skill-test-results {
  background: rgba(255,255,255,0.6);
  border-radius: 5px;
  margin-bottom: 5px;
  padding: 10px;
  text-align: left;
  dl { padding: 0; margin: 0; display: flex; flex-wrap: wrap;}
  dt { flex: 0 0 50%; font-weight: bold;}
  &:after {
    display: block;
    content: "";
    flex-basis: 100%;
  }
}

.skill-test-results-break {
  flex-basis: 100%;
  height: 0;
}

.status-bar {
  text-align: center;
}

button {
  border: 0;
  padding: 10px;
  text-transform: uppercase;
  background-color: #532e61;
  font-weight: bold;
  border-radius: 0.6em;
  color: #EEE;
  font: Arial, sans-serif;
  &:hover {
    background-color: #311b3e;
  }
}

.card {
  width: $card-width;
  margin: 2px;
}

.question-label {
  display: flex;
  flex-direction: column;
  width: 75vw;

  p {
    font-size: 2em;
  }
}

.label-choices {
  display: flex;
  flex-direction: row;
  align-self: center;
  button {
    margin-left: 10px;
  }
}

.portrait {
  border-radius: 3px;
  width: $card-width;
  margin-right: 2px;

  &.active {
    border: 1px solid $select;
    cursor:pointer;
  }
}

</style>
