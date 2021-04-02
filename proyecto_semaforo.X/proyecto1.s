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
  GLOBAL V1
  PSECT udata_bank0
  UNIDAD_V1:    DS 1   ; variable que se usa en la division para guardar la unidad
  DECENA_V1:    DS 1   ; variable que se usa en la division para guardar la decena
  RESIDUO_V1:   DS 1   ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_V1:   DS 1   ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_V1:   DS 1   ; Se guarda el valor traducido por la tabla de la variable decena
  
  UNIDAD_V2:    DS 1   ; variable que se usa en la division para guardar la unidad
  DECENA_V2:    DS 1   ; variable que se usa en la division para guardar la decena
  RESIDUO_V2:   DS 1   ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_V2:   DS 1   ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_V2:   DS 1   ; Se guarda el valor traducido por la tabla de la variable decena  
    
  UNIDAD_V3:    DS 1   ; variable que se usa en la division para guardar la unidad
  DECENA_V3:    DS 1   ; variable que se usa en la division para guardar la decena
  RESIDUO_V3:   DS 1   ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_V3:   DS 1   ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_V3:   DS 1   ; Se guarda el valor traducido por la tabla de la variable decena
  
  PSECT udata_shr ;common memory
  W_T:       DS 1 ; variable que de interrupcio para w
  STATUS_T:  DS 1 ; variable que de interrupcio que guarda STATUS
  SENAL:     DS 1 ; Se utiliza como indicador para el cambio de display
  Estado:    DS 1 ; Se utiliza como indicador para el cambio de estado
  V1:        DS 1
  V2:        DS 1
  V3:        DS 1  
  
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
      BTFSC RBIF ; confirma si hubo una interrucion en el puerto B
      CALL ESTADOS ; llama a la subrrutina de la interrupcion del contador binario
      BCF RBIF
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
    BCF TRISB,3
    BCF TRISB,4
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
    CALL LED_MODO
    CALL MOSTRAR_DIS
    CALL DIVISION
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
    BSF WPUB,2
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

LED_MODO:
    BTFSC Estado, 0
    GOTO  via1
    BTFSC Estado, 1
    GOTO  via2
    BTFSC Estado, 2
    GOTO  via3
    BTFSC Estado, 3
    GOTO  ACEP_CAN
    
normal:
    BSF PORTB, 3
    BCF PORTB, 4
    BCF PORTB, 5
    BCF PORTB, 6
    BCF PORTB, 7
    RETURN
    
via1:
    BCF PORTB, 3
    BSF PORTB, 4
    BCF PORTB, 5
    BCF PORTB, 6
    BCF PORTB, 7
    RETURN
     
via2:
    BCF PORTB, 3
    BCF PORTB, 4
    BSF PORTB, 5
    BCF PORTB, 6
    BCF PORTB, 7
    RETURN
    
via3:
    BCF PORTB, 3
    BCF PORTB, 4
    BCF PORTB, 5
    BSF PORTB, 6
    BCF PORTB, 7
    RETURN
    
ACEP_CAN:
    BCF PORTB, 3
    BCF PORTB, 4
    BCF PORTB, 5
    BCF PORTB, 6
    BSF PORTB, 7
    RETURN
    
MOSTRAR_DIS:
    MOVF  DECENA_V1, W
    CALL  TABLA 
    MOVWF DECENA2_V1; Se guarda en la variable DECENA lo que contiene la variable DECENA2
    MOVF  UNIDAD_V1, W
    CALL  TABLA 
    MOVWF UNIDAD2_V1; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
    
    MOVF  DECENA_V2, W
    CALL  TABLA 
    MOVWF DECENA2_V2; Se guarda en la variable DECENA lo que contiene la variable DECENA2
    MOVF  UNIDAD_V2, W
    CALL  TABLA 
    MOVWF UNIDAD2_V2; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
    
    MOVF  DECENA_V3, W
    CALL  TABLA 
    MOVWF DECENA2_V3; Se guarda en la variable DECENA lo que contiene la variable DECENA2
    MOVF  UNIDAD_V3, W
    CALL  TABLA 
    MOVWF UNIDAD2_V3; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
    RETURN
    
DIVISION:
    clrf DECENA_V1    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_V1
    clrf RESIDUO_V1
    movf V1, 0    ;Trasladamos valor en IncrementoT1 a resta 
    movwf RESIDUO_V1
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_V1, f    ;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_V1    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        ;Evitar que haya un overlap (00h - FFh)
    addwf RESIDUO_V1
    movf RESIDUO_V1, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_V1
    
    clrf DECENA_V2    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_V2
    clrf RESIDUO_V2
    movf V2, 0    ;Trasladamos valor en IncrementoT1 a resta 
    movwf RESIDUO_V2
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_V2, f    ;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_V2    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        ;Evitar que haya un overlap (00h - FFh)
    addwf RESIDUO_V2
    movf RESIDUO_V2, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_V2
    
    clrf DECENA_V3    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_V3
    clrf RESIDUO_V3
    movf V3, 0    ;Trasladamos valor en IncrementoT1 a resta 
    movwf RESIDUO_V3
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_V3, f    ;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_V3    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        ;Evitar que haya un overlap (00h - FFh)
    addwf RESIDUO_V3
    movf RESIDUO_V3, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_V3
    RETURN
    
    
;----------------------sub-rutinas de interrupcion------------------------------    

ESTADOS:
    BTFSC Estado, 0
    GOTO  VIA1
    BTFSC Estado, 1
    GOTO  VIA2
    BTFSC Estado, 2
    GOTO  VIA3
    BTFSC Estado, 3
    GOTO  ACEPTAR_CANCELAR
    
NORMAL:
    BTFSS PORTB, 0
    BSF   Estado,0
    RETURN
    
VIA1:
    BTFSS PORTB,1 ; verifica si el PB del primer pin del puerto b esta activado
    INCF  V1 ;incrementa la variable
    BTFSS PORTB,2 ; verifica si el PB del segundo pin del puerto b esta activado
    DECF  V1; decrementa la variable
    BTFSS PORTB,0
    BCF   Estado,0
    BTFSS PORTB, 0
    BSF   Estado,1
    RETURN
     
VIA2:
    BTFSS PORTB,1 ; verifica si el PB del primer pin del puerto b esta activado
    INCF  V2 ;incrementa la variable
    BTFSS PORTB,2 ; verifica si el PB del segundo pin del puerto b esta activado
    DECF  V2; decrementa la variable
    BTFSS PORTB,0
    BCF   Estado,1
    BTFSS PORTB, 0
    BSF   Estado,2
    RETURN
    
VIA3:
    BTFSS PORTB,1 ; verifica si el PB del primer pin del puerto b esta activado
    INCF  V3 ;incrementa la variable
    BTFSS PORTB,2 ; verifica si el PB del segundo pin del puerto b esta activado
    DECF  V3; decrementa la variable
    BTFSS PORTB,0
    BCF   Estado,2
    BTFSS PORTB,0
    BSF   Estado,3
    RETURN
    
ACEPTAR_CANCELAR:
    BTFSS PORTB,0
    CLRF  Estado
    RETURN
    

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
    BTFSC PORTB,3
    RETURN
    MOVF DECENA2_V3, W
    MOVWF PORTC
    BSF PORTD, 6 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D6 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS7:
    BTFSC PORTB,3
    RETURN
    MOVF UNIDAD2_V3, W
    MOVWF PORTC
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