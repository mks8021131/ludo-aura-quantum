const board = document.getElementById("board");
const diceButton = document.getElementById("diceButton");
const diceCube = document.getElementById("diceCube");
const helperText = document.getElementById("helperText");
const turnName = document.getElementById("turnName");
const turnDot = document.getElementById("turnDot");
const turnState = document.getElementById("turnState");
const scoreGrid = document.getElementById("scoreGrid");
const newGameButton = document.getElementById("newGameButton");
const undoButton = document.getElementById("undoButton");
const bestMoveButton = document.getElementById("bestMoveButton");
const winnerNewGame = document.getElementById("winnerNewGame");
const playerCountSelect = document.getElementById("playerCount");
const themeSelect = document.getElementById("themeSelect");
const turnSpeedSelect = document.getElementById("turnSpeed");
const boardStyleSelect = document.getElementById("boardStyle");
const autoPlayToggle = document.getElementById("autoPlayToggle");
const soundToggle = document.getElementById("soundToggle");
const hapticToggle = document.getElementById("hapticToggle");
const winnerOverlay = document.getElementById("winnerOverlay");
const winnerTitle = document.getElementById("winnerTitle");
const winnerSummary = document.getElementById("winnerSummary");
const settingsOverlay = document.getElementById("settingsOverlay");
const openSettings = document.getElementById("openSettings");
const closeSettings = document.getElementById("closeSettings");
const resetGameBtn = document.getElementById("resetGameBtn");
const resetSettingsBtn = document.getElementById("resetSettingsBtn");

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
let state;
let audioContext;

function createState() {
  const playerCount = Number(playerCountSelect.value);
  return {
    players: colors.slice(0, playerCount).map((color) => ({
      ...color,
      tokens: Array.from({ length: 4 }, (_, id) => ({ id, pos: -1, finished: false })),
    })),
    current: 0,
    dice: 1,
    rolled: false,
    rolling: false,
    moving: false,
    winner: null,
    history: [],
    startedAt: Date.now(),
  };
}

