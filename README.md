# DSD-2026-SUT
Solutions for theoretical/lab assignments from the *Digital System Design (DSD)* course, **Spring 2026** (بهار ۱۴۰۵),
Computer Engineering Department, **Sharif University of Technology (SUT)**.

## Course Overview
This repository contains my work for the DSD course at SUT, which covers the design, description, and
verification of digital hardware — combinational and sequential circuit design, finite state machines,
ASM charts, and hardware description with **Verilog** (behavioral & structural), simulated with
`iverilog`/`vvp` and viewed in GTKWave.

The course covers:
- **ASM/FSM**: FSM diagrams and their use; modeling and synthesizing control circuits with FSMs; ASM charts
  and digital system design with them; control unit vs. datapath; datapath synthesis from an ASM chart;
  various methods of synthesizing a control unit from an ASM chart
- **Introduction to HDLs**: overview of hardware description languages; concurrent vs. sequential code;
  digital design flow; overview of Verilog's features and comparison with other HDLs; why HDLs matter
- **Verilog fundamentals**: general structure of a Verilog description; top-down vs. bottom-up design;
  structural vs. behavioral modeling; `module`, `initial`, `always`, `@`; modular design; testbenches and
  how to write a correct one
- **Data types & core concepts**: `wire` vs. `reg`; 4-valued logic and signal strength; arrays and vectors;
  `real`/`integer`/`time`, strings; `parameter` and parametric design; system tasks, directives, macros;
  hierarchical naming
- **Structural modeling**: module ports and port types; port-mapping methods; rules for wires/variables in
  port connections; gate-level design; delay modeling in structural descriptions
- **Dataflow modeling**: delay modeling in dataflow descriptions; inertial vs. transport delay; operators;
  describing level-sensitive and edge-sensitive sequential circuits in dataflow style
- **Behavioral modeling**: blocking vs. non-blocking assignments; event control; decision/loop statements;
  functions and tasks; types of event control (regular, level-sensitive, named); types of timing control
  (regular, inter-assignment, zero); inertial/transport delay modeling in behavioral code; race conditions
  in concurrent blocks; how a Verilog simulator executes code
- **Synthesizable coding in Verilog**: general rules for synthesizability (e.g., no delays in the
  description, division operator, ...); writing synthesizable behavioral code; avoiding combinational
  loops; loops in behavioral code and their effect on synthesis; 3-valued logic and its effect on
  synthesis; overview of how synthesis tools work
- **Digital system design with PLDs**: properties of digital systems; abstraction levels and modeling
  methods; applications of configurable circuits; overview of PLD types and their use in research/industry
- **SPLDs and CPLDs**: SPLD structures (PAL, PLA, ROM); CPLD structures; SPLD/CPLD fabrication technologies;
  CPLD case studies
- **FPGAs**: FPGA structures; LUT-based vs. MUX-based FPGAs; fabrication technologies (anti-fuse vs. SRAM);
  programmable interconnect methods; LUT-based and MUX-based FPGA case studies; capabilities of the latest
  FPGAs; overview of the newest programmable devices, especially FPSoCs

## Note on scope
Some of this course's assignments were given and discussed live in class without a distributed written
handout. For those (`HW-2`, `HW-3`, `HW-4`), I've added a short `README.md` inside each folder summarizing
the problem based on my submitted report, since there's no official assignment PDF to link. `HW-1` and
`HW-5` came with a proper PDF handout and are included as usual.

## Repository Structure
```
DSD-2026-SUT/
├── HW-1/   ASM chart → sequential circuit design (assignment PDF, .drawio diagram, LaTeX report)
├── HW-2/   Debugging a ripple up-counter testbench (in-class problem, see HW-2/README.md)
├── HW-3/   Delayed D flip-flop + 3-bit shift register in Verilog (in-class problem, see HW-3/README.md)
├── HW-4/   Sensitivity-list bug in a 2-to-1 MUX (in-class problem, see HW-4/README.md)
└── HW-5/   Verilog programming (assignment PDF), 4 sub-questions Q1-Q4, each with code + testbench + report
```

Each HW/question folder contains the submitted `.v` (and `_tb.v` testbench) source, the write-up PDF, and
a `LaTeX/` folder with the report source (`.tex`, `answers/`, `assets/` — shared style/fonts not duplicated,
see the template link below).

## Notes
- **LaTeX template:** All write-ups were typeset with my own reusable Persian/XeLaTeX assignment
  template — see [Persian-LaTeX-Assignment-Template](https://github.com/theQuantaBoy/Persian-LaTeX-Assignment-Template).
  To build any `HW-N/LaTeX/*.tex` here, drop it into a copy of that template (for its `commons/style.sty`
  and `fonts/`).
- Simulation artifacts (`a.out`, `.vcd` waveform dumps, `build/` directories) are excluded — only source
  Verilog and the report PDFs are kept.

## Information
**Instructor:** Dr. Ejlali (دکتر اجلالی)

**Student:** Mohsen Salah
**Student ID:** 403106238
