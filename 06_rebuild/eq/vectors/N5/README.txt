cma_int.py vectors: N=5, seed=2, OSNR=20 dB, 10008 input symbols, 10004 outputs (first at k=4).
eq_in.txt       xr xi yr yi                    int8 Q3.5, one row per input symbol
eq_out_ref.txt  k yx_re yx_im yy_re yy_im       Q3.13, one row per output
eq_dbg_ref.txt  k e_x e_y gx_re gx_im gy_re gy_im   e Q4.12, g 23 frac bits
eq_taps_ref.txt k then taps AFTER the update at k: filters xx, xy, yx, yy;
                per filter tap 0..N-1 (0 = newest sample), each re im, Q2.22
