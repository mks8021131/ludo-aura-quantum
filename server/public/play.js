const revealItems = document.querySelectorAll(".reveal");
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.18 }
);
revealItems.forEach((item) => observer.observe(item));

document.querySelectorAll('a[href^="#"]').forEach((link) => {
  link.addEventListener("click", (event) => {
    const target = document.querySelector(link.getAttribute("href"));
    if (!target) return;
    event.preventDefault();
    target.scrollIntoView({ behavior: "smooth", block: "start" });
  });
});

const board = document.getElementById("board");
const diceButton = document.getElementById("diceButton");
const diceValue = document.getElementById("diceValue");
const helperText = document.getElementById("helperText");
const turnName = document.getElementById("turnName");
const turnDot = document.getElementById("turnDot");
const turnState = document.getElementById("turnState");
const scoreGrid = document.getElementById("scoreGrid");
const eventLog = document.getElementById("eventLog");
const newGameButton = document.getElementById("newGameButton");
const undoButton = document.getElementById("undoButton");
const fullscreenButton = document.getElementById("fullscreenButton");
const bestMoveButton = document.getElementById("bestMoveButton");
const winnerNewGame = document.getElementById("winnerNewGame");
const playerCountSelect = document.getElementById("playerCount");
const themeSelect = document.getElementById("themeSelect");
const assistToggle = document.getElementById("assistToggle");
const soundToggle = document.getElementById("soundToggle");
const hapticToggle = document.getElementById("hapticToggle");
const rollCount = document.getElementById("rollCount");
const captureCount = document.getElementById("captureCount");
const matchTime = document.getElementById("matchTime");
const winnerOverlay = document.getElementById("winnerOverlay");
const winnerTitle = document.getElementById("winnerTitle");
const winnerSummary = document.getElementById("winnerSummary");

const colors = [
  { id: "red", label: "Red", css: "var(--red)", start: 0, base: [[2, 2], [2, 3], [3, 2], [3, 3]], home: [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5]] },
  { id: "green", label: "Green", css: "var(--green)", start: 13, base: [[2, 11], [2, 12], [3, 11], [3, 12]], home: [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7]] },
  { id: "yellow", label: "Yellow", css: "var(--yellow)", start: 26, base: [[11, 11], [11, 12], [12, 11], [12, 12]], home: [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9]] },
  { id: "blue", label: "Blue", css: "var(--blue)", start: 39, base: [[11, 2], [11, 3], [12, 2], [12, 3]], home: [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7]] },
];

const track = [
  [6, 1], [6, 2], [6, 3], [6, 4], [6, 5],
  [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6],
  [0, 7], [0, 8],
  [1, 8], [2, 8], [3, 8], [4, 8], [5, 8],
  [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14],
  [7, 14], [8, 14],
  [8, 13], [8, 12], [8, 11], [8, 10], [8, 9],
  [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8],
  [14, 7], [14, 6],
  [13, 6], [12, 6], [11, 6], [10, 6], [9, 6],
  [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0],
  [7, 0], [6, 0],
];

const safeCells = new Set([0, 8, 13, 21, 26, 34, 39, 47]);
const GAME_STATES = Object.freeze({
  IDLE: "idle",
  PLAYING: "playing",
  FINISHED: "finished",
});
let state;
let audioContext;
let timerId;

function createState() {
  const playerCount = Number(playerCountSelect.value);
  return {
    players: colors.slice(0, playerCount).map((color) => ({
      ...color,
      finishedTokens: 0,
      tokens: Array.from({ length: 4 }, (_, id) => ({ id, pos: -1, finished: false })),
    })),
    gameState: GAME_STATES.IDLE,
    current: 0,
    dice: null,
    rolled: false,
    rolling: false,
    moving: false,
    winner: null,
    rolls: 0,
    captures: 0,
    history: [],
    startedAt: Date.now(),
    log: [],
  };
}

function cellToStyle(row, col, inset = 0) {
  const cell = 100 / 15;
  return {
    left: `${col * cell + inset}%`,
    top: `${row * cell + inset}%`,
  };
}

function absolutePosition(player, relative) {
  return (relative + player.start) % 52;
}

