(*Use Turbo Pascal 5.5 and Turbo Assembler 2.0 to compile*)
uses crt, dos, graph;
{$F+ $O+ $I-}
type
  MYREC = record
    NAM:string[10];
    GAME:word;
    WIN:integer;
    RECS:byte;
    CONTROL:byte;
  end;

  SHIPTYPE = record
    SIZE, TIP, ORT, CUR:byte;
    XSHIP, YSHIP:integer;
  end;

  ARR = array[0..1] of word;
  SCRARR = array[0..29000] of byte;

var
  CENTER:integer; ZACH:array[1..7] of integer; RECOR:array[0..255] of MYREC;
  XMY, YMY, XPC, YPC:integer; CASEPC:integer; NUMREC:integer; MYNOMER:integer;
  POINT1, POINT2:word; STEP1:word; SCORE1, SCORE2:word;
  NAME:string[10];
  POLE1, POLE2:array[0..11, 0..11] of integer;
  POLE11, POLE22:array[0..11, 0..11] of byte;
  SHIP:array[1..20] of SHIPTYPE; 
  ISOU:integer; X, Y:integer; P:integer; 
  HOD:word; K:word; TIME:word; 
  NUM:integer; NUMPIC:integer; 
  SCR    :SCRARR absolute $A000:$0;
  SCRMAIN:SCRARR absolute $A000:$5DC0;
  SCRBUFF:SCRARR absolute $A000:$BB80;
  REGS:Registers; 
  T:integer; I, J:integer; 
  T1, T2, T3, T4:word; 
  SYM:char; 
  PIC:array[0..120] of ^SCRARR; 
  STR1:string;

procedure BADDRAW(var p:SCRARR;var scr:SCRARR;x,y,t:integer);external; {$L BADDRAW}
(*Calculate high scores entry checksum*)
function SUMMCONTROL(index:integer):integer;
var
  summ, i:word;
begin
  summ := 0;
  with RECOR[index] do begin
    for i := 1 to Length(NAM) do summ := ord(NAM[i]) + summ;
    summ := summ + GAME + RECS + WIN;
    summ := summ mod 256;
    SUMMCONTROL := summ mod 256;
  end;
end;

(*Write high scores to file*)
procedure WRITEREC;
var
  s:string;
  f:file of MYREC;
  i:integer;
begin
  s := 'sea.pic';
  Assign(f, s);
  Rewrite(f);
  for i := 0 to NUMREC do begin
    RECOR[i].CONTROL := SUMMCONTROL(i);
    Write(f, RECOR[i]);
  end;
  Close(f);
end;

(*Switch to text mode and terminate*)
procedure EXITING;
begin
  NOSOUND;
  REGS.ax := 3; INTR($10, REGS);
  WRITEREC;
  Halt(0);
end;
(*Switch to graphics mode and init mouse*)
procedure INITGR;
begin
  REGS.ax := $0D; INTR($10, REGS);
  REGS.ax := 2; INTR($33, REGS);
end;




function FIXA(v:word):word;
var
  i:word;
  summ:word;
begin
  summ := 0;
  for i := 0 to 8 - 1 do summ := summ or ((((v shr i) and 1) shl i) shl i);
  FIXA := summ * 2 + summ;
end;
(*Draw small text*)
procedure MYTEXT(s:string;x,y,z,a:integer;b,c:integer;var screen:SCRARR);
var
  lofont:scrarr absolute $F000:$FA6E;
  hifont:pointer;
  dd:word;
  ff:word;
  ee:word;
  i,j:word;
  aa:integer;
  bb, cc, hh, ii, gg:byte;
begin
  hifont := Ptr(Word(Ptr(0,$7E)^), Word(Ptr(0,$7C)^));
  aa := x div 8;
  bb := x mod 8;
  cc := 8 - bb;
  dd := y * a + aa;
  Port[$3CE] := 5; Port[$3CF] := 2;
  for i := 1 to Length(s) do begin
    ee := Ord(s[i]);
    if ee > 127 then ee := ee - 128;
    ff := ee * 8;
    ee := Ord(s[i]);
    if z < 2 then
      for j := 0 to 8 - 1 do begin
        if j < 4 then gg := b else gg := c;
        if ee < 128 then hh := lofont[ff+j] else hh := SCRARR(hifont^)[ff+j];
        Port[$3CE] := 8; Port[$3CF] := hh shr bb;
        ii := screen[j * a + dd];
        FillChar(screen[j * a + dd], 1, gg);
        if cc <> 8 then begin
          Port[$3CE] := 8; Port[$3CF] := hh shl cc;
          ii := screen[j * a + dd + 1];
          FillChar(screen[j * a + dd + 1], 1, gg);
        end;
      end
    else for j := 0 to 8 - 1 do begin
        if j < 4 then gg := b else gg := c;
        if ee < 128 then hh := lofont[ff+j] else hh := SCRARR(hifont^)[ff+j];
        Port[$3CE] := 8; Port[$3CF] := hh shr bb;
        ii := screen[j * a * 2 + dd];
        FillChar(screen[j * a * 2 + dd], 1, gg);
        ii := screen[j * a * 2 + dd + a];
        FillChar(screen[j * a * 2 + dd + a], 1, gg);
        if cc <> 8 then begin
          Port[$3CE] := 8; Port[$3CF] := hh shl cc;
          ii := screen[j * a * 2 + dd + 1];
          FillChar(screen[j * a * 2 + dd + 1], 1, gg);
          ii := screen[j * a * 2 + dd + 1 + a];
          FillChar(screen[j * a * 2 + dd + 1 + a], 1, gg);
        end;
    end;
    dd := dd + 1;
  end;
end;
(*Draw large text*)
procedure MYTEXT2(s:string;x,y,z:integer;b,c:integer;var screen:SCRARR);
var
  dd:word;
  ff:word;
  i,j:word;
  ee:word;
  lofont:scrarr absolute $F000:$FA6E;
  hifont:pointer;
  hh, gg:byte;
  jj:word;
