Original SEA.LIB is required to run.

Global vars and function names are recovered thanks to unstripped debug
information. 

Use Borland Turbo Assembler 2.0 and Borland Turbo Pascal 5.5 to produce
byte-exact executables. Compiled file will still be different in
non-essential parts, like DOS header and debug information.
This is due to inclusion of uninitalized garbage memory by compiler and
time-depended information (build date).

NB! AI is a cheater.