function boardPosition(player, token) {
  if (token.pos === -1) return player.base[token.id];
  if (token.pos < 52) return track[absolutePosition(player, token.pos)];
  if (token.pos < 57) return player.home[token.pos - 52];
  return [7, 7];
}

function canMove(player, token) {
  if (state.gameState === GAME_STATES.FINISHED) return false;
  if (!state.rolled || state.rolling || state.moving || state.winner || token.finished) return false;
  if (token.pos === -1) return state.dice === 6;
  return token.pos + state.dice <= 57;
}

function checkWinner(player) {
  console.log("[Ludo] Winner check", {
    player: player.label,
    gameState: state.gameState,
    finishedTokens: player.finishedTokens,
  });

  if (state.gameState !== GAME_STATES.PLAYING) return false;
  if (player.finishedTokens !== 4) return false;

  state.gameState = GAME_STATES.FINISHED;
  state.winner = player;
  addLog(`${player.label} wins the match.`);
  return true;
}

function normalizeGameState(value, winner) {
  if (Object.values(GAME_STATES).includes(value)) return value;
  return winner ? GAME_STATES.FINISHED : GAME_STATES.IDLE;
}

function movableTokens() {
  const player = state.players[state.current];
  return player.tokens.filter((token) => canMove(player, token));
}

function targetPosition(player, token) {
  const target = token.pos === -1 ? 0 : token.pos + state.dice;
  return target < 52 ? track[absolutePosition(player, target)] : target < 57 ? player.home[target - 52] : [7, 7];
}

function renderBoardBase() {
  board.innerHTML = "";

  for (let row = 0; row < 15; row += 1) {
    for (let col = 0; col < 15; col += 1) {
      const cell = document.createElement("span");
      cell.className = "cell";
      const onTrack = track.some(([r, c]) => r === row && c === col);
      if (onTrack) cell.classList.add("track");
      const trackIndex = track.findIndex(([r, c]) => r === row && c === col);
      if (safeCells.has(trackIndex)) cell.classList.add("safe");
      colors.forEach((player) => {
        if (player.home.some(([r, c]) => r === row && c === col)) {
          cell.classList.add(`home-${player.id}`);
        }
      });
      Object.assign(cell.style, cellToStyle(row, col));
      board.appendChild(cell);
    }
  }

  colors.forEach((player) => {
    const base = document.createElement("div");
    base.className = `base base-${player.id}`;
    base.dataset.player = player.id;
    board.appendChild(base);
  });

  const center = document.createElement("div");
  center.className = "center-home";
  board.appendChild(center);
}

function render() {
  const player = state.players[state.current];
  turnName.textContent = state.winner ? `${state.winner.label} Wins` : player.label;
  turnDot.style.background = player.css;
  turnDot.style.boxShadow = `0 0 18px ${player.css}`;
  turnState.textContent = state.winner ? "Game over" : state.rolling ? "Rolling" : state.moving ? "Moving" : state.rolled ? "Choose token" : "Roll dice";
  diceButton.disabled = state.rolling || state.moving || state.rolled || Boolean(state.winner);
  bestMoveButton.disabled = state.rolling || state.moving || !state.rolled || Boolean(state.winner) || !movableTokens().length;
  undoButton.disabled = state.rolling || state.moving || !state.history.length;
  renderDice();
  helperText.textContent = helperMessage();
  rollCount.textContent = state.rolls;
  captureCount.textContent = state.captures;
  updateWinnerOverlay();

  document.querySelectorAll(".base").forEach((base) => {
    base.classList.toggle("active", base.dataset.player === player.id && !state.winner);
  });

  document.querySelectorAll(".token, .move-hint").forEach((node) => node.remove());
  renderHints();
  renderTokens();
  renderScores();
  renderLog();
}

function renderDice() {
  if (!state.rolling && !state.rolled) {
    diceValue.textContent = "ROLL";
    return;
  }
  const value = state.dice || 1;
  const activePips = {
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  }[value];
  diceValue.innerHTML = `<span class="dice-face">${Array.from({ length: 9 }, (_, index) => `<span class="pip ${activePips.includes(index) ? "on" : ""}"></span>`).join("")}</span>`;
}

