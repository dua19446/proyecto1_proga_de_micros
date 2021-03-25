; Archivo:     lab3.s
; Dispositivo: PIC16F887
; Autor:       Alejandro Duarte
; Compilador:  pic-as (v2.30), MPLABX V5.40
;
; Programa:    contador en el puerto A
; Hardware:    LEDS en el puerto A, DISPLAY de 7 segmentos en puertos C y D
;
; Creado: 2 MARZO, 2021
; Última modificación: , 2021

; Assembly source line config statements
    
PROCESSOR 16F887  ; Se elige el microprocesador a usar
#include <xc.inc> ; libreria para el procesador 

; configuratión word 1
  CONFIG  FOSC =  INTRC_NOCLKOUT  ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF             ; Watchdog Timer Enable bit (WDT enabled)
  CONFIG  PWRTE = OFF        ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF               ; Code Protection bit (Program memory code protection is enabled)
  CONFIG  CPD = OFF              ; Data Code Protection bit (Data memory code protection is enabled)
  
  CONFIG  BOREN = OFF          ; Brown Out Reset Selection bits (BOR enabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is enabled)
  CONFIG  FCMEN = OFF            ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; configuration word 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF            ; Flash Program Memory Self Write Enable bits (0000h to 0FFFh write protected, 1000h to 1FFFh may be modified by EECON control)

;-------------------------------varibles----------------------------------------  
  PSECT udata_bank0
  UNIDAD:    DS 1   ; variable que se usa en la division para guardar la unidad
  DECENA:    DS 1   ; variable que se usa en la division para guardar la decena
  RESIDUO:   DS 1   ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2:   DS 1   ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2:   DS 1   ; Se guarda el valor traducido por la tabla de la variable decena
  
  PSECT udata_shr ;common memory
  W_T:       DS 1 ; variable que de interrupcio para w
  STATUS_T:  DS 1 ; variable que de interrupcio que guarda STATUS
  SENAL:     DS 1 ; Se utiliza como indicador para el cambio de display
  
;Instrucciones de reset
PSECT resVect, class=code, abs, delta=2
;--------------vector reset----------------
ORG 00h        ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    GOTO main
   
PSECT intVect, class=CODE, ABS, DELTA=2
;------------------------VECTOR DE INTERRUPCION---------------------------------
ORG 04h
    PUSH:
       MOVWF W_T
       SWAPF STATUS, W
       MOVWF STATUS_T
       
    ISR:
      ;BTFSC RBIF ; confirma si hubo una interrucion en el puerto B
      ;CALL INC_DEC ; llama a la subrrutina de la interrupcion del contador binario
      BTFSC T0IF; verifica si se desbordo el timer0
      CALL INT_T0; llama a la subrrutina de interrupcion del tiemer 0
      
    POP: 
      SWAPF STATUS_T, W
      MOVWF STATUS
      SWAPF W_T, F
      SWAPF W_T, W
      RETFIE
      
PSECT code, delta=2, abs
ORG 100h    ; Posicion para el codigo
; se establece la tabla para traducir los numeros y que el numero correspondiente
; se marque en el display
TABLA:
    CLRF    PCLATH
    BSF     PCLATH, 0 
    ANDLW   0x0f
    ADDWF   PCL
    retlw   00111111B	; 0
    retlw   00000110B	; 1
    retlw   01011011B	; 2
    retlw   01001111B	; 3
    retlw   01100110B	; 4
    retlw   01101101B	; 5
    retlw   01111101B	; 6
    retlw   00000111B	; 7
    retlw   01111111B	; 8
    retlw   01101111B	; 9
    retlw   01110111B	; A
    retlw   01111100B	; b
    retlw   00111001B	; C
    retlw   01011110B	; d
    retlw   01111001B	; E
    retlw   01110001B	; F
    
