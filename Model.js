// Timing and prompt content are kept independent of Qt so they stay easy to
// inspect and test. The cadence is configurable; the health prompts are not a
// claim that one Pomodoro schedule is medically optimal.

function clamp(value, min, max) {
  var n = Number(value)
  if (!isFinite(n)) n = min
  return Math.max(min, Math.min(max, Math.round(n)))
}

function minutes(value, fallback, max) {
  return clamp(value, 1, max || 120) || fallback
}

function formatSeconds(seconds) {
  var value = Math.max(0, Math.ceil(Number(seconds) || 0))
  var mins = Math.floor(value / 60)
  var secs = value % 60
  return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs
}

function phaseMinutes(phase, focus, shortBreak, longBreak) {
  if (phase === "focus") return focus
  return phase === "longBreak" ? longBreak : shortBreak
}

function nextPhase(phase, completed, longBreakAfter) {
  if (phase !== "focus") return "focus"
  return completed % longBreakAfter === 0 ? "longBreak" : "shortBreak"
}

var PROMPTS = {
  shortBreak: [
    {title: "Stand and move", body: "Stand up, walk lightly, or change position for a few minutes."},
    {title: "Stretch gently", body: "Roll your shoulders, open your chest, and move your wrists without pain."},
    {title: "Rest your eyes", body: "Look across the room, blink slowly, and let your eyes refocus."},
    {title: "Change posture", body: "Sit down if you have been standing, or stand and move if you have been sitting."}
  ],
  longBreak: [
    {title: "Screen-free recovery", body: "Step away from the screen. Walk, stretch, hydrate, or rest your eyes."},
    {title: "Move your whole body", body: "Take a short walk or do easy mobility. Keep it comfortable, not strenuous."},
    {title: "Reset your workstation", body: "Change posture, relax your shoulders, and check that your screen is comfortable."}
  ],
  focus: [
    {title: "Ready to focus", body: "Settle into a comfortable posture and begin the next focused block."}
  ]
}

function prompt(phase, index) {
  var choices = PROMPTS[phase] || PROMPTS.focus
  return choices[Math.abs(Number(index) || 0) % choices.length]
}
