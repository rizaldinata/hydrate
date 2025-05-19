% Silsilah Keluarga 
anak(anto, ita).
anak(anto, budi).
anak(anto, ida).
anak(wati, ita).
anak(wati, budi).
anak(wati, ida).
anak(deni, hadi).
anak(ita, hadi).
anak(budi, dina).
anak(ida, andi).
anak(ida, rita).
anak(rudi, andi).
anak(rudi, rita).

% Jenis kelamin
lakilaki(anto).
lakilaki(deni). 
lakilaki(budi). 
lakilaki(rudi). 
lakilaki(hadi). 
lakilaki(andi). 
perempuan(wati).
perempuan(ita).
perempuan(ida).
perempuan(dina).
perempuan(rita).

% Aturan Relasi Orang Tua 
% Keterangan: AN - Anak, OT adalah Orang Tua
ortu(AN, OT) :- anak(OT, AN).

% Aturan saudara laki-laki
% Keterangan: SL - Saudara Laki-laki, S - Saudara
saudaralaki(S, SL) :- 
    anak(OT, S), anak(OT, SL), lakilaki(SL), S \= SL.

% Aturan saudara perempuan
% Keterangan: SP - saudara perempuan, S - Saudara
saudaraperempuan(S, SP) :- 
    anak(OT, S), anak(OT, SP), perempuan(SP), S \= SP.

% Aturan Paman Bibi
% Keterangan: P - Paman, B - Bibi, AN - Anak, OT - Orang Tua
paman(AN, P) :- ortu(AN, OT), saudaralaki(OT, P).
bibi(AN, B) :- ortu(AN, OT), saudaraperempuan(OT, B).

% Aturan Kakek Nenek
% Keterangan: K - Kakek, N - Nenek, AN - Anak, OT - Orang Tua
kakek(AN, K) :- ortu(AN, OT), ortu(OT, K), lakilaki(K).
nenek(AN, N) :- ortu(AN, OT), ortu(OT, N), perempuan(N).