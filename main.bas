2000 rem *** "constants" ***
2010 di=59459:rem data direction reg.
2020 io=59471:rem i/o port
2030 de=10:rem 1/60secs.bit read delay
2500 rem *** variables ***
2510 o=0:rem output val.(hard-coded)
2520 by=0:rem current byte read
2530 c=0:rem current bit read index
2540 t=0:rem wait until this time
2550 bi=0:rem current bit read
2560 p=0:rem param.for sub routines
2570 ad=-1:rem where to store bytes
2580 le=0:rem count of payload bytes
2590 ca=-1:rem current store address
2600 la=-1:rem last store address
5000 rem *** main ***
5005 print"setting out val. to high.."
5010 gosub 7000:rem see val.of o
5020 print"enabling output.."
5030 poke di,(peek(di)or2)
5040 print"setting out val. to low.."
5050 gosub 7000
5060 gosub 7200:rem read a byte
5070 ad=by
5080 gosub 7200:rem read a byte
5090 ad=256*by+ad
5100 print"start address = ";
5110 print ad
5120 gosub 7200:rem read a byte
5130 le=by
5140 gosub 7200:rem read a byte
5150 le=256*by+le
5160 print"byte count = ";
5170 print le
5180 print"reading payload.."
5190 la=ad+le-1
5195 for ca=ad to la
5200 gosub 7200:rem read a byte
5210 poke ca,by
5220 next ca
5230 print"done."
6990 end
7000 rem *** toggle output ***
7010 o=1-o
7020 if o=0 then 7050
7030 poke io,(peek(io)or2)
7040 return
7050 poke io,(peek(io)and253)
7060 return
7100 rem *** wait 1/60 secs.in p ***
7110 t=ti+p
7120 if ti<t then 7120
7130 return
7200 rem *** read a byte into by ***
7210 by=0
7220 for c=0 to 7
7230 p=de:gosub 7100:rem wait delay
7240 bi=peek(io)and1
7250 by=by+bi*(2^c)
7260 gosub 7000:rem acknowledge
7270 next c
7280 return