function cellToStyle(row, col) {
  const cell = 100 / 15;
  return {
    left: `${col * cell}%`,
    top: `${row * cell}%`,
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
  if (!state.rolled || state.rolling || state.moving || state.winner || token.finished) return false;
  if (token.pos === -1) return state.dice === 6;
  return token.pos + state.dice <= 57;
}

function movableTokens() {
  const player = state.players[state.current];
  return player.tokens.filter((token) => canMove(player, token));
}

function renderBoardBase() {
  board.innerHTML = "";
  const boardStyle = boardStyleSelect.value;
  board.className = `ludo-board style-${boardStyle}`;

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
  turnState.textContent = state.winner ? "Game over" : state.rolling ? "Rolling" : state.moving ? "Moving" : state.rolled ? "Choose token" : "Roll dice";
  
  helperText.textContent = helperMessage();
  updateWinnerOverlay();

  document.querySelectorAll(".token, .move-hint").forEach((node) => node.remove());
  renderHints();
  renderTokens();
  renderScores();
}

function helperMessage() {
  if (state.winner) return "Match finished!";
  if (state.rolling) return "Aura Engine rolling...";
  if (state.moving) return "Advancing quantum field...";
  if (!state.rolled) return "Tap the dice to roll.";
  const moves = movableTokens().length;
  if (moves === 0) return "No legal moves. Passing turn.";
  return `${moves} valid moves. Tap a glowing token.`;
}

function renderHints() {
  if (!state.rolled || state.moving || state.rolling || state.winner) return;
  const player = state.players[state.current];
  player.tokens.forEach((token) => {
    if (!canMove(player, token)) return;
    const target = token.pos === -1 ? 0 : token.pos + state.dice;
    const [row, col] = target < 52 ? track[absolutePosition(player, target)] : target < 57 ? player.home[target - 52] : [7, 7];
    const hint = document.createElement("span");
    hint.className = "move-hint";
    hint.style.color = player.css;
    Object.assign(hint.style, cellToStyle(row, col));
    board.appendChild(hint);
  });
}

function renderTokens() {
  state.players.forEach((player) => {
    player.tokens.forEach((token) => {
      const [row, col] = boardPosition(player, token);
      const tokenEl = document.createElement("div");
      tokenEl.className = "token";
      tokenEl.style.backgroundColor = player.css;
      Object.assign(tokenEl.style, cellToStyle(row, col));

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
    const active = index === state.current && !state.winner;
    const finished = player.tokens.filter(t => t.finished).length;
    const card = document.createElement("div");
    card.className = `glass-panel score-card ${active ? "active" : ""}`;
    card.style.color = player.css;
    card.innerHTML = `
      <div style="width: 12px; height: 12px; border-radius: 50%; background: currentColor;"></div>
      <div style="flex: 1;">
        <div style="font-weight: 800; font-size: 0.9rem;">${player.label}</div>
        <div style="font-size: 0.7rem; color: var(--text-secondary);">${finished}/4 finished</div>
      </div>
    `;
    scoreGrid.appendChild(card);
  });
}

async function rollDice() {
  if (state.rolling || state.moving || state.rolled || state.winner) return;
  state.rolling = true;
  diceCube.classList.add("rolling");
  playTone(200, 0.1, "triangle");

  const result = Math.floor(Math.random() * 6) + 1;
  await wait(800);

  state.dice = result;
  state.rolling = false;
  state.rolled = true;
  diceCube.classList.remove("rolling");
  
  // Apply rotation based on result
  const rotations = {
    1: 'rotateX(0deg) rotateY(0deg)',
    2: 'rotateX(-90deg) rotateY(0deg)',
    3: 'rotateX(0deg) rotateY(-90deg)',
    4: 'rotateX(0deg) rotateY(90deg)',
    5: 'rotateX(90deg) rotateY(0deg)',
    6: 'rotateX(180deg) rotateY(0deg)'
  };
  diceCube.style.transform = rotations[result];
  
  render();
  
  if (!movableTokens().length) {
    await wait(1000);
    nextTurn();
  } else if (autoPlayToggle.checked) {
    await wait(500);
    const moves = movableTokens();
    moveToken(state.players[state.current], moves[Math.floor(Math.random() * moves.length)]);
  }
}

async function moveToken(player, token) {
  if (!canMove(player, token)) return;
  state.moving = true;
  render();

  const speed = { slow: 400, normal: 200, fast: 80 }[turnSpeedSelect.value];

  if (token.pos === -1) {
    token.pos = 0;
    playTone(400, 0.05, "sine");
    render();
    await wait(speed);
  } else {
    const steps = state.dice;
    for (let i = 0; i < steps; i++) {
      token.pos += 1;
      playTone(400 + i * 20, 0.04, "sine");
      render();
      await wait(speed);
    }
  }

  // Capture logic
  if (token.pos < 52 && !safeCells.has(absolutePosition(player, token.pos))) {
    const abs = absolutePosition(player, token.pos);
    state.players.forEach(opp => {
      if (opp === player) return;
      opp.tokens.forEach(t => {
        if (t.pos >= 0 && t.pos < 52 && absolutePosition(opp, t.pos) === abs) {
          t.pos = -1;
          pulse("kill");
        }
      });
    });
  }

  if (token.pos === 57) {
    token.finished = true;
    playTone(600, 0.2, "sine");
  }

  if (player.tokens.every(t => t.finished)) {
    state.winner = player;
  }

  state.moving = false;
  state.rolled = false;
  
  if (state.winner) {
    render();
    return;
  }

  if (state.dice === 6) {
    render();
    if (autoPlayToggle.checked) setTimeout(rollDice, 500);
  } else {
    nextTurn();
  }
}

function nextTurn() {
  state.current = (state.current + 1) % state.players.length;
  state.rolled = false;
  state.dice = 1;
  render();
  if (autoPlayToggle.checked) setTimeout(rollDice, 500);
}

function updateWinnerOverlay() {
  if (!state.winner) {
    winnerOverlay.hidden = true;
    return;
  }
  winnerTitle.textContent = `${state.winner.label} Wins!`;
  winnerOverlay.hidden = false;
}

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function playTone(freq, dur, type) {
  if (!soundToggle.checked) return;
  audioContext ||= new (window.AudioContext || window.webkitAudioContext)();
  const osc = audioContext.createOscillator();
  const gain = audioContext.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  gain.gain.setValueAtTime(0.05, audioContext.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + dur);
  osc.connect(gain);
  gain.connect(audioContext.destination);
  osc.start();
  osc.stop(audioContext.currentTime + dur);
}

function pulse(type) {
  if (hapticToggle.checked && navigator.vibrate) {
    navigator.vibrate(type === "kill" ? [100, 50, 100] : 20);
  }
}

function startGame() {
  state = createState();
  renderBoardBase();
  render();
}

// Event Listeners
diceButton.addEventListener("click", rollDice);
newGameButton.addEventListener("click", startGame);
winnerNewGame.addEventListener("click", startGame);
openSettings.addEventListener("click", () => settingsOverlay.classList.add("active"));
closeSettings.addEventListener("click", () => settingsOverlay.classList.remove("active"));
resetGameBtn.addEventListener("click", startGame);
resetSettingsBtn.addEventListener("click", () => {
  playerCountSelect.value = "4";
  themeSelect.value = "neon";
  turnSpeedSelect.value = "normal";
  boardStyleSelect.value = "gradient";
  autoPlayToggle.checked = false;
  soundToggle.checked = true;
  hapticToggle.checked = true;
  themeSelect.dispatchEvent(new Event("change"));
  startGame();
});

themeSelect.addEventListener("change", () => {
  document.body.className = `theme-${themeSelect.value}`;
});

boardStyleSelect.addEventListener("change", renderBoardBase);

startGame();
