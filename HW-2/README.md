# HW-2 — Context

This assignment was given and discussed live in class (no written handout was distributed), so there is
no separate assignment PDF here — only my submitted report and code.

**Problem:** Simulate and debug a piece of Verilog code written in class implementing a 4-bit
asynchronous ripple up-counter (built from T flip-flops, counting 0–15 in binary). The initial simulation
run showed a bug: the testbench declared the counter's output as a single-bit `wire q`, so the compiler
silently truncated/padded the counter's actual 4-bit output — the simulated waveform only showed the
least-significant bit toggling instead of a full 4-bit count. The task was to find this bug and fix the
testbench so the simulation correctly reflects the counter's behavior.

- `original/` — the initial (buggy) testbench and simulation
- `fixed/` — the corrected testbench
- `LaTeX/` and the submitted PDF explain the debugging process and the fix.
