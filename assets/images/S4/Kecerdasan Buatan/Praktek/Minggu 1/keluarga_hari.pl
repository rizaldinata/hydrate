% Hubungan Keluarga dari Anak
anaklaki(hari, agus).
anaklaki(agus, budi).
anaklaki(ani, rudi).
anakperempuan(agus, ani).
anakperempuan(budi, ria).
anakperempuan(budi, ita).


% Aturan mencari anak dari orang tua
% Keterangan: A - Anak, OT - Parent
ortu(A, OT):- anaklaki(OT, A).
ortu(A, OT):- anakperempuan(OT, A).

% Aturan Mencari Turunan
% Keterangan: GP - Grandparent, TR - Turunan
turunan(GP, TR):- ortu(TR, GP). % Anak
turunan(GP, TR):- ortu(TR, P), ortu(P, GP). % Cucu
turunan(GP, TR):- ortu(TR, P), ortu(P, OT), ortu(OT, GP). % Cicit