function helperMessage() {
  if (state.winner) return "Start a new game to play again.";
  if (state.rolling) return "Dice is rolling...";
  if (state.moving) return "Token is moving step by step.";
  if (!state.rolled) return "Roll to begin. A 6 opens a token from base.";
  const moves = movableTokens().length;
  if (moves === 0) return "No legal moves. Passing turn.";
  return `${moves} legal move${moves === 1 ? "" : "s"} highlighted. Tap a glowing token.`;
}

function renderHints() {
  if (!assistToggle.checked || !state.rolled || state.moving || state.rolling || state.winner) return;
  const player = state.players[state.current];
  player.tokens.forEach((token) => {
    if (!canMove(player, token)) return;
    const [row, col] = targetPosition(player, token);
    const hint = document.createElement("span");
    hint.className = "move-hint";
    hint.style.color = player.css;
    Object.assign(hint.style, cellToStyle(row, col, 0.86));
    board.appendChild(hint);
  });
}

function renderTokens() {
  const occupancy = new Map();
  state.players.forEach((player) => {
    player.tokens.forEach((token) => {
      const [row, col] = boardPosition(player, token);
      const key = `${row}-${col}`;
      const stack = occupancy.get(key) || 0;
      occupancy.set(key, stack + 1);

      const tokenEl = document.createElement("button");
      tokenEl.className = "token";
      tokenEl.type = "button";
      tokenEl.style.color = player.css;
      tokenEl.title = `${player.label} token ${token.id + 1}`;
      tokenEl.dataset.player = player.id;
      tokenEl.dataset.token = token.id;
      const offset = stack * 0.82;
      Object.assign(tokenEl.style, cellToStyle(row, col, 0.78 + offset));

      if (player === state.players[state.current] && canMove(player, token)) {
        tokenEl.classList.add("movable");
        tokenEl.addEventListener("click", () => moveToken(player, token));
      }

      board.appendChild(tokenEl);
    });
  });
}

function renderScores() {
  scoreGrid.innerHTML = "";
  state.players.forEach((player, index) => {
    const finished = player.finishedTokens;
    const progress = player.tokens.reduce((sum, token) => sum + Math.max(0, token.finished ? 57 : token.pos), 0);
    const active = index === state.current && !state.winner;
    const card = document.createElement("article");
    card.className = `score-card ${active ? "active" : ""}`;
    card.style.color = player.css;
    card.innerHTML = `
      <span class="score-dot"></span>
      <span>
        <span class="score-name">${player.label}</span>
        <span class="score-meta">${player.tokens.filter((t) => t.pos >= 0 && !t.finished).length} active, ${player.tokens.filter((t) => t.pos === -1).length} in base</span>
      </span>
      <span class="score-finished">${finished}/4</span>
      <span class="progress-track"><span class="progress-fill" style="width: ${Math.min(100, (progress / 228) * 100)}%"></span></span>
    `;
    scoreGrid.appendChild(card);
  });
}

function renderLog() {
  eventLog.innerHTML = "";
  state.log.slice(0, 7).forEach((item) => {
    const li = document.createElement("li");
    li.textContent = item;
    eventLog.appendChild(li);
  });
}

async function rollDice() {
  if (state.gameState === GAME_STATES.FINISHED || state.rolling || state.moving || state.rolled || state.winner) return;
  pushHistory();
  state.rolling = true;
  diceButton.classList.add("rolling");
  pulse("dice");
  playTone(180, 0.06, "triangle");

  const result = Math.floor(Math.random() * 6) + 1;
  const started = performance.now();
  while (performance.now() - started < 500) {
    state.dice = Math.floor(Math.random() * 6) + 1;
    render();
    await wait(65);
  }

  state.dice = result;
  state.rolls += 1;
  state.rolling = false;
  state.rolled = true;
  diceButton.classList.remove("rolling");
  console.log("[Ludo] Dice roll", {
    player: state.players[state.current].label,
    result,
    gameState: state.gameState,
  });
  addLog(`${state.players[state.current].label} rolled ${result}.`);
  render();
  await wait(120);

  if (!movableTokens().length) {
    await wait(650);
    nextTurn();
  }
}