main:
    BANKSEL ANSEL ; Entramos al banco donde esta el registro ANSEL
    CLRF ANSEL
    CLRF ANSELH  ; se establecen los pines como entras y salidas digitales
    
    BANKSEL TRISA ; Entramos al banco donde esta el TRISA
    BCF TRISA, 0 
    BCF TRISA, 1 
    BCF TRISA, 2
    BCF TRISA, 3
    BCF TRISA, 4
    BCF TRISA, 5 ; Se ponen los pines del puerto A como salidas
    
    BCF TRISC, 0  ; 
    BCF TRISC, 1
    BCF TRISC, 2
    BCF TRISC, 3
    BCF TRISC, 4
    BCF TRISC, 5
    BCF TRISC, 6
    BCF TRISC, 7  ; Se ponen los pines del puerto C como salida
    
    BCF TRISD,0
    BCF TRISD,1
    BCF TRISD,2
    BCF TRISD,3
    BCF TRISD,4 
    BCF TRISD,5
    BCF TRISD,6
    BCF TRISD,7 ; Se colocan los primeros 5 pines del puertoD como salida 
    
    BCF TRISE,0
    BCF TRISE,1
    BCF TRISE,3 ; Se colocan los pines del puerto C como salida 
    
   
    BSF TRISB,0
    BSF TRISB,1
    BSF TRISB,2 ; Se ponen los primeros 3 pines como entradas  
    BCF TRISB,5
    BCF TRISB,6
    BCF TRISB,7; Se ponen los tres tres ultimos pines como salida
    
 ; subrutinas de cofiguracion
    CALL PULL_UP
    CALL OSCILLATOR
    CALL CONF_IOC
    CALL CONF_INTCON ; Se llama a las diferentes subrrutinas de configuracion
    
    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC 
    CLRF PORTD ; Se limpian todos los puertos del pic
    CLRF PORTE
    BANKSEL PORTA 
    
loop:
;    CALL MOSTRAR_DIS
;    CALL DIVISION
    GOTO loop
    
PULL_UP:
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7 ; Se abilitan los pull-up internos del puerto B
    BCF T0CS ; Se establece que se usara oscilador interno 
    BCF PSA  ; el prescaler se asigna al timer 0
    BSF PS2
    BSF PS1
    BSF PS0  ; el prescaler es de 256   
    BANKSEL WPUB
    BSF WPUB,0
    BSF WPUB,1
    BSF WPUB,3
    BCF WPUB,3
    BCF WPUB,4
    BCF WPUB,5
    BCF WPUB,6
    BCF WPUB,7 ;Se estblece que pines del puerto B tendran activado el pull-up
    RETURN 
    
OSCILLATOR:
    BANKSEL OSCCON ; Se ingresa al banco donde esta el registro OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1   
    bcf	    IRCF0  ; Se configura el oscilador a una frecuencia de 250kHz 
    bsf	    SCS	  
    RETURN
    
CONF_IOC:   
    BANKSEL IOCB
    BSF IOCB, 0
    BSF IOCB, 1
    BSF IOCB, 2  ;Se activa el interrupt on change de los dos primeros pines del puerto B 
    RETURN
    
CONF_INTCON:
    BANKSEL INTCON
    BSF  GIE ; Se activan las interrupciones globales 
    BCF  RBIF ; Se colaca la bandera en 0 por precaucion
    BSF  RBIE ; Permite interrupciones en el puerto B
    BSF  T0IE ; Permite interrupion del timer 0
    BCF  T0IF ; limpia bandera de desbordamiento de timer 0
    RETURN
    
