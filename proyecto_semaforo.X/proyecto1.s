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
  UNIDAD_V1:  DS 1 ; variable que se usa en la division para guardar la unidad
  DECENA_V1:  DS 1 ; variable que se usa en la division para guardar la decena
  RESIDUO_V1: DS 1 ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_V1: DS 1 ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_V1: DS 1 ; Se guarda el valor traducido por la tabla de la variable decena
  
  UNIDAD_V2:  DS 1 ; variable que se usa en la division para guardar la unidad
  DECENA_V2:  DS 1 ; variable que se usa en la division para guardar la decena
  RESIDUO_V2: DS 1 ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_V2: DS 1 ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_V2: DS 1 ; Se guarda el valor traducido por la tabla de la variable decena  
    
  UNIDAD_V3:  DS 1 ; variable que se usa en la division para guardar la unidad
  DECENA_V3:  DS 1 ; variable que se usa en la division para guardar la decena
  RESIDUO_V3: DS 1 ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_V3: DS 1 ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_V3: DS 1 ; Se guarda el valor traducido por la tabla de la variable decena
    
  UNIDAD_T1:  DS 1 ; variable que se usa en la division para guardar la unidad
  DECENA_T1:  DS 1 ; variable que se usa en la division para guardar la decena
  RESIDUO_T1: DS 1 ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_T1: DS 1 ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_T1: DS 1 ; Se guarda el valor traducido por la tabla de la variable decena
  
  UNIDAD_T2:  DS 1 ; variable que se usa en la division para guardar la unidad
  DECENA_T2:  DS 1 ; variable que se usa en la division para guardar la decena
  RESIDUO_T2: DS 1 ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_T2: DS 1 ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_T2: DS 1 ; Se guarda el valor traducido por la tabla de la variable decena  
    
  UNIDAD_T3:  DS 1 ; variable que se usa en la division para guardar la unidad
  DECENA_T3:  DS 1 ; variable que se usa en la division para guardar la decena
  RESIDUO_T3: DS 1 ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2_T3: DS 1 ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2_T3: DS 1 ; Se guarda el valor traducido por la tabla de la variable decena 
    
  RESET_DIS:    DS 1  

  PSECT udata_shr ;common memory
  W_T:       DS 1 ; variable que de interrupcio para w
  STATUS_T:  DS 1 ; variable que de interrupcio que guarda STATUS
  SENAL:     DS 1 ; Se utiliza como indicador para el cambio de display
  Estado:    DS 1 ; Se utiliza como indicador para el cambio de estado
  V1:        DS 1 ; Varible que se incrementa y decrementa para la conf. de via1
  V2:        DS 1 ; Varible que se incrementa y decrementa para la conf. de via2
  V3:        DS 1 ; Varible que se incrementa y decrementa para la conf. de via3
  TIEMPO1:   DS 1 ; Variable donde se guarda el tiempo de la via1
  TIEMPO2:   DS 1 ; Variable donde se guarda el tiempo de la via2
  TIEMPO3:   DS 1 ; Variable donde se guarda el tiempo de la via3
  
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
      BTFSC TMR1IF   ; verifica si se desbordo el timer0
      CALL SUB_TM1  ; llama a la subrrutina de interrupcion del tiemer 0
      BCF  TMR1IF ; Se limpia la bandera activada.
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
    BCF TRISE,2 ; Se colocan los pines del puerto C como salida 
    
   
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
    
    MOVLW 10
    MOVWF V1
    MOVWF V2
    MOVWF V3
    MOVLW 10
    MOVWF TIEMPO1
    MOVLW 20
    MOVWF TIEMPO2
    MOVLW 30
    MOVWF TIEMPO3 ; Se asignan los valores iniciales de los tiempos de las vias
    
    ;Configuracion del timer1
    BANKSEL PIE1
    BSF TMR1IE ; Se activa la interrupcion del timer1
    BANKSEL PIR1 
    BCF TMR1IF ; Se limpia la bandera del timer1
    BANKSEL T1CON
    BSF TMR1ON ; Se activa el timer1 
    BCF TMR1CS ; Reloj interno 
    BSF T1CKPS0  
    BSF T1CKPS1 ; pre-scaler de 1:8
    
    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC 
    CLRF PORTD ; Se limpian todos los puertos del pic
    CLRF PORTE
    BANKSEL PORTA 
    
