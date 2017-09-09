5010 poke59471,(peek(59471)or2)
5030 poke59459,(peek(59459)or2)
5045 o=0
5050 poke59459,(peek(59459)and253)
5052 by=0
5055 for c=0 to 7
5060 t=ti+10
5070 if ti<t then 5070
5080 bi=peek(59471)and1
5082 by=by+bi*(2^c)
5090 if o=1 then 5200
5100 poke59471,(peek(59471)or2)
5110 goto 5210
5200 poke59471,(peek(59471)and253)
5210 o=1-o
5220 next c
5230 print"byte = ";
5240 print by