async function moveToken(player, token) {
  if (state.gameState === GAME_STATES.FINISHED) return;
  if (player !== state.players[state.current]) return;
  if (!canMove(player, token)) return;
  if (!state.rolling && !state.moving) pushHistory();
  if (state.gameState === GAME_STATES.IDLE) state.gameState = GAME_STATES.PLAYING;
  state.moving = true;
  console.log("[Ludo] Token move", {
    player: player.label,
    token: token.id,
    from: token.pos,
    dice: state.dice,
    gameState: state.gameState,
  });
  render();

  if (token.pos === -1) {
    token.pos = 0;
    playTone(360, 0.05, "sine");
    pulse("move");
    render();
    bounceToken(player, token);
    await wait(180);
  } else {
    for (let step = 0; step < state.dice; step += 1) {
      token.pos += 1;
      playTone(300 + step * 18, 0.04, "sine");
      render();
      bounceToken(player, token);
      await wait(145);
    }
  }

  let captured = false;
  if (token.pos === 57 && !token.finished) {
    token.finished = true;
    player.finishedTokens = Math.min(4, player.finishedTokens + 1);
    console.log("[Ludo] Token finished", {
      player: player.label,
      token: token.id,
      finishedTokens: player.finishedTokens,
      gameState: state.gameState,
    });
    addLog(`${player.label} finished a token.`);
    playTone(640, 0.12, "triangle");
  } else if (token.pos < 52) {
    captured = captureAt(player, token);
  }

  if (captured) {
    state.captures += 1;
    board.classList.add("capture");
    pulse("kill");
    playTone(120, 0.16, "sawtooth");
    setTimeout(() => board.classList.remove("capture"), 350);
  }

  if (checkWinner(player)) {
    state.moving = false;
    render();
    return;
  }

  const extraTurn = state.dice === 6 || captured;
  state.moving = false;
  state.rolled = false;
  state.dice = null;
  render();

  if (extraTurn) {
    addLog(`${player.label} gets another roll.`);
  } else {
    nextTurn();
  }
}

function chooseBestMove() {
  const player = state.players[state.current];
  const moves = movableTokens();
  if (!moves.length) return null;

  const captureMove = moves.find((token) => {
    const target = token.pos === -1 ? 0 : token.pos + state.dice;
    if (target >= 52) return false;
    const absolute = absolutePosition(player, target);
    if (safeCells.has(absolute)) return false;
    return state.players.some((opponent) => opponent !== player && opponent.tokens.some((other) => other.pos >= 0 && other.pos < 52 && absolutePosition(opponent, other.pos) === absolute));
  });
  if (captureMove) return captureMove;

  return moves
    .slice()
    .sort((a, b) => {
      const finishA = (a.pos === -1 ? 0 : a.pos + state.dice) === 57 ? 1 : 0;
      const finishB = (b.pos === -1 ? 0 : b.pos + state.dice) === 57 ? 1 : 0;
      if (finishA !== finishB) return finishB - finishA;
      if (a.pos === -1 && b.pos !== -1) return -1;
      if (b.pos === -1 && a.pos !== -1) return 1;
      return b.pos - a.pos;
    })[0];
}

function captureAt(player, token) {
  const absolute = absolutePosition(player, token.pos);
  if (safeCells.has(absolute)) return false;

  let captured = false;
  state.players.forEach((opponent) => {
    if (opponent === player) return;
    opponent.tokens.forEach((other) => {
      if (other.pos < 0 || other.pos >= 52) return;
      if (absolutePosition(opponent, other.pos) === absolute) {
        other.pos = -1;
        captured = true;
        addLog(`${player.label} captured ${opponent.label}.`);
      }
    });
  });
  return captured;
}

function bounceToken(player, token) {
  requestAnimationFrame(() => {
    const tokenEl = board.querySelector(`[data-player="${player.id}"][data-token="${token.id}"]`);
    if (!tokenEl) return;
    tokenEl.classList.add("bounce");
    setTimeout(() => tokenEl.classList.remove("bounce"), 260);
  });
}

function nextTurn() {
  if (state.winner || state.gameState === GAME_STATES.FINISHED) return;
  state.current = (state.current + 1) % state.players.length;
  state.rolled = false;
  state.rolling = false;
  state.moving = false;
  state.dice = null;
  addLog(`${state.players[state.current].label}'s turn.`);
  render();
}

