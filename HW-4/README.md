# HW-4 — Context

This assignment was given and discussed live in class (no written handout was distributed), so there is
no separate assignment PDF here — only my submitted report and code.

**Problem:** Test a 2-to-1 multiplexer written in class (`MUX_2_1.v`) to demonstrate a synthesizable
behavioral-coding rule: when describing a combinational circuit behaviorally with a single `always @(...)`
block, **all** inputs of the combinational circuit must appear in the sensitivity list. The original module
deliberately omits the select input `sel` from its sensitivity list, so the simulated circuit fails to
react when only `sel` changes. `MUX_2_1_FIXED.v` corrects this by adding `sel` to the sensitivity list.
`testbench.v` exercises both versions to show the difference in simulated behavior.
