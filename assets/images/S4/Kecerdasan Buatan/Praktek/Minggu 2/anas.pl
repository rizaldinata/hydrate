lulusan_sd(anas).
wni(anas).
kelahiran(anas, 1952).
pns(NAMA):-usia_daftar(NAMA, USIA), USIA < 35.
usia_daftar(NAMA, USIA):-kelahiran(NAMA, TAHUN), tahun_daftar(Y), USIA is Y-TAHUN.
pensiun(NAMA):-pns(NAMA), usia(NAMA, USIA), USIA > 60.
tahun_daftar(1985).
tahun(2005).
usia(NAMA, USIA):-kelahiran(NAMA, TAHUN), tahun(Y), USIA is Y-TAHUN.