loop:
    CALL LED_MODO ; Subrrutina para el cambio el cambio LED en el modo
    CALL MOSTRAR_DIS ; Sirve para guardar el valor en variables que se mostraran
    CALL DIVISION ; Donde se hace la division para obtener un valor decimal
    CALL PARA_MODO_NORMAL ; Sirve para hacer los cambios de modo del sistema
    GOTO loop ; ciclo infinito
   
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
    BCF	    IRCF2   
    BSF	    IRCF1   
    BCF	    IRCF0  ; Se configura el oscilador a una frecuencia de 250kHz 
    BSF	    SCS	  
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
;se realiza el tiempo de los semaforos 
PARA_MODO_NORMAL:
    MOVLW 10            ;Para el tiempo del primer semaforo:
    SUBWF TIEMPO1, 0
    BTFSC STATUS, 2
    BSF PORTA, 2        ;Encender led verde semaforo 1
    BTFSC STATUS, 2
    BCF PORTA, 0  ;Apagar led roja para el semaforo 1
    BTFSC STATUS, 2
    BCF PORTA, 1  ;APAGA LED AMARILLA semaforo1
    BTFSC STATUS, 2
    BSF PORTA, 3        ;Encender led roja para el semaforo 2
    BTFSC STATUS, 2
    BCF PORTA, 4       ;APAGA led amarillo del semaforo 2
    BTFSC STATUS, 2
    BCF PORTA, 5       ;APAGA led verde del semaforo 2
    BTFSC STATUS, 2
    BCF PORTE, 2      ;APARGA led verde del semaforo 3
    BTFSC STATUS, 2
    BCF PORTE, 1       ;APAGA led amarilla del semaforo3
    BTFSC STATUS, 2
    BCF PORTE, 0        ;Encender led roja para el semaforo 3
    MOVLW 6            ;Si el tiempo en Tiempo1M1 es 6, entonces:
    SUBWF TIEMPO1, 0
    BTFSC STATUS, 2
    BCF PORTA, 2        ;Hacer titilar led verde del semaforo 1
    BTFSC STATUS, 2
    BSF PORTA, 2
    BTFSC STATUS, 2
    BCF PORTA, 2
    MOVLW 5            ;Hacer titilar led verde del semaforo 1
    SUBWF TIEMPO1, 0
    BTFSC STATUS, 2
    BSF PORTA, 2
    BTFSC STATUS, 2
    BCF PORTA, 2
    BTFSC STATUS, 2
    BSF PORTA, 2
    MOVLW 4            ;Hacer titilar led verde del semaforo 1
    SUBWF TIEMPO1, 0
    BTFSC STATUS, 2
    BCF PORTA, 2
    BTFSC STATUS, 2
    BSF PORTA, 2
    BTFSC STATUS, 2
    BCF PORTA, 2
    MOVLW 3            ;cuando llega a 3:
    SUBWF TIEMPO1, 0
    BTFSC STATUS, 2
    BSF PORTA, 1        ;Se enciende el amarillo del semaforo1
    MOVLW 0            ;Si el tiempo ya es 0:
    SUBWF TIEMPO1, 0
    BTFSC STATUS, 2
    BCF PORTA, 1        ;Se apaga led amarilla
    BTFSC STATUS, 2
    CALL TOPE            ;Llamar subrutina para declarar el tope

    MOVLW 10            ;Para el tiempo del segundo semaforo
    SUBWF TIEMPO2, 0
    BTFSC STATUS, 2
    BSF PORTA, 5        ;Encender led verde del semaforo2
    BTFSC STATUS, 2
    BSF PORTA, 0        ;Enciend led roja para el semaforo 1
    BTFSC STATUS, 2
    BCF PORTA, 3        ;Apaga led roja para el semaforo 2
    BTFSC STATUS, 2
    BSF PORTE, 0        ;Encender led roja para el semaforo 3
    MOVLW 6            ;Si el tiempo llega a 6:
    SUBWF TIEMPO2, 0
    BTFSC STATUS, 2
    BCF PORTA, 5        ;Hacer titilar led verde del semaforo2
    BTFSC STATUS, 2
    BSF PORTA, 5
    BTFSC STATUS, 2
    BCF PORTA, 5
    MOVLW 5            ;Hacer titilar led verde del semaforo2
    SUBWF TIEMPO2, 0
    BTFSC STATUS, 2
    BSF PORTA, 5
    BTFSC STATUS, 2
    BCF PORTA, 5
    BTFSC STATUS, 2
    BSF PORTA, 5
    MOVLW 4            ;Hacer titilar led verde del semaforo2
    SUBWF TIEMPO2, 0
    BTFSC STATUS, 2
    BCF PORTA, 5
    BTFSC STATUS, 2
    BSF PORTA, 5
    BTFSC STATUS, 2
    BCF PORTA, 5
    MOVLW 3            ;Si el tiempo llega a 3:
    SUBWF TIEMPO2, 0
    BTFSC STATUS, 2
    BSF PORTA, 4        ;Encender led amarilla del semaforo2
    MOVLW 0            ;Si el tiempo llega a 0:
    SUBWF TIEMPO2, 0
    BTFSC STATUS, 2
    BCF PORTA, 4        ;Apagar led amarilla
    BTFSC STATUS, 2
    CALL TOPE            ;Llamar subrutina para hacer el tope de tiempo    
    
    MOVLW 10            ;Para el tiempo del tercer semaforo
    SUBWF TIEMPO3, 0
    BTFSC STATUS, 2
    BSF PORTE, 2        ;Encender led verde del tercer semaforo
    BTFSC STATUS, 2
    BSF PORTA, 0        ;Enciende led roja para el semaforo 1
    BTFSC STATUS, 2
    BSF PORTA, 3        ;Encender led roja para el semaforo 2
    BTFSC STATUS, 2
    BCF PORTE, 0        ;Apaga led roja para el semaforo 3
    MOVLW 6            ;Si el tiempo llega a 6, entonces:
    SUBWF TIEMPO3, 0
    BTFSC STATUS, 2
    BCF PORTE, 2        ;Hacer titilar led verde del semaforo 3
    BTFSC STATUS, 2
    BSF PORTE, 2
    BTFSC STATUS, 2
    BCF PORTE, 2
    MOVLW 5            ;Hacer titilar led verde del semaforo 3
    SUBWF TIEMPO3, 0
    BTFSC STATUS, 2
    BSF PORTE, 2
    BTFSC STATUS, 2
    BCF PORTE, 2
    BTFSC STATUS, 2
    BSF PORTE, 2
    MOVLW 4            ;Hacer titilar led verde del semaforo 3
    SUBWF TIEMPO3, 0
    BTFSC STATUS, 2
    BCF PORTE, 2
    BTFSC STATUS, 2
    BSF PORTE, 2
    BTFSC STATUS, 2
    BCF PORTE, 2
    MOVLW 3            ;Si el tiempo llega a 3:
    SUBWF TIEMPO3, 0
    BTFSC STATUS, 2
    BSF PORTE, 1        ;Encender led amarilla del semaforo 3
    MOVLW 0            ;Si el tiempo llega a 0:
    SUBWF TIEMPO3, 0
    BTFSC STATUS, 2
    BCF PORTE, 1        ;Apagar led amarilla del semaforo 3
    BTFSC STATUS, 2
    CALL TOPE            ;Llamar subrutina para hacer el tope de tiempo 
    RETURN
    