;MOSTRAR_DIS:
;    MOVF  DECENA, W
;    CALL  TABLA 
;    MOVWF DECENA2; Se guarda en la variable DECENA lo que contiene la variable DECENA2
;    MOVF  UNIDAD, W
;    CALL  TABLA 
;    MOVWF UNIDAD2; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
;    RETURN
;    
;DIVISION:
;    BANKSEL PORTA
;    CLRF  DECENA; Se limpia la variable CENTENA
;    MOVF  , 0
;    MOVWF RESIDUO ; pasa lo que hay en el puertoA a RESIDUO	    
;    MOVLW 10		    
;    SUBWF RESIDUO, 0 ; Se resta 100 lo que hay en RESIDUO y se queda en W	    
;    BTFSC STATUS, 0 ; Se asegura que se realizo la operacion 	    
;    INCF  DECENA ; nuemero de centenas que caben en el numero del puertoA	    
;    BTFSC STATUS, 0	    
;    MOVWF RESIDUO ; El resultado de la resta se guarda en RESIDUO	    
;    BTFSC STATUS, 0	    
;    GOTO  $-7	; Se repite por cada centena que pueda haber	    
;    CLRF  UNIDAD ;Se limpia la variable CENTENA
;    MOVLW 1		    
;    SUBWF RESIDUO, 0 ; Se resta 10 lo que hay en RESIDUO y se queda en W	    
;    BTFSC STATUS, 0 ; Se asegura que se realizo la operacion 
;    INCF  UNIDAD	; nuemero de decenas que caben en el numero del puertoA	    
;    BTFSC STATUS, 0	    
;    RETURN
;    GOTO $-6 ; Se resta el nuemro 1 cuanto se necesite para saber las unidades de lo que quedo de la resta anterior 
;    
    
;----------------------sub-rutinas de interrupcion------------------------------    

R_TIMER0:
    BANKSEL PORTA
    MOVLW  255
    MOVWF  TMR0; Se ingresa al registro TMR0 el numero desde donde empieza a contar
    BCF  T0IF ; Se pone en 0 el bit T0IF  
    RETURN
    

INT_T0:
    CALL R_TIMER0 ; llama a subrrutina para reiniciar el timer0
    CLRF PORTD 
    BTFSC SENAL, 0
    GOTO  DIS1
    BTFSC SENAL, 1
    GOTO  DIS2
    BTFSC SENAL, 2
    GOTO  DIS3
    BTFSC SENAL, 3
    GOTO  DIS4
    BTFSC SENAL, 4
    GOTO  DIS5
    BTFSC SENAL, 5
    GOTO  DIS6
    BTFSC SENAL, 6
    GOTO  DIS7
    
DIS0:
    BSF PORTD, 0 ; Se pone el valor de DIS en el puerto D y se activa su display respectivo
    GOTO NEXT_D0; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS1:
    BSF PORTD, 1 ; Se pone el valor de DIS+1 en el puerto D y se activa su display respectivo
    GOTO NEXT_D1 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS2:
    MOVLW 01011011B
    MOVWF PORTC
    BSF PORTD, 2 ; Se pone el valor de CENTENA2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D2 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS3:
    BSF PORTD, 3 ; Se pone el valor de DECENA2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D3 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS4:
    BSF PORTD, 4 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D4 ; Se utiliza para cambiar el valor de SENAL y cambiar de display

DIS5:
    BSF PORTD, 5 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D5 ; Se utiliza para cambiar el valor de SENAL y cambiar de display

DIS6:
    BSF PORTD, 6 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D6 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS7:
    BSF PORTD, 7 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D7 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
NEXT_D0:
    MOVLW 00000001B
    XORWF SENAL, F
    RETURN ; Se utiliza la operacion xor para activar el primer bit de SENAL
NEXT_D1:
    MOVLW 00000011B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el segundo bit de SENAL
NEXT_D2:
    MOVLW 00000110B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el tercer bit de SENAL
NEXT_D3:
    MOVLW 00001100B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el cuarto bit de SENAL
NEXT_D4:
    MOVLW 00011000B
    XORWF SENAL, F
    RETURN
NEXT_D5:
    MOVLW 00110000B
    XORWF SENAL, F
    RETURN
NEXT_D6:
    MOVLW 01100000B
    XORWF SENAL, F
    RETURN
NEXT_D7:
    CLRF SENAL; Se limpia la variable SENAL
    RETURN
    
END