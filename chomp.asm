;complete chomp program
         page 0          ;suppress page headings in asw listing file
         
         cpu 4040       
         
;include 4004 register definitions            
include "reg4004.inc"         
            
; Conditional jumps that ASW recognizes:
; jcn t     jump if test=0
; jcn tn    jump if test=1
; jcn c     jump if cy=1
; jcn cn    jump if cy=0
; jcn z     jump if accumulator=0
; jcn zn    jump if accumulator!=0            

;--------------------------------------------------------------------------------------------------
;power on reset entry
;--------------------------------------------------------------------------------------------------
         org 0         
         
         nop
         jun 0005           ;skip interrupt
         jun inter          ;interrupt vector
         fim p4,80h
         src p4
         ldm 9
         wmp                ;set up 4265 mode
         jms clrf           ;clear switch flags
         fim p2,28h         ;set ms addr, count and ddrv count
loop2:   jms ladr           ;load address to display
loop1:   ein                ;enable interrupts
         jms ddrv           ;display driver
         fim p4,40h
         src p4
         rdr                ;read in switches
         din                ;disable interrupts
         rar                ;first flag to cy
         jcn t, skip        ;jump to chip 1 if test set
         jun 100h
skip:    jcn cn, entda      ;enter data
         rar                ;next flag to cy
         jcn cn, entad      ;enter address
         rar                ;next flag to cy
         jcn cn, dump       ;dump?
         rar                ;last flag to cy
         jcn c,loop1        ;run or back again
run:     jms clrf
         fim p4,80h
         src p4
         clb
         wr1                ;blank display
         wr2
         jun 200h           ;jump to user prog in chip 2
entda:   fim p4,00h
         src p4
         ld r4
         wmp                ;select program ram chip
         src p1             ;address byte
         ld r12
         wpm                ;write least sig nibble
         ld r14             ;to ram
         wpm                ;write most sig nibble
         jms clrf           ;clear switch flags
         jun count          ;bump address count
entad:   ld r13             ;put kbd in counter
         xch r3
         ld r12 
         xch r2 
         ld r14 
         xch r4             ;reload counter with 12 bit address
         jms clrf           ;clear switch flags
         jun loop2
dump:    fim p6,00h
         fim p4,00h
         src p4
         ld r4
         wmp                ;select ram chip
         src p1             ;address byte
         rpm                ;get ls nibble
         xch r12
         rpm                ;get ms nibble
         xch r14
         fim p5,00h         ;clear kbd count
         fim p4,50h
         src p4
         wrr                ;clear flags but not kbd
         jms loky           ;display dump byte
count:   isz r3,loop2
         isz r2,loop2
         isz r4,loop2
         jun loop2          ;address counter
inter:   sb1
         xch r6
         tcc                ;save ac and carry
         xch r7
         fim p1,40h
         src p1
         rdr                ;get prog/run switch
         ral                ;put in cy
         jcn c,promo        ;are we in prog mode?
         ld r7              ;user ir so restore status
         rar
         ld r6
         jun 203h           ;go to user ir
promo:   fim p2,80h         ;select 4265
         src p2
         rd0                ;get kbd bcd
         xch r15            ;put in kbd temp
         inc r11            ;bump table index
         inc r11
         ldm 8
         xch r10            ;ms table index nibble
         ld r15             ;put kbd in acc
         jin p5             ;branch via table
        org 082h
table:   jun first
         jun secon
         jun third
first:   xch r14            ;first kbd digit in r14
         jun term
secon:   xch r12            ;second to r12
         jun term
third:   xch r13            ;third in r13    
         fim p5,00h         ;clear kbd char count   
term:    jms loky           ;put new kbd digit in 4002  
         ld r7  
         rar                ;restore status     
         ld r6
         bbs     
clrf:    fim p4,50h         ;select rom o.p. port 5   
         src p4   
         wrr                ;clear switch flags     
         fim p5,00h         ;clear kbd registers    
         fim p6,00h     
         fim p7,00h     
         bbl 0h  
ladr:    fim p4,0ah         ;fetch 4002 src start add   
         ld r4    
         xch r1   
         jms hexl           ;convert to seven seg code  
         ld r2    
         xch r1   
         jms hexl           ;convert to seven seg code  
         ld r3
         xch r1   
         jms hexl           ;convert to seven seg code  
         bbl 0h  
ddrv:    src p3             ;display driver routine     
         rdm                ;low four from 4002     
         fim p4,80h   
         src p4             ;low four to 4265 port X    
         wr1     
         inc r7             ;bump nibble pointer    
         src p3   
         rdm                ;high four from 4002    
         src p4   
         wr2                ;low four to 4265 port Y    
         inc r7             ;bump nibble pointer    
         isz r5,dato        ;increment shift counter    
         ldm 0fh            ;fetch wrm code     
         wrm                ;bit set 4265 Z3 high   
         ldm 08h            ;preset shift counter   
         xch r5   
         jun pass    
dato:    ldm 0eh            ;fetch wrm code     
         wrm                ;bit set Z3 low     
pass:    fim p4,080h        ;slow down multiplex rate   
loop3:   isz r8,loop3     
         isz r9,loop3     
         bbl 0h  
loky:    fim p4,00h         ;set up address     
         ld r14  
         xch r1             ;get low four   
         jms hexl           ;convert to seven seg code
         ld r12  
         xch r1   
         jms hexl           ;convert to seven seg code  
         ld r13  
         xch r1   
         jms hexl           ;convert to seven seg code  
         bbl 0h  
hexl:    ldm 0fh            ;seven seg table lookup code 
         xch r0             ;table base in r0     
         fin p0             ;get seg code from table    
         src p4   
         ld r1              ;first four to 4002     
         wrm     
         inc r9             ;bump nibble pointer    
         src p4   
         ld r0              ;last four to 4002  
         wrm     
         inc r9             ;bump nibble pointer    
         bbl 0   

         org 0f0h  
         data 07eh          ;lookup table       
         data 00ch
         data 0b6h   
         data 09eh   
         data 0cch   
         data 0dah   
         data 0fah   
         data 00eh   
         data 0feh   
         data 0deh   
         data 0eeh   
         data 0f8h   
         data 072h   
         data 0bch   
         data 0f2h   
         data 0e2h   