TOPE:
    ;Para el semaforo 1
    MOVLW 0            ;Si el tiempo, del semaforo1, llega a 0 :
    SUBWF TIEMPO1, 0
    BTFSC STATUS, 2
    CALL PARA_T1   ; Se llama para hacer la sumatoria de los tiempos T2 Y T3
    MOVWF TIEMPO1  ; se carga el valor al tiempo del semaforo1
    BSF PORTA, 0        ;Encender led roja del semaforo 1

    ;Para el semaforo 2
    MOVLW 0            ;Si el tiempo, del semaforo2, llega a 0 :
    SUBWF TIEMPO2, 0
    BTFSC STATUS, 2
    CALL  PARA_T2      ;Se llama para hacer la sumatoria de los tiempos T1 Y T3
    MOVWF TIEMPO2    ; se carga el valor al tiempo del semaforo2
    BSF PORTA, 3        ;Encender led roja del semaforo 2

    ;Para el semaforo 3
    MOVLW 0            ;Si el tiempo, del semaforo3, llega a 0 :
    SUBWF TIEMPO3, 0
    BTFSC STATUS, 2
    CALL  PARA_T3      ;Se llama para hacer la sumatoria de los tiempos T2 Y T1
    MOVWF TIEMPO3    ; se carga el valor al tiempo del semaforo3
    BSF PORTE, 0        ;Encender led roja del semaforo 3
    RETURN 
    