begin
  hifont := Ptr(Word(Ptr(0,$7E)^), Word(Ptr(0,$7C)^));
  dd := y * 40 + x;
  Port[$3CE] := 5; Port[$3CF] := 2;
  for i := 1 to Length(s) do begin
    ee := Ord(s[i]);
    if ee > 127 then ee := ee - 128;
    ff := ee * 8;
    ee := Ord(s[i]);
    if z < 2 then
      for j := 0 to 8 - 1 do begin
        if j < 4 then gg := b else gg := c;
        if ee < 128 then hh := lofont[ff+j] else hh := SCRARR(hifont^)[ff+j];
        jj := FIXA(hh);
        Port[$3CE] := 8; Port[$3CF] := Hi(jj);
        hh := screen[j * 40 + dd];
        FillChar(screen[j * 40 + dd], 1, gg);
        Port[$3CE] := 8; Port[$3CF] := Lo(jj);
        hh := screen[j * 40 + dd + 1];
        FillChar(screen[j * 40 + dd + 1], 1, gg);
      end
    else for j := 0 to 8 - 1 do begin
        if j < 4 then gg := b else gg := c;
        if ee < 128 then hh := lofont[ff+j] else hh := SCRARR(hifont^)[ff+j];
        jj := FIXA(hh);
        Port[$3CE] := 8; Port[$3CF] := Hi(jj);
        hh := screen[j * (40 * 2) + dd];
        FillChar(screen[j * (40 * 2) + dd], 1, gg);
        hh := screen[j * (40 * 2) + dd + 40];
        FillChar(screen[j * (40 * 2) + dd + 40], 1, gg);
        Port[$3CE] := 8; Port[$3CF] := Lo(jj);
        hh := screen[j * (40 * 2) + dd + 1];
        FillChar(screen[j * (40 * 2) + dd + 1], 1, gg);
        hh := screen[j * (40 * 2) + dd + (1 + 40)];
        FillChar(screen[j * (40 * 2) + dd + (1 + 40)], 1, gg);
    end;
    dd := dd + 2;
  end;
end;

(*Read graphics objects*)
procedure READMY;
var
  hdr:array[0..127] of byte;
  libname:string;
  f:file;
begin
  libname := 'sea.lib';
  Assign(f, libname);
  {$I-} Reset(f, 128); {$I+}
  if IOResult <> 0 then begin
    Writeln('File ', libname, ' not found.');
    Halt(1);
  end;
  BlockRead(f, hdr, 1);
  for I := 1 to hdr[0] do begin
    J := hdr[I];
    GetMem(PIC[I - 1], J * 128);
    BlockRead(f, PIC[I - 1]^, J);
  end;
  Close(f);
end;
(*Validate high score entry checksum*)
function CHECKCONTROL(index:integer):boolean;
var
  summ, i:word; 
begin
  summ := 0;
  with RECOR[index] do begin
    for i := 1 to Length(NAM) do summ := ord(NAM[i]) + summ;
    summ := summ + GAME + RECS + WIN;
    summ := summ mod 256;
    if CONTROL <> summ then CHECKCONTROL := false else CHECKCONTROL := true;
  end;
end;


(*Read and verify high scores from file*)
procedure READREC;
var
  n:string;
  f:file of MYREC;
begin
  n := 'sea.pic';
  Assign(f, n);
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then begin
    WriteLn('File ', n, ' not found.');
    for NUMREC := 0 to 7 - 1 do with RECOR[NUMREC] do
      case NUMREC of
        0: begin NAM := 'BADY'; GAME := 3; WIN := 10; RECS := 27; CONTROL := 0; end;
        1: begin NAM := 'BELLA'; GAME := 10; WIN := 6; RECS := 27; CONTROL := 0; end;
        2: begin NAM := 'BILL'; GAME := 10; WIN := 5; RECS := 32; CONTROL := 0; end;
        3: begin NAM := 'BADY'; GAME := 8; WIN := 4; RECS := 35; CONTROL := 0; end;
        4: begin NAM := 'KILLER'; GAME := 6; WIN := 3; RECS := 38; CONTROL := 0; end;
        5: begin NAM := 'FEDOR'; GAME := 4; WIN := 2; RECS := 40; CONTROL := 0; end;
        6: begin NAM := 'ALEX'; GAME := 2; WIN := 1; RECS := 48; CONTROL := 0; end;
      end;
    NUMREC := 6;
  end else begin
    NUMREC := 0;
    while (NUMREC < 255) and not Eof(f) do begin
      Read(f, RECOR[NUMREC]);
      if (not CHECKCONTROL(NUMREC)) and (NUMREC > 0) then begin with RECOR[NUMREC] do begin
        GAME := 0; WIN := 0; RECS := 99; CONTROL := 0;
      end; end;
      inc(NUMREC);
    end;
    dec(NUMREC);
    Close(f);
  end;
end;

