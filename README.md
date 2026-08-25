# Healthy Pomodoro

An Omarchy bar widget for configurable focus sessions and gentle health prompts.

## Install

Once this repository has a public Git URL, install it with Omarchy's plugin
manager:

```bash
omarchy plugin add <git-url> --enable
```

The widget defaults to the right side of the bar. Move it later with:

```bash
omarchy bar move io.github.peterszarvas94.pomodoro --section right
```

Add an optional Hyprland shortcut in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + CTRL + ALT + P", "Healthy Pomodoro", "omarchy-shell shell toggle io.github.peterszarvas94.pomodoro")
```

Reload Hyprland after changing bindings:

```bash
hyprctl reload
hyprctl configerrors
```

## Local development

Clone the repository under `~/Projects`, then symlink the whole repository into
Omarchy's user plugin directory:

```bash
git clone <git-url> ~/Projects/omarchy-pomodoro
mkdir -p ~/.config/omarchy/plugins
ln -s ~/Projects/omarchy-pomodoro ~/.config/omarchy/plugins/io.github.peterszarvas94.pomodoro
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.peterszarvas94.pomodoro right
omarchy restart shell
```

Do not symlink individual files inside the plugin. Omarchy plugin validation
rejects internal symlinks; linking the complete plugin directory keeps the
repository as the single source of truth.

The shell follows this whole-directory link, but `omarchy plugin validate`
rejects a symlink passed as its plugin-folder argument. Validate the real
`~/Projects/omarchy-pomodoro` path, as shown below, rather than the installed
symlink path.

Validate changes before restarting the shell:

```bash
omarchy plugin validate ~/Projects/omarchy-pomodoro
qmllint -I /usr/share/omarchy/shell \
  ~/Projects/omarchy-pomodoro/BarWidget.qml \
  ~/Projects/omarchy-pomodoro/Panel.qml
```

## Use

- Left-click the bar icon to open the panel.
- Right-click starts, pauses, or resumes the timer.
- Middle-click skips the current phase.
- `Super+Ctrl+Alt+P` opens the panel.
- Inside the panel: `s` start, `p` pause, `r` reset, `n` skip, `z` postpone a break.
- `Left` / `Right` move between controls; `Enter` or `Space` activates buttons.
- On a duration field, `Up` / `Down` changes its value without entering the input.
- `Esc` always closes the panel.

The widget starts manually. It never locks the screen or prevents work. Breaks can
be postponed, and automatic transitions are optional.

## Evidence-informed design

The plugin deliberately does not call the classic 25/5 Pomodoro ratio medically
proven. It offers several cadences and editable values. Its prompts are based on
the direction of current guidance and evidence:

- WHO's physical-activity guidance says to limit sedentary time and replace it
  with movement; any amount is better than none.
- A randomized crossover trial in *Medicine & Science in Sports & Exercise*
  found acute cardiometabolic benefits from interrupting sitting, with the
  strongest glucose result at five minutes of light walking every 30 minutes.
  It was a small study (11 participants), so this is not a universal prescription.
- A systematic review and meta-analysis found that interrupting prolonged
  sitting can improve acute metabolic and vascular outcomes.
- OSHA's computer-workstation guidance recommends frequent short micro-breaks to
  stand, stretch, move, and look away from the screen.
- Eye-rest prompts encourage looking into the distance and blinking. The exact
  20-20-20 formula is presented as a practical cue, not a guaranteed treatment.

References:

- https://www.who.int/news-room/fact-sheets/detail/physical-activity
- https://doi.org/10.1249/mss.0000000000003109
- https://doi.org/10.1249/mss.0000000000000654
- https://doi.org/10.1007/s40279-018-0963-8
- https://www.osha.gov/etools/computer-workstations/work-process

This is a wellness aid, not medical advice. Choose movements appropriate for you
and stop if you experience pain, dizziness, numbness, or other concerning symptoms.