;Se hace la sumatoria de los tiempos para cada uno de los topes de los semaforos
PARA_T1:
    MOVF TIEMPO2,0
    ADDWF TIEMPO3,0
    RETURN
PARA_T2:
    MOVF TIEMPO1,0
    ADDWF TIEMPO3,0
    RETURN
PARA_T3:
    MOVF TIEMPO2,0
    ADDWF TIEMPO1,0
    RETURN
;se realiza el cambio de led para indicar el modo
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
    BCF PORTB, 7 ; Para el modo normal 
    RETURN
    
via1:
    BCF PORTB, 3
    BSF PORTB, 4
    BCF PORTB, 5
    BCF PORTB, 6
    BCF PORTB, 7 ; Para la configuaracion de tiempo para la via 1
    RETURN
     
via2:
    BCF PORTB, 3
    BCF PORTB, 4
    BSF PORTB, 5
    BCF PORTB, 6
    BCF PORTB, 7 ; Para la configuaracion de tiempo para la via 2
    RETURN
    
via3:
    BCF PORTB, 3
    BCF PORTB, 4
    BCF PORTB, 5
    BSF PORTB, 6
    BCF PORTB, 7; Para la configuaracion de tiempo para la via 3
    RETURN
    
ACEP_CAN:
    BCF PORTB, 3
    BCF PORTB, 4
    BCF PORTB, 5
    BCF PORTB, 6
    BSF PORTB, 7; Para indicar que estamos en el modo aceptar o cancelar 
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
    
    MOVF  DECENA_T1, W
    CALL  TABLA 
    MOVWF DECENA2_T1; Se guarda en la variable DECENA lo que contiene la variable DECENA2
    MOVF  UNIDAD_T1, W
    CALL  TABLA 
    MOVWF UNIDAD2_T1; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
    
    MOVF  DECENA_T2, W
    CALL  TABLA 
    MOVWF DECENA2_T2; Se guarda en la variable DECENA lo que contiene la variable DECENA2
    MOVF  UNIDAD_T2, W
    CALL  TABLA 
    MOVWF UNIDAD2_T2; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
    
    MOVF  DECENA_T3, W
    CALL  TABLA 
    MOVWF DECENA2_T3; Se guarda en la variable DECENA lo que contiene la variable DECENA2
    MOVF  UNIDAD_T3, W
    CALL  TABLA 
    MOVWF UNIDAD2_T3; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
    RETURN
    