(*Ask for player's name*)
procedure INPUTNAME;
var
  i, j:integer;
  c:integer;
  k:integer;
  nam:string;
  l:integer;
begin
  Port[$3CE] := 5; Port[$3CF] := 2;
  Port[$3CE] := 8; Port[$3CF] := $FF;
  FillChar(SCR, 960, 7);
  MYTEXT2('NAME:', 1, 5, 2, 0, 0, SCR);
  MYTEXT2('NAME:', 1, 4, 2, 14, 14, SCR);
  nam := '';
  i := 0;
  repeat
    j := 0;
    SYM := #7;
    repeat
      inc(j);
      if j < 10 then c := 12 else c := 7;
      if j > 20 then j := 0;
      MYTEXT2('Ü', i * 2 + 11, 7, 2, c, c, SCR);
      DELAY(20);
      REGS.ax := 3; INTR($33, REGS);
    until KEYPRESSED or (REGS.bx > 0);
    for k := 1 to 20 do SOUND((k * k * 4 + 20) * ISOU);
    NOSOUND;
    MYTEXT2('Ü', i * 2 + 11, 7, 2, 7, 7, SCR);
    if KEYPRESSED then SYM := UpCase(READKEY);
    if SYM in ['0'..'9','A'..'Z', '_'] then begin
      nam := nam + SYM;
      MYTEXT2(SYM, i * 2 + 11, 5, 2, 0, 0, SCR);
      MYTEXT2(SYM, i * 2 + 11, 4, 2, 12, 12, SCR);
      i := i + 1;
    end;
    if (SYM = #8) and (i > 0) then begin
      nam := Copy(nam, 1, i - 1);
      i := i - 1;
      MYTEXT2('Û', i * 2 + 11, 5, 2, 7, 7, SCR);
      MYTEXT2('Û', i * 2 + 11, 4, 2, 7, 7, SCR);
    end;
  until (i > 9) or (((SYM = #13) or (REGS.bx > 0)) and (i > 2)) or (SYM = #27);
  if SYM = #27 then EXITING;
  NAME := nam;
  j := 0;
  for i := 1 to NUMREC do
    if RECOR[i].NAM = NAME then j := i;
  MYNOMER := j;
end;
(*Screen change with droplets effect*)
procedure SMENA;
var
  o:array[0..39] of byte;
  i, ofs, j, k:integer;
begin
  SYM := #7;
  Port[$3CE] := 5; Port[$3CF] := 1;
  j := 8000;
  for i := 0 to 39 do o[i] := 0;
  repeat
    repeat
      i := Random(40);
      if KEYPRESSED then begin SYM := READKEY;
        if SYM = #0 then begin SYM := READKEY;
          if SYM = #$3B then ISOU := 1 - ISOU;
        end;
        if SYM = #27 then EXITING;
      end;

    until o[i] < 200;
    if j mod 50 = 0 then begin NOSOUND;
      SOUND((j mod 200 + 30) * ISOU);
    end;
    ofs := o[i] * 40 + i;
    Port[$3CE] := 5; Port[$3CF] := 1;
    for k := 0 to 12 - 1 do if k * 40 + ofs < 8000 then
      Move(SCRBUFF[k * 40 + ofs], SCR[k * 40 + ofs], 1);
    if o[i] < 189 then
      BADDRAW(PIC[16]^, SCR, i * 8, o[i] + 4, 0);
    inc(o[i], 4);
    dec(j, 4);
  until j <= 0;
  NOSOUND;
end;





(*Draw player's ships*)
procedure DRAWSHIP1;
var
  i:integer;
  x,y,p:integer;
begin
  for i := 1 to 10 do with SHIP[i] do if CUR > 0 then begin
    if ORT = 0 then begin
      x := XSHIP * 14 - 5;
      y := YSHIP * 14 + 13;
      p := TIP + 4;
    end else begin
      x := XSHIP * 14 - 4;
      y := YSHIP * 14 + 9;
      p := TIP;
    end;
    BADDRAW(PIC[p]^, SCRBUFF, x, y, 1);
  end;
end;

(*Draw sunken ships*)
procedure DRDR;
begin
  for I := 1 to 10 do for J := 1 to 10 do begin
    if POLE1[i, j] > 100 then BADDRAW(PIC[Random(4) + 12]^, SCRMAIN, I * 14 + 1, J * 14 + 15, 1);
    if POLE2[i, j] > 100 then BADDRAW(PIC[Random(4) + 12]^, SCRMAIN, I * 14 + 159, J * 14 + 15, 1);
  end;
  BADDRAW(PIC[Random(3) + 53]^, SCRMAIN, 60, 0, 3);
  BADDRAW(PIC[Random(3) + 50]^, SCRMAIN, 250, 0, 3);

end;
(*Player's move*)
procedure HOD1;
var
  pp:integer;
  d, e, xx, yy:integer;
  f:integer;
  z:integer;
  qx, qy, qz:integer;
  k:integer;
  rx, ry, px, py:integer;
  r1, r2:real;


  procedure Missile(index:integer;b,c,d:integer);
  begin
    Port[$3CE] := 5; Port[$3CF] := 1;
    Move(SCRBUFF, SCRMAIN, 8000);
    DRDR;
    BADDRAW(PIC[index]^, SCRMAIN, b, c, d);
    if z > 0 then begin
      inc(z);
      qx := qx + 2;
      qy := qy - 1;
      if z > 10 then qz := 21 else qz := 20;
      if z > 20 then z := 0;
      BADDRAW(PIC[qz]^, SCRMAIN, qx + 3, qy - 2, 0);
    end;
    Port[$3CE] := 5; Port[$3CF] := 1;
    Move(SCRMAIN, SCR, 8000);
  end;





begin
  STR1 := 'ARROWS KEYS-MOVE';
  MYTEXT(STR1, 23, 182, 1, 40, 15, 15, SCRBUFF);
  MYTEXT(STR1, 22, 181, 1, 40, 8, 8, SCRBUFF);
  STR1 := 'ENTER-FIRE';
  MYTEXT(STR1, 47, 191, 1, 40, 15, 15, SCRBUFF);
  MYTEXT(STR1, 46, 190, 1, 40, 4, 4, SCRBUFF);
  STR1 := 'FIRES:';
  MYTEXT2(STR1, 22, 187, 1, 15, 15, SCRBUFF);
  MYTEXT2(STR1, 22, 186, 1, 4, 4, SCRBUFF);
  xx := XMY; yy := YMY; z := 0; TIME := 0;
  inc(STEP1);
  repeat
    Port[$3CE] := 5; Port[$3CF] := 1;
    Move(SCRBUFF, SCRMAIN, 8000);
    DRDR;
    if Random > 0.9 then pp := 18 else pp := 17;
    BADDRAW(PIC[pp]^, SCRMAIN, xx * 14 + 150, yy * 14 + 17, 11);
    Str(STEP1:2, STR1);
    MYTEXT2(STR1, 35, 180, 2, 15, 15, SCRMAIN);
    MYTEXT2(STR1, 35, 179, 2, 4, 12, SCRMAIN);

    Port[$3CE] := 5; Port[$3CF] := 1; Move(SCRMAIN, SCR, 8000);
    if KEYPRESSED then begin
      for I := 1 to 20 do SOUND((I * I * 4 + 20) * ISOU);
      NOSOUND;
      SYM := READKEY;
      if SYM = #0 then begin
        SYM := READKEY;
        if SYM = #$48 then dec(yy);
        if SYM = #$50 then inc(yy);
        if SYM = #$4B then dec(xx);
        if SYM = #$4D then inc(xx);
        if SYM = #$3B then ISOU := 1 - ISOU;
        if xx < 1 then xx := 10; if xx > 10 then xx := 1;
        if yy < 1 then yy := 10; if yy > 10 then yy := 1;
      end;
      if SYM = #13 then begin
        rx := 1; ry := 1;
        TIME := 0;
        repeat
          I := Random(10) + 1; J := Random(10) + 1;
        until (POLE1[I, J] > 0) and (POLE1[I, J] < 100);
        rx := I; ry := J;
        rx := rx * 14 + 16; ry := ry * 14 + 26;
        qx := rx; qy := ry;
        px := xx * 14 + 154; py := yy * 14 + 18;
        d := Round((px - rx) * (185. - ry) / ((370. - ry) - py)) + rx;
        e := 185;
        z := 0;
        for k := 0 to 4 - 1 do begin
          for I := 1 to 5 do begin
            SOUND(ISOU * (4 - k) * (Random(100) + 100)); DELAY(k + 1);
            NOSOUND; DELAY(I div 2 + k);
          end;
          Missile(Random(2) + 9, (rx + 2) + (k div 3) + Random(2), (ry + 3) + (k div 3) + Random(2), 1);
        end;
        f := Round((Abs(e - ry) + d - rx) * 0.03) + 1;
        r1 := (d - rx) / f; r2 := (e - ry) / f;
        z := 1;
        for k := 1 to f - 1 do begin
          SOUND(ISOU * (200 - TIME * 1));
          inc(TIME);
          Missile(22, Round(k * r1) + rx, Round(k * r2) + ry + 3, 11);
        end;
        for k := 0 to 2 - 1 do begin
          SOUND(ISOU * (200 - TIME * 1));
          inc(TIME);
          Missile(24, d, e + 5, 11);
        end;
        f := Round((Abs(py - e) + px - d) * 0.03) + 1;
        r1 := (px - d) / f; r2 := (py - e) / f;
        for k := 1 to f do begin
          SOUND(ISOU * (200 - TIME * 1));
          inc(TIME);
          Missile(23, Round(k * r1) + d, Round(k * r2) + e + 3, 11);
        end;
        for I := 1 to 10 do begin
          SOUND(ISOU * (Random(2000) + 1000)); DELAY(1); NOSOUND;
          DELAY(I div 4 + 1);
        end;
        if POLE2[xx, yy] > 0 then begin (*hit*)
          if POLE2[xx, yy] < 100 then begin
            inc(SCORE1);
            dec(POINT2);
            I := POLE2[xx, yy];
            POLE2[xx, yy] := POLE2[xx, yy] + 100;
            with SHIP[I] do begin
              dec(CUR);
              if CUR = 0 then begin (*destroyed*)
                if ORT = 0 then begin
                  X := XSHIP * 14 + 151;
                  Y := YSHIP * 14 + 13;
                  P := TIP + 44;
                end else begin
                  X := XSHIP * 14 + 152;
                  Y := YSHIP * 14 + 9;
                  P := TIP + 40;
                end;
                BADDRAW(PIC[P]^, SCRBUFF, X, Y, 1);
              end;
            end;
            for k := 0 to 4 - 1 do begin
              for I := 1 to 10 do begin
                SOUND(ISOU * (4 - k) * (Random(200) + 100)); DELAY(1);
                NOSOUND; DELAY(I div 2 + 1);
              end;
              Missile(26, px + 2, py - 7, 11);
            end;
          end;
        end else begin (*miss*)
          for k := 0 to 3 - 1 do Missile(25, px + 2, py - 7, 11);
          for k := 0 to 4 - 1 do Missile(19, xx * 14 + 159, yy * 14 + 22, 11);
          BADDRAW(PIC[19]^, SCRBUFF, xx * 14 + 159, yy * 14 + 22, 11);
          HOD := 2;	
        end;
        for I := 1 to 20 do begin
          SOUND(ISOU * (Random(1000) + 100)); DELAY(2); NOSOUND; DELAY(I div 4 + 1);
        end;
      end;
    end;
  until (SYM = #27) or (HOD = 2) or (POINT2 = 0);
  XMY := xx; YMY := yy;
end;

(*Computer's move*)
procedure HOD2;
var
  pp:integer;
  d, e, xx, yy:integer;
  f:integer;
  z:integer; qx, qy, qz:integer;
  k:integer; rx, ry, px, py:integer;
  r1, r2:real;

  procedure Missile(index:integer;b,c,d:integer);
  begin
    Port[$3CE] := 5; Port[$3CF] := 1;
    Move(SCRBUFF, SCRMAIN, 8000);
    DRDR;
    BADDRAW(PIC[index]^, SCRMAIN, b, c, d);
    if z > 0 then begin
      inc(z);
      qx := qx - 2;
      if (z mod 5) = 0 then qy := qy - 1;
      if z > 15 then qz := 21 else qz := 20;
      if z > 28 then z := 0;
      BADDRAW(PIC[qz]^, SCRMAIN, qx + 3, qy - 4, 0);
    end;
    if (TIME mod 10) < 5 then STR1 := 'ah-h!' else STR1 := 'Oh-h!';
    MYTEXT(STR1, Random(3) + 6, Random(2) + 2, 1, 40, Random(2) + 14, Random(2) + 14, SCRMAIN);
    Port[$3CE] := 5; Port[$3CF] := 1;
    Move(SCRMAIN, SCR, 8000);
  end;


begin
  repeat
    z := 0; TIME := 0;
    if KEYPRESSED then begin SYM := READKEY;
      if SYM = #0 then begin SYM := READKEY;
        if SYM = #$3B then ISOU := 1 - ISOU;
      end;
    end;
    if CASEPC = 0 then
      repeat (*initial shot*)
        xx := Random(10) + 1; yy := Random(10) + 1;
      until POLE11[xx, yy] = 0
    else repeat (*ship shot*)
        I := POLE1[XPC, YPC] mod 100;
        if SHIP[I].ORT = 0 then begin (*what a cheater! ai always know where to hit once ship is discovered*)
          xx := SHIP[I].XSHIP + Random(SHIP[I].TIP); yy := SHIP[I].YSHIP;
        end else begin
          yy := SHIP[I].YSHIP + Random(SHIP[I].TIP); xx := SHIP[I].XSHIP;
        end;
      until POLE11[xx, yy] = 0;
    POLE11[xx, yy] := 1;
    rx := 21 * 14 + 0; ry := 1 * 14 + 6;
    qx := rx; qy := ry;
    px := xx * 14 - 3; py := yy * 14 + 18;
    d := Round((px - rx) * (185. - ry) / ((370. - ry) - py)) + rx;
    e := 185; z := 0;
    for k := 0 to 4 - 1 do begin
      for I := 1 to 6 - 1 do begin
        SOUND(ISOU * (4 - k) * (Random(100) + 100)); DELAY(k + 1);
        NOSOUND; DELAY(I div 2 + k);
      end;
      Missile(Random(2) + 9, (rx - 2) - (k div 3) - Random(2), (ry + 3) + (k div 3) + Random(2), 1);
    end;
    f := Round((Abs(e - ry) + Abs(d - rx)) * 0.03) + 1;
    r1 := (d - rx) / f; r2 := (e - ry) / f;
    z := 1;
    for k := 1 to f - 1 do begin
      SOUND(ISOU * (400 - TIME * 4));
      inc(TIME);
      Missile(34, Round(k * r1) + rx, Round(k * r2) + ry - 5, 11);
    end;
    for k := 0 to 2 - 1 do begin
      SOUND(ISOU * (400 - TIME * 4)); inc(TIME);
      Missile(36, d + 2, e + 3, 11);
    end;
    f := Round((Abs(py - e) + Abs(px - d)) * 0.03) + 1;
    r1 := (px - d) / f; r2 := (py - e) / f;
    for k := 1 to f do begin
      SOUND(ISOU * (400 - TIME * 4));
      inc(TIME);
      Missile(35, Round(k * r1) + d + 4, Round(k * r2) + e + 1, 11);
    end;
    for I := 1 to 10 do begin
      SOUND(ISOU * (Random(2000) + 1000)); DELAY(1); NOSOUND;
      DELAY(I div 4 + 1);
    end;
    if POLE1[xx, yy] > 0 then begin (*hit*)
      CASEPC := 1; XPC := xx; YPC := yy;
      if POLE1[xx, yy] < 100 then begin
        inc(SCORE2);
        dec(POINT1);
        I := POLE1[xx, yy];
        POLE1[xx, yy] := POLE1[xx, yy] + 100;
        with SHIP[I] do begin (*mark surrounding cells*)
          POLE11[xx - 1, yy - 1] := 1;
          POLE11[xx + 1, yy - 1] := 1;
          POLE11[xx - 1, yy + 1] := 1;
          POLE11[xx + 1, yy + 1] := 1;
          dec(CUR);
          if CUR = 0 then begin (*destroyed*)
            CASEPC := 0;
            if (ORT = 0) or (TIP = 1) then begin
              POLE11[XSHIP - 1, YSHIP] := 1;
              POLE11[XSHIP + TIP, YSHIP] := 1;
            end;
            if (ORT = 1) or (TIP = 1) then begin
              POLE11[XSHIP, YSHIP - 1] := 1;
              POLE11[XSHIP, YSHIP + TIP] := 1;
            end;
          end;
        end;
        for k := 0 to 4 - 1 do begin
          for I := 1 to 10 do begin
            SOUND(ISOU * (4 - k) * (Random(200) + 100)); DELAY(1);
            NOSOUND; DELAY(I div 2 + 1);
          end;
          Missile(33, px + 2, py - 7, 11);
        end;
      end;
    end else begin (*miss*)
      for k := 0 to 3 - 1 do Missile(32, px + 2, py - 7, 11);
      for k := 0 to 4 - 1 do Missile(19, xx * 14 + 1, yy * 14 + 22, 11);
      BADDRAW(PIC[19]^, SCRBUFF, xx * 14 + 1, yy * 14 + 22, 11);
      for I := 1 to 20 do begin
        SOUND(ISOU * (Random(1000) + 100)); DELAY(2); NOSOUND; DELAY(I div 4 + 1);
      end;
      DRAWSHIP1;
      HOD := 1;
    end;
    XPC := xx; YPC := yy;
  until (SYM = #27) or (HOD = 1) or (POINT1 = 0);
end;

(*Play game loop*)
procedure PLAY;
begin
  XMY := 5; YMY := 5; XPC := 1; YPC := 1; CASEPC := 0;
  repeat
    if HOD = 1 then HOD1 else HOD2;
  until (SYM = #27) or (POINT1 = 0) or (POINT2 = 0);
end;
(*Place player's ships*)
procedure RND;
var
  good:integer;
  rz, rx, ry:integer; x, y, o:integer; sh, j:integer; cx, cy, pt, dx, dy:integer;

  procedure Help;
  var
    i:integer;
  begin
    BADDRAW(PIC[28]^, SCRBUFF, 0, 0, 16);
    BADDRAW(PIC[30]^, SCRBUFF, 212, 30, 3);
    i := 10 - 1;
    while (SHIP[i].CUR = 0) and (i > 1) do begin
      BADDRAW(PIC[SHIP[i + 1].TIP + 4]^, SCRBUFF, 2, 160 - i * 16, 1);
      dec(i);
    end;
    STR1 := 'PLACE SHIPS INTO SEA:';
    MYTEXT(STR1, 47, 3, 1, 40, 8, 8, SCRBUFF);
    MYTEXT(STR1, 46, 2, 1, 40, 15, 15, SCRBUFF);
    STR1 := 'USE ARROWS KEYS FOR MOVE';
    MYTEXT(STR1, 31, 173, 1, 40, 8, 8, SCRBUFF);
    MYTEXT(STR1, 30, 172, 1, 40, 15, 15, SCRBUFF);
    STR1 := 'USE INS FOR ROTATE';
    MYTEXT(STR1, 61, 182, 1, 40, 8, 8, SCRBUFF);
    MYTEXT(STR1, 60, 181, 1, 40, 15, 15, SCRBUFF);
    STR1 := 'PRESS ENTER WHEN SHIP IN PLACE';
    MYTEXT(STR1, 3, 191, 1, 40, 8, 8, SCRBUFF);
    MYTEXT(STR1, 2, 190, 1, 40, 15, 15, SCRBUFF);
  end;


begin
  POINT1 := 20;
  Help;
  SMENA;

  for sh := 1 to 10 do begin
    SHIP[sh].CUR := SHIP[sh].TIP;
    x := 1; y := 1; o := 1; good := 0;
    TIME := 0;
    repeat
      inc(TIME);
      Port[$3CE] := 5; Port[$3CF] := 1;
      Move(SCRBUFF, SCRMAIN, 8000);
      BADDRAW(PIC[Random(3) + 53]^, SCRMAIN, 20, 2, 3);
      REGS.ax := 3; INTR($33, REGS);
      if o = 0 then begin
        rx := x * 14 + 48;
        ry := y * 14 + 5;
        rz := SHIP[sh].TIP + 4;
      end else begin
        rx := x * 14 + 49;
        ry := y * 14 + 1;
        rz := SHIP[sh].TIP;
      end;
      if (TIME mod 5) < 4 then begin
        case SHIP[sh].TIP of
          1: STR1 := 'TORPEDO-BOAT';
          2: STR1 := 'DESTROYER';
          3: STR1 := 'CRUISER';
          4: STR1 := 'BATTLE-SHIP';
        end;
        MYTEXT(STR1, 221, 3, 1, 40, 8, 8, SCRMAIN);
        MYTEXT(STR1, 220, 2, 1, 40, 15, 15, SCRMAIN);
        BADDRAW(PIC[rz]^, SCRMAIN, rx, ry, 1);
      end;

      Port[$3CE] := 5; Port[$3CF] := 1; Move(SCRMAIN, SCR, 8000);
      if KEYPRESSED then begin
        for I := 1 to 20 do SOUND((I * I * 4 + 20) * ISOU);
        NOSOUND;
        SYM := READKEY;
        if SYM = #0 then begin
          SYM := READKEY;
          if SYM = #$48 then dec(y);
          if SYM = #$50 then inc(y);
          if SYM = #$4B then dec(x);
          if SYM = #$4D then inc(x);
          if SYM = #$3B then ISOU := 1 - ISOU;
          if SYM in [#$51, #$52] then o := 1 - o;
          if x < 1 then x := 10; if x > 10 then x := 1;
          if y < 1 then y := 10; if y > 10 then y := 1;
        end;
        if SYM = #27 then EXITING;
        if SYM = #13 then begin
          pt := SHIP[sh].TIP;
          dx := 0; dy := 0;
          if o > 0 then dy := 1 else dx := 1;
          good := 1; (*Check if ship fits there*)
          cx := x; cy := y;
          for j := 0 to pt - 1 do begin (*Is it in map's bounds and not over occupied cells?*)
            if (cx < 11) and (cy < 11) and (POLE1[cx, cy] = 0) then 
              begin {ok} end else good := 0;
            cx := cx + dx; cy := cy + dy;
          end;
          if good > 0 then begin (*Mark surrounding cells as occupied*)
            if o > 0 then
              for j := -1 to pt do begin
                cy := y + j;
                if ((x - 1) < 11) and (cy < 11) then POLE1[x - 1, cy] := -1;
                if (x < 11) and (cy < 11) then POLE1[x, cy] := -1;
                if ((x + 1) < 11) and (cy < 11) then POLE1[x + 1, cy] := -1;
              end
            else for j := -1 to pt do begin
                cx := x + j;
                if (cx < 11) and ((y - 1) < 11) then POLE1[cx, y - 1] := -1;
                if (cx < 11) and (y < 11) then POLE1[cx, y] := -1;
                if (cx < 11) and ((y + 1) < 11) then POLE1[cx, y + 1] := -1;
            end;
            (*Mark ship's cells*)
            cx := x; cy := y;
            for j := 0 to pt - 1 do begin
              POLE1[cx, cy] := sh;
              cx := cx + dx; cy := cy + dy;
            end;


            for j := 1 to 20 do begin
              SOUND(ISOU * (340 - j * 10)); DELAY(j div 6 + 1); NOSOUND; DELAY(j + 2);
            end;
          end else
            for j := 1 to 20 do begin
              SOUND(ISOU * (340 + j * 40)); DELAY(4); NOSOUND; DELAY(4);
            end;
        end;
        NOSOUND;
      end;
    until good = 1;
    Help;
    SHIP[sh].ORT := o;
    SHIP[sh].XSHIP := x;
    SHIP[sh].YSHIP := y;
    for I := 1 to 10 do if SHIP[I].CUR > 0 then begin
      if SHIP[I].ORT = 0 then begin
        rx := SHIP[I].XSHIP * 14 + 48;
        ry := SHIP[I].YSHIP * 14 + 5;
        rz := SHIP[I].TIP + 4;
      end else begin
        rx := SHIP[I].XSHIP * 14 + 49;
        ry := SHIP[I].YSHIP * 14 + 1;
        rz := SHIP[I].TIP;
      end;
      BADDRAW(PIC[rz]^, SCRBUFF, rx, ry, 1);
    end;
  end;
end;
(*Place enemy's ships*)
procedure RND2;
var
  good:integer;
  rz, rx, ry:integer; x, y, o:integer; i, j:integer; cx, cy, pt, dx, dy:integer;
begin



  POINT2 := 20;
  for i := 11 to 20 do begin
    SHIP[i].CUR := SHIP[i].TIP;
    repeat



      (*Pick a random start point and orientation*)
      x := Random(10) + 1;
      y := Random(10) + 1;
      o := Random(2);
      pt := SHIP[i].TIP; (*Ship length and heading*)
      dx := 0; dy := 0;
      if o > 0 then dy := 1 else dx := 1;
      good := 1; (*Check if ship fits there*)
      cx := x; cy := y;
      for j := 0 to pt - 1 do begin (*Is it in map's bounds and not over occupied cells?*)
        if (cx < 11) and (cy < 11) and (POLE2[cx, cy] = 0) then {ok} else good := 0;
        cx := cx + dx; cy := cy + dy;
      end;
    until good = 1;
    if o > 0 then (*Mark surrounding cells as occupied*)
      for j := -1 to pt do begin
        cy := y + j;
        if ((x - 1) < 11) and (cy < 11) then POLE2[x - 1, cy] := -1;
        if (x < 11) and (cy < 11) then POLE2[x, cy] := -1;
        if ((x + 1) < 11) and (cy < 11) then POLE2[x + 1, cy] := -1;
      end
    else for j := -1 to pt do begin
        cx := x + j;
        if (cx < 11) and ((y - 1) < 11) then POLE2[cx, y - 1] := -1;
        if (cx < 11) and (y < 11) then POLE2[cx, y] := -1;
        if (cx < 11) and ((y + 1) < 11) then POLE2[cx, y + 1] := -1;
    end;
    cx := x; cy := y; (*Mark ship's cells*)
    for j := 0 to pt - 1 do begin
      POLE2[cx, cy] := i;
      cx := cx + dx; cy := cy + dy;
    end;
    SHIP[i].ORT := o;
    SHIP[i].XSHIP := x;
    SHIP[i].YSHIP := y;
  end;
end;
(*Show rankings*)
procedure DRAWHELLOY;
var
  c:integer; top:array[1..6] of integer;
begin
  Port[$3CE] := 5; Port[$3CF] := 2; Port[$3CE] := 8; Port[$3CF] := $FF;
  FillChar(SCRBUFF[0], 8000, 3); FillChar(SCRMAIN[0], 8000, 3);
  BADDRAW(PIC[30]^, SCRBUFF, 214, 30, 3);
  STR1 := 'SEA BATTLE DATABASE';
  MYTEXT2(STR1, 1, 2, 2, 0, 0, SCRBUFF);
  MYTEXT2(STR1, 1, 1, 2, 9, 9, SCRBUFF);
  if MYNOMER = 0 then begin
    MYNOMER := NUMREC + 1;
    NUMREC := NUMREC + 1;
    RECOR[NUMREC].NAM := NAME;
    RECOR[NUMREC].GAME := 1;
    RECOR[NUMREC].WIN := 0;
    RECOR[NUMREC].RECS := 99;
    RECOR[NUMREC].CONTROL := 0;
  end;
  STR1 := 'Current CARD of Mr.' + NAME;
  MYTEXT(STR1, 7, 21, 2, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 6, 20, 2, 40, 13, 13, SCRBUFF);
  STR1 := 'Games:';
  MYTEXT(STR1, 7, 41, 2, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 6, 40, 2, 40, 9, 9, SCRBUFF);
  Str(RECOR[MYNOMER].GAME, STR1);
  MYTEXT2(STR1, 9, 41, 2, 1, 1, SCRBUFF);
  MYTEXT2(STR1, 9, 40, 2, 14, 14, SCRBUFF);
  STR1 := 'Wins: ';
  MYTEXT(STR1, 15, 59, 2, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 14, 58, 2, 40, 9, 9, SCRBUFF);
  Str(RECOR[MYNOMER].WIN, STR1);
  MYTEXT2(STR1, 9, 59, 2, 1, 1, SCRBUFF);
  MYTEXT2(STR1, 9, 58, 2, 14, 14, SCRBUFF);
  STR1 := 'Fires:';
  MYTEXT(STR1, 7, 77, 2, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 6, 76, 2, 40, 9, 9, SCRBUFF);
  Str(RECOR[MYNOMER].RECS, STR1);
  MYTEXT2(STR1, 9, 77, 2, 1, 1, SCRBUFF);
  MYTEXT2(STR1, 9, 76, 2, 14, 14, SCRBUFF);
  STR1 := 'BEST RESULT IN';
  MYTEXT(STR1, 111, 77, 1, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 110, 76, 1, 40, 15, 15, SCRBUFF);
  Str(RECOR[MYNOMER].RECS, STR1);
  STR1 := 'THE ONE GAME';
  MYTEXT(STR1, 115, 87, 1, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 114, 86, 1, 40, 15, 15, SCRBUFF);
  STR1 := '6 BEST          6 BEST';
  MYTEXT(STR1, 27, 111, 1, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 26, 110, 1, 40, 15, 15, SCRBUFF);
  STR1 := 'CAPTAIN         RESULTS';
  MYTEXT(STR1, 23, 120, 1, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 22, 119, 1, 40, 15, 15, SCRBUFF);
  STR1 := 'NAME   WINS   NAME    FIRES';
  MYTEXT(STR1, 13, 133, 1, 40, 0, 0, SCRBUFF);
  MYTEXT(STR1, 12, 132, 1, 40, 15, 15, SCRBUFF);

  for J := 1 to 6 do top[J] := 1;
  for J := 1 to NUMREC do RECOR[J].CONTROL := 0;

  for K := 1 to 6 do begin
    J := 1;
    while RECOR[J].CONTROL = 1 do inc(J);
    for I := 1 to NUMREC do if RECOR[I].CONTROL = 0 then
      if RECOR[I].WIN > RECOR[J].WIN then J := I;
    RECOR[J].CONTROL := 1;
    top[K] := J;
  end;

  for J := 1 to 6 do begin
    I := top[J];
    STR1 := RECOR[I].NAM;
    if STR1 = NAME then c := 15 else c := 14;
    MYTEXT(STR1, 2, J * 9 + 135, 1, 40, 1, 1, SCRBUFF);
    MYTEXT(STR1, 1, J * 9 + 134, 1, 40, c, c, SCRBUFF);
    Str(RECOR[I].WIN:3, STR1);
    MYTEXT(STR1, 75, J * 9 + 135, 1, 40, 1, 1, SCRBUFF);
    MYTEXT(STR1, 74, J * 9 + 134, 1, 40, c, c, SCRBUFF);
  end;

  for J := 1 to 6 do top[J] := 1;
  for J := 1 to NUMREC do RECOR[J].CONTROL := 0;

  for K := 1 to 6 do begin
    J := 1;
    while RECOR[J].CONTROL = 1 do inc(J);
    for I := 1 to NUMREC do if RECOR[I].CONTROL = 0 then
      if RECOR[I].RECS < RECOR[J].RECS then J := I;
    RECOR[J].CONTROL := 1;
    top[K] := J;
  end;

  for J := 1 to 6 do begin
    I := top[J];
    STR1 := RECOR[I].NAM;
    if STR1 = NAME then c := 15 else c := 14;
    MYTEXT(STR1, 122, J * 9 + 135, 1, 40, 1, 1, SCRBUFF);
    MYTEXT(STR1, 121, J * 9 + 134, 1, 40, c, c, SCRBUFF);
    Str(RECOR[I].RECS:2, STR1);
    MYTEXT(STR1, 215, J * 9 + 135, 1, 40, 1, 1, SCRBUFF);
    MYTEXT(STR1, 214, J * 9 + 134, 1, 40, c, c, SCRBUFF);
  end;
  SMENA;
  SYM := READKEY;
end;

procedure GLOBALEXIT(a:integer);
begin
  Port[$3CE] := 5; Port[$3CF] := 2; Port[$3CE] := 8; Port[$3CF] := $FF;
  FillChar(SCRBUFF[0], 8000, 3); FillChar(SCRMAIN[0], 8000, 3);
  BADDRAW(PIC[30]^, SCRBUFF, 214, 30, 3);
  STR1 := 'THE BATTLE ON';
  MYTEXT2(STR1, 1, 62, 2, 0, 0, SCRBUFF);
  MYTEXT2(STR1, 1, 61, 2, 9, 9, SCRBUFF);
  STR1 := 'THE BLACK SEA';
  MYTEXT2(STR1, 1, 81, 2, 0, 0, SCRBUFF);
  MYTEXT2(STR1, 1, 80, 2, 9, 9, SCRBUFF);
  STR1 := '(C) by BADY';
  MYTEXT(STR1, 68, 101, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 68, 100, 1, 40, 9, 9, SCRBUFF);
  STR1 := 'JUNE 1992';
  MYTEXT(STR1, 76, 111, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 76, 110, 1, 40, 9, 9, SCRBUFF);
  STR1 := 'MADE IN RUSSIA';
  MYTEXT(STR1, 57, 181, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 57, 180, 1, 40, 9, 9, SCRBUFF);
  STR1 := 'BY BASHUROV V.(BADY)';
  MYTEXT(STR1, 33, 191, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 33, 190, 1, 40, 9, 9, SCRBUFF);
  SMENA;
  DELAY(500);
  BADDRAW(PIC[27]^, SCR, 214, 30, 16);
  DELAY(200);
  BADDRAW(PIC[30]^, SCR, 214, 30, 16);
  DELAY(200);
  SYM := READKEY;
end;
(*Battle map*)
procedure DRAWMAP;
const
  mapx:array[1..7] of integer = (72,103,142,177,218,245,269);
  mapy:array[1..7] of integer = (40, 43, 76, 60, 68, 95,127);
var
  j:integer;
begin
  BADDRAW(PIC[49]^, SCRBUFF, 0, 0, 16);
  STR1 := 'BLACK SEA';
  MYTEXT(STR1, 100, 122, 2, 40, 0, 0, SCRBUFF);
  STR1 := 'ODESSA';
  MYTEXT(STR1, 22, 65, 1, 40, 0, 0, SCRBUFF);
  STR1 := 'NIKOLAEV';
  MYTEXT(STR1, 92, 72, 1, 40, 0, 0, SCRBUFF);
  STR1 := 'SEVASTOPOLE';
  MYTEXT(STR1, 100, 103, 1, 40, 0, 0, SCRBUFF);
  STR1 := 'KERTCH';
  MYTEXT(STR1, 160, 88, 1, 40, 0, 0, SCRBUFF);
  STR1 := 'NOVOROSSIYSK';
  MYTEXT(STR1, 220, 86, 1, 40, 0, 0, SCRBUFF);
  STR1 := 'SOTCHY';
  MYTEXT(STR1, 215, 124, 1, 40, 0, 0, SCRBUFF);
  STR1 := 'BATUM';
  MYTEXT(STR1, 231, 155, 1, 40, 0, 0, SCRBUFF);
  STR1 := 'Ukraine';
  MYTEXT2(STR1, 2, 15, 2, 0, 0, SCRBUFF);
  STR1 := 'RUSSIA';
  MYTEXT2(STR1, 26, 35, 2, 0, 0, SCRBUFF);
  SMENA;
  repeat
    Port[$3CE] := 5; Port[$3CF] := 1;
    Move(SCRBUFF, SCRMAIN, 8000);
    for I := 1 to 7 do
      case ZACH[I] of
        0: BADDRAW(PIC[Random(2) * 2 + 29]^, SCRMAIN, mapx[I] - 13, mapy[I] + 3, 3);
        1: BADDRAW(PIC[Random(3) + 50]^, SCRMAIN, mapx[I], mapy[I], 3);
        2: BADDRAW(PIC[Random(3) + 53]^, SCRMAIN, mapx[I] - 20, mapy[I], 3);
      end;
    Port[$3CE] := 5; Port[$3CF] := 1;
    Move(SCRMAIN, SCR, 8000);
  until KEYPRESSED;
  SYM := READKEY;
  if CENTER = 0 then GLOBALEXIT(2);
  if CENTER = 8 then GLOBALEXIT(1);
end;



begin
  Randomize;
  ISOU := 1;
  SYM := #7;
  for I := 1 to 3 do ZACH[I] := 1;
  for I := 4 to 7 do ZACH[I] := 2;
  ZACH[4] := 0;
  CENTER := 4;
  READREC;
  READMY;
  INITGR;
  I := 0;
  SCORE1 := 0;
  SCORE2 := 0;
  STEP1 := 0;
  Port[$3CE] := 5; Port[$3CF] := 2; Port[$3CE] := 8; Port[$3CF] := $FF;
  FillChar(SCRBUFF[0], 8000, 3); FillChar(SCRMAIN[0], 8000, 3);
  BADDRAW(PIC[30]^, SCRBUFF, 214, 30, 3);
  STR1 := 'THE BATTLE ON';
  MYTEXT2(STR1, 1, 62, 2, 0, 0, SCRBUFF);
  MYTEXT2(STR1, 1, 61, 2, 9, 9, SCRBUFF);
  STR1 := 'THE BLACK SEA';
  MYTEXT2(STR1, 1, 81, 2, 0, 0, SCRBUFF);
  MYTEXT2(STR1, 1, 80, 2, 9, 9, SCRBUFF);
  STR1 := '(C) by BADY';
  MYTEXT(STR1, 68, 101, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 68, 100, 1, 40, 9, 9, SCRBUFF);
  STR1 := 'JUNE 1992';
  MYTEXT(STR1, 76, 111, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 76, 110, 1, 40, 9, 9, SCRBUFF);
  STR1 := 'MADE IN RUSSIA';
  MYTEXT(STR1, 57, 181, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 57, 180, 1, 40, 9, 9, SCRBUFF);
  STR1 := 'BY BASHUROV V.(BADY)';
  MYTEXT(STR1, 33, 191, 1, 40, 8, 8, SCRBUFF);
  MYTEXT(STR1, 33, 190, 1, 40, 9, 9, SCRBUFF);
  SMENA;
  DELAY(500);
  BADDRAW(PIC[27]^, SCR, 214, 30, 16);
  DELAY(200);
  BADDRAW(PIC[30]^, SCR, 214, 30, 16);
  DELAY(200);
  INPUTNAME;





  repeat
    DRAWHELLOY;
    DRAWMAP;

    I := 0;
    SCORE1 := 0;
    SCORE2 := 0;
    STEP1 := 0;
    Port[$3CE] := 5; Port[$3CF] := 1;
    for I := 0 to 12 - 1 do for J := 0 to 12 - 1 do begin
      POLE11[I, J] := 1; POLE22[I, J] := 1;
    end;
    for I := 1 to 10 do for J := 1 to 10 do begin
      POLE1[I, J] := 0; POLE2[I, J] := 0;
      POLE11[I, J] := 0; POLE22[I, J] := 0;
    end;

    for I := 1 to 20 do SHIP[I].ORT := 0;
    for I := 1 to 20 do SHIP[I].CUR := 0;

    for I := 1 to 20 do
      case I of
              1, 11: SHIP[I].TIP := 4;
      2.. 3, 12..13: SHIP[I].TIP := 3;
      4.. 6, 14..16: SHIP[I].TIP := 2;
      7..10, 17..20: SHIP[I].TIP := 1;
      end;
    RND;
    RND2;
    BADDRAW(PIC[0]^, SCRBUFF, 0, 0, 16);
    BADDRAW(PIC[11]^, SCRBUFF, 294, 6, 1);

    DRAWSHIP1;


    SMENA;
    TIME := 0; SYM := #7;
    STEP1 := 0;
    inc(RECOR[MYNOMER].GAME);
    HOD := 1;
    PLAY;
    NOSOUND;
    if SYM <> #27 then begin
      Port[$3CE] := 5; Port[$3CF] := 2; Port[$3CE] := 8; Port[$3CF] := $FF;
      FillChar(SCRBUFF[0], 8000, 3); FillChar(SCRMAIN[0], 8000, 3);
      BADDRAW(PIC[27]^, SCRBUFF, 212, 30, 3);
      STR1 := 'SEA';
      MYTEXT2(STR1, 4, 61, 2, 0, 0, SCRBUFF);
      MYTEXT2(STR1, 4, 60, 2, 9, 9, SCRBUFF);
      STR1 := 'BATTLE';
      MYTEXT2(STR1, 1, 82, 2, 0, 0, SCRBUFF);
      MYTEXT2(STR1, 1, 81, 2, 9, 9, SCRBUFF);
      STR1 := '(C) by BADY';
      MYTEXT(STR1, 10, 101, 1, 40, 8, 8, SCRBUFF);
      MYTEXT(STR1, 10, 100, 1, 40, 9, 9, SCRBUFF);
      STR1 := 'JUNE 1992';
      MYTEXT(STR1, 14, 111, 1, 40, 8, 8, SCRBUFF);
      MYTEXT(STR1, 14, 110, 1, 40, 9, 9, SCRBUFF);
      STR1 := 'MADE IN RUSSIA';
      MYTEXT(STR1, 7, 181, 1, 40, 8, 8, SCRBUFF);
      MYTEXT(STR1, 7, 180, 1, 40, 9, 9, SCRBUFF);
      STR1 := 'AUTHOR BASHUROV';
      MYTEXT(STR1, 3, 191, 1, 40, 8, 8, SCRBUFF);
      MYTEXT(STR1, 3, 190, 1, 40, 9, 9, SCRBUFF);
      if POINT2 = 0 then begin
        Str(STEP1, STR1);
        STR1 := 'Fires:' + STR1;
        MYTEXT2(STR1, 5, 22, 2, 15, 15, SCRBUFF);
        MYTEXT2(STR1, 5, 21, 2, 5, 5, SCRBUFF);
        inc(RECOR[MYNOMER].WIN);
        if RECOR[MYNOMER].RECS > STEP1 then
          RECOR[MYNOMER].RECS := STEP1;
        ZACH[CENTER] := 2;
        CENTER := CENTER - 1;
        if CENTER > 0 then ZACH[CENTER] := 0;
        STR1 := 'CONGRATULATIONS!';
        MYTEXT2(STR1, 3, 3, 2, 15, 15, SCRBUFF);
        MYTEXT2(STR1, 3, 2, 2, 12, 12, SCRBUFF);
        SMENA;
        SYM := READKEY;
        NOSOUND;
      end;
      if POINT1 = 0 then begin
        ZACH[CENTER] := 1;
        CENTER := CENTER + 1;
        if CENTER < 8 then ZACH[CENTER] := 0;
        STR1 := 'Oh! I AM SORRY...';
        MYTEXT2(STR1, 4, 3, 2, 15, 15, SCRBUFF);
        MYTEXT2(STR1, 4, 2, 2, 8, 8, SCRBUFF);
        SMENA;
        SYM := READKEY;
        NOSOUND;
      end;
    end;
  until SYM in [#27];
  EXITING;
end.
