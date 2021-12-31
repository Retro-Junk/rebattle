@echo off
tp55\tasm BADDRAW.ASM
tp55\TPC.EXE -b -v -$l- -$d+ -$v+ -$o+ -utp55 sea.pas