DIVISION:
    clrf DECENA_V1    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_V1
    clrf RESIDUO_V1
    movf V1, 0     
    movwf RESIDUO_V1
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_V1, f    
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_V1    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        
    addwf RESIDUO_V1
    movf RESIDUO_V1, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_V1
    
    clrf DECENA_V2    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_V2
    clrf RESIDUO_V2
    movf V2, 0    
    movwf RESIDUO_V2
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_V2, f    
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_V2    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        
    addwf RESIDUO_V2
    movf RESIDUO_V2, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_V2
    
    clrf DECENA_V3    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_V3
    clrf RESIDUO_V3
    movf V3, 0     
    movwf RESIDUO_V3
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_V3, f    
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_V3    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        
    addwf RESIDUO_V3
    movf RESIDUO_V3, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_V3
    
    clrf DECENA_T1    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_T1
    clrf RESIDUO_T1
    movf TIEMPO1, 0    
    movwf RESIDUO_T1
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_T1, f    
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_T1    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        
    addwf RESIDUO_T1
    movf RESIDUO_T1, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_T1
    
    clrf DECENA_T2    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_T2
    clrf RESIDUO_T2
    movf TIEMPO2, 0    
    movwf RESIDUO_T2
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_T2, f    ;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_T2    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        
    addwf RESIDUO_T2
    movf RESIDUO_T2, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_T2
    
    clrf DECENA_T3    ;Limpiamos los registros a utilizar 
    clrf UNIDAD_T3
    clrf RESIDUO_T3
    movf TIEMPO3, 0    
    movwf RESIDUO_T3
    movlw 10        ;Mover valor 10 a W
    subwf RESIDUO_T3, f    ;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    incf DECENA_T3    ;Incrementar decenas
    btfsc STATUS, 0    ;Si la bandera no se levanto, no saltar
    goto $-5        ;Repetir hasta que ya no hayan decenas
    movlw 10        
    addwf RESIDUO_T3
    movf RESIDUO_T3, 0    ;Trasladar valor restante a unidades
    movwf UNIDAD_T3
    RETURN
    
;----------------------sub-rutinas de interrupcion------------------------------    

SUB_TM1:
    BANKSEL TMR1H
    MOVLW 0xE1
    MOVWF TMR1H
    BANKSEL TMR1L
    MOVLW 0x7C
    MOVWF TMR1L ; Se carga el valor adecuado de trabajo a los registros del TMR1
    DECF TIEMPO1 
    DECF TIEMPO2 
    DECF TIEMPO3 ; Se decrementan los tiempos de los semaforos 
    RETURN 

; Subrrutina de los pull-up
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
    BTFSS PORTB,1 ; verifica si el PB del segundo pin del puerto b esta activado
    CALL INCREMENTO_V1 ; llama a subrrutina para incrementa la variable
    BTFSS PORTB,2 ; verifica si el PB del terce pin del puerto b esta activado
    CALL DECREMENTO_V1 ; llama a subrrutina para decrementa la variable
    BTFSS PORTB,0
    BCF   Estado,0
    BTFSS PORTB, 0
    BSF   Estado,1 ; Si el PB del primer pin del puertoB cambia el valor de bandera
    RETURN
     
VIA2:
    BTFSS PORTB,1 ; verifica si el PB del segundo pin del puerto b esta activado
    CALL INCREMENTO_V2 ;llama a subrrutina para incrementa la variable
    BTFSS PORTB,2 ; verifica si el PB del tercer pin del puerto b esta activado
    CALL DECREMENTO_V2;llama a subrrutina para decrementa la variable
    BTFSS PORTB,0
    BCF   Estado,1
    BTFSS PORTB, 0
    BSF   Estado,2 ; Si el PB del primer pin del puertoB cambia el valor de bandera
    RETURN
    