function addLog(message) {
  state.log.unshift(message);
}

function pushHistory() {
  state.history.push(JSON.stringify({
    players: state.players.map((player) => ({
      id: player.id,
      finishedTokens: player.finishedTokens,
      tokens: player.tokens.map((token) => ({ ...token })),
    })),
    gameState: state.gameState,
    current: state.current,
    dice: state.dice,
    rolled: state.rolled,
    winner: state.winner ? state.winner.id : null,
    rolls: state.rolls,
    captures: state.captures,
    log: state.log.slice(0, 12),
  }));
  state.history = state.history.slice(-12);
}

function undoLast() {
  if (state.rolling || state.moving || !state.history.length) return;
  const snapshot = JSON.parse(state.history.pop());
  state.players.forEach((player) => {
    const saved = snapshot.players.find((item) => item.id === player.id);
    if (!saved) return;
    player.finishedTokens = saved.finishedTokens || 0;
    player.tokens.forEach((token, index) => Object.assign(token, saved.tokens[index]));
  });
  state.gameState = normalizeGameState(snapshot.gameState, snapshot.winner);
  state.current = snapshot.current;
  state.dice = snapshot.dice;
  state.rolled = snapshot.rolled;
  state.winner = snapshot.winner ? state.players.find((player) => player.id === snapshot.winner) : null;        
  state.rolls = snapshot.rolls;
  state.captures = snapshot.captures;
  state.log = ["Undo applied.", ...snapshot.log];
  render();
}

function updateTimer() {
  if (!state) return;
  const elapsed = Math.max(0, Math.floor((Date.now() - state.startedAt) / 1000));
  const minutes = String(Math.floor(elapsed / 60)).padStart(2, "0");
  const seconds = String(elapsed % 60).padStart(2, "0");
  matchTime.textContent = `${minutes}:${seconds}`;
}

function updateWinnerOverlay() {
  if (!state.winner || state.gameState !== GAME_STATES.FINISHED) {
    winnerOverlay.hidden = true;
    return;
  }
  winnerTitle.textContent = `${state.winner.label} Wins`;
  winnerSummary.textContent = `${state.rolls} rolls, ${state.captures} captures, ${matchTime.textContent} match time.`;
  winnerOverlay.hidden = false;
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function pulse(type) {
  if (!hapticToggle.checked || !navigator.vibrate) return;
  if (type === "kill") navigator.vibrate([80, 35, 120]);
  else if (type === "dice") navigator.vibrate(40);
  else navigator.vibrate(18);
}

function playTone(frequency, duration, wave) {
  if (!soundToggle.checked) return;
  audioContext ||= new (window.AudioContext || window.webkitAudioContext)();
  const oscillator = audioContext.createOscillator();
  const gain = audioContext.createGain();
  oscillator.type = wave;
  oscillator.frequency.value = frequency;
  gain.gain.setValueAtTime(0.001, audioContext.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.06, audioContext.currentTime + 0.01);
  gain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + duration);
  oscillator.connect(gain);
  gain.connect(audioContext.destination);
  oscillator.start();
  oscillator.stop(audioContext.currentTime + duration + 0.02);
}

function startGame() {
  state = createState();
  renderBoardBase();
  addLog(`${state.players[state.current].label}'s turn.`);
  render();
  updateTimer();
  clearInterval(timerId);
  timerId = setInterval(updateTimer, 1000);
}

diceButton.addEventListener("click", rollDice);
newGameButton.addEventListener("click", startGame);
winnerNewGame.addEventListener("click", startGame);
undoButton.addEventListener("click", undoLast);
bestMoveButton.addEventListener("click", () => {
  const token = chooseBestMove();
  if (token) moveToken(state.players[state.current], token);
});
fullscreenButton.addEventListener("click", () => {
  const target = document.querySelector(".game-panel");
  if (!document.fullscreenElement) target.requestFullscreen?.();
  else document.exitFullscreen?.();
});
playerCountSelect.addEventListener("change", startGame);
assistToggle.addEventListener("change", render);
themeSelect.addEventListener("change", () => {
  document.body.classList.remove("theme-aura", "theme-royal", "theme-ember");
  document.body.classList.add(`theme-${themeSelect.value}`);
});

startGame();
