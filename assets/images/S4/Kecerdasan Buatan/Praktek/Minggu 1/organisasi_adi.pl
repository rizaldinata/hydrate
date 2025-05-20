% Aturan Organisasi Perusahaan
bawahanlangsung(adi, burhan).
bawahanlangsung(burhan, bahrun).
bawahanlangsung(burhan, bisrin).
bawahanlangsung(bahrun, fahri).
bawahanlangsung(bahrun, farah).
bawahanlangsung(bisrin, ferdi).

% Aturan Atasan Langsung
% Keterangan: ATS - Atasan, BW - Bawahan
atasanlangsung(BW, ATS):- bawahanlangsung(ATS, BW).

% Keterangan: AB - Anak Buah
% Anak Buah Langsung
anakbuah(ATS, AB):- atasanlangsung(AB, ATS). 

% Anak Buah Tidak Langsung Ke-1
anakbuah(ATS, AB):- 
    atasanlangsung(AB, ATL), atasanlangsung(ATL, ATS).

% Anak Buah Tidak Langsung Ke-2
anakbuah(ATS, AB):- 
    atasanlangsung(AB, ATL), atasanlangsung(ATL, ATLL), 
    atasanlangsung(ATLL, ATS). 