VIA3:
    BTFSS PORTB,1 ; verifica si el PB del segundo pin del puerto b esta activado
    CALL INCREMENTO_V3 ;llama a subrrutina para incrementa la variable
    BTFSS PORTB,2 ; verifica si el PB del tercer pin del puerto b esta activado
    CALL DECREMENTO_V3; llama a subrrutina para decrementa la variable
    BTFSS PORTB,0
    BCF   Estado,2
    BTFSS PORTB,0
    BSF   Estado,3; Si el PB del primer pin del puertoB cambia el valor de bandera
    RETURN
    
ACEPTAR_CANCELAR:
    BCF RESET_DIS,0
    BTFSS PORTB,1 ; verifica si el PB del segundo pin del puerto b esta activado
    CALL ACEPTAR ;llama a subrrutina para cargar los valores a los semaforos
    BTFSS PORTB,2 ; verifica si el PB del tercer pin del puerto b esta activado
    CALL CANCELAR; llama a subrrutina para no cargar los valores propuestos
    BTFSS PORTB,0
    CALL REINICIO
    BTFSS PORTB,0; Si el PB del primer pin del puertoB limpia el valor de bandera
    CLRF  Estado ; y reinicia todo.
    RETURN
    
    
; subrrutinas para el incremento y decremento de variables de las vias con rango
; de 10 a 20 segundos
INCREMENTO_V1:
    INCF    V1
    BCF     STATUS, 2
    MOVLW   21
    SUBWF   V1, w
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   10
    MOVWF   V1 
    RETURN
    
DECREMENTO_V1:
    DECF    V1
    BCF     STATUS, 2
    MOVLW   9
    SUBWF   V1, w
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   20
    MOVWF   V1 
    RETURN
    
INCREMENTO_V2:
    INCF    V2
    BCF     STATUS, 2
    MOVLW   21
    SUBWF   V2, w
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   10
    MOVWF   V2 
    RETURN
    
DECREMENTO_V2:
    DECF    V2
    BCF     STATUS, 2
    MOVLW   9
    SUBWF   V2, w
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   20
    MOVWF   V2 
    RETURN
    
INCREMENTO_V3:
    INCF    V3
    BCF     STATUS, 2
    MOVLW   21
    SUBWF   V3, w
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   10
    MOVWF   V3 
    RETURN
    
DECREMENTO_V3:
    DECF    V3
    BCF     STATUS, 2
    MOVLW   9
    SUBWF   V3, w
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   20
    MOVWF   V3 
    RETURN
    
ACEPTAR:
    CALL RESETEO ; se llama subrrutina para hacer la rutina de rest
    MOVF V1,0
    MOVWF TIEMPO1, 1
    MOVF V2,0
    ADDWF TIEMPO1,0
    MOVWF TIEMPO2
    MOVF V3,0
    ADDWF TIEMPO2, 0
    MOVWF TIEMPO3, 1; Se cargan los valores configurados de cada via hacia los 
    RETURN; los tiempos de los semaforos.
    
CANCELAR:
    MOVLW 10
    MOVWF V1,1
    MOVWF V2,1
    MOVWF V3,1;solamente se devuelven a su valor inicial los valores de las vias
    RETURN

RESETEO:
    CLRF TIEMPO1
    CLRF TIEMPO2
    CLRF TIEMPO3 ; se limpian los valores de los tiempos de los semaforos 
    BSF RESET_DIS,0
    BSF PORTA, 0
    BSF PORTA, 3
    BSF PORTE, 0 ; Se prenden los leds rojos y se apagan los displays por un
    RETURN; momento para indicar que se hizo el reseteo 

REINICIO:
    CLRF TIEMPO1
    CLRF TIEMPO2
    CLRF TIEMPO3
    MOVLW 10
    MOVWF TIEMPO1
    MOVLW 20
    MOVWF TIEMPO2
    MOVLW 30
    MOVWF TIEMPO3; subrrutina que sirve para reiniciar todo cuando se pasa del 
    RETURN; modo 5 al modo 1 nuevamente cargandoles sus valores iniciales.
    
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
    BTFSC RESET_DIS,0;Sirve para indicar el reseteo cuando se cargan los valores
    RETURN
    MOVF DECENA2_T1, W
    MOVWF PORTC
    BSF PORTD, 0 ; Se pone el valor de DIS en el puerto D y se activa su display respectivo
    GOTO NEXT_D0; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS1:
    BTFSC RESET_DIS,0;Sirve para indicar el reseteo cuando se cargan los valores
    RETURN
    MOVF UNIDAD2_T1, W
    MOVWF PORTC
    BSF PORTD, 1 ; Se pone el valor de DIS+1 en el puerto D y se activa su display respectivo
    GOTO NEXT_D1 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS2:
    BTFSC RESET_DIS,0;Sirve para indicar el reseteo cuando se cargan los valores
    RETURN
    MOVF DECENA2_T2, W
    MOVWF PORTC
    BSF PORTD, 2 ; Se pone el valor de CENTENA2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D2 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS3:
    BTFSC RESET_DIS,0;Sirve para indicar el reseteo cuando se cargan los valores
    RETURN
    MOVF UNIDAD2_T2, W
    MOVWF PORTC
    BSF PORTD, 3 ; Se pone el valor de DECENA2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D3 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS4:
    BTFSC RESET_DIS,0;Sirve para indicar el reseteo cuando se cargan los valores
    RETURN
    MOVF DECENA2_T3, W
    MOVWF PORTC
    BSF PORTD, 4 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D4 ; Se utiliza para cambiar el valor de SENAL y cambiar de display

DIS5:
    BTFSC RESET_DIS,0;Sirve para indicar el reseteo cuando se cargan los valores
    RETURN
    MOVF UNIDAD2_T3, W
    MOVWF PORTC
    BSF PORTD, 5 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D5 ; Se utiliza para cambiar el valor de SENAL y cambiar de display

DIS6:
    BTFSC PORTB,3
    GOTO NEXT_D6
    BTFSC PORTB,4
    CALL DIS_V1_DECENA
    BTFSC PORTB,5
    CALL DIS_V2_DECENA
    BTFSC PORTB,6; sirven para indicar que valor mostrar dependiendo del estado
    CALL DIS_V3_DECENA; en que se esta para mostrarlo en el display
    BTFSC PORTB,7
    GOTO NEXT_D6
    BSF PORTD, 6 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D6 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS7:
    BTFSC PORTB,3
    GOTO NEXT_D7
    BTFSC PORTB,4
    CALL DIS_V1_UNIDAD
    BTFSC PORTB,5
    CALL DIS_V2_UNIDAD
    BTFSC PORTB,6;sirven para indicar que valor mostrar dependiendo del estado
    CALL DIS_V3_UNIDAD; en que se esta para mostrarlo en el display
    BTFSC PORTB,7
    GOTO NEXT_D7
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
    RETURN; Se utiliza la operacion xor para activar el quinto bit de SENAL
NEXT_D5:
    MOVLW 00110000B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el sexto bit de SENAL
NEXT_D6:
    MOVLW 01100000B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el septimo bit de SENAL
NEXT_D7:
    CLRF SENAL; Se limpia la variable SENAL
    RETURN
    
  ; son subrrutinas para mostrar que el valor correspondiente dependiendo del 
  ; modo en que se esta.
DIS_V1_DECENA:
    MOVF DECENA2_V1, W
    MOVWF PORTC
    RETURN
    
DIS_V1_UNIDAD:
    MOVF UNIDAD2_V1, W
    MOVWF PORTC
    RETURN

DIS_V2_DECENA:
    MOVF DECENA2_V2, W
    MOVWF PORTC
    RETURN
    
DIS_V2_UNIDAD:
    MOVF UNIDAD2_V2, W
    MOVWF PORTC
    RETURN
    
DIS_V3_DECENA:
    MOVF DECENA2_V3, W
    MOVWF PORTC
    RETURN
    
DIS_V3_UNIDAD:
    MOVF UNIDAD2_V3, W
    MOVWF PORTC
    RETURN
END