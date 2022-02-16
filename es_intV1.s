* Inicializa el SP y el PC
****************************

        ORG     $0
        DC.L    $8000     * Pila
        DC.L    PPAL      * PC

* Inicializacion de las etiquetas de los registros *
****************************************************

        ORG     $400
		
		flagA:  DS.B    1
        flagB:  DS.B    1

        fPRINT: DS.B     1 
*************************************************
* Inicializacion de los registros de la linea A *
*************************************************
MR1A		EQU		$EFFC01     * Direccion del registro de escritura
MR2A		EQU		$EFFC01     * Direccion del registro de lectura
SRA			EQU		$EFFC03     * Direccion del registro de estado
CSRA		EQU		$EFFC03     * Direccion del registro de seleccion de reloj
CRA			EQU		$EFFC05     * Direccion del registro de control
RBA			EQU		$EFFC07     * Direccion del buffer de recepcion
TBA			EQU		$EFFC07     * Direccion del buffer de transmision
MR1B		EQU		$EFFC11		* Direccion del registro de escritura
MR2B		EQU		$EFFC11		* Direccion del registro de lectura
SRB			EQU		$EFFC13		* Direccion del registro de estado
CSRB		EQU		$EFFC13		* Direccion del registro de seleccion de reloj
CRB			EQU		$EFFC15		* Direccion del registro de control
RBB			EQU		$EFFC17		* Direccion del buffer de recepcion
TBB			EQU		$EFFC17		* Direccion del buffer de transmision
ACR			EQU		$EFFC09		* Direccion del registro de control auxiliar(escritura)
ISR			EQU		$EFFC0B		* Direccion del registro de estado de interrupcion(lectura)
IMR			EQU		$EFFC0B		* Direccion del registro de mascara de interrupcion(escritura)
IVR			EQU		$EFFC19		* Direccion del registro del vector de interrupcion(lectura/escritura)

*******************************************
*** Inicializacion de mensaje (pruebas) ***
*******************************************

MENSAJE:		DC.L		'de computadores y mas'
PRUEBA_LC:		DC.L		'0123456789'
PRUEBA_SCAN:	DC.L		'abcdefghijklmnopqrst'
*PRUEBA_SCAN:	DC.L		'de computadores'


*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

* Definicion de variables  *
****************************

* DS: Es quivalente hacer un "res" en el mc88110 (reserva espacio en memoria a partir de la direccion de la etiqueta con un tamaño dado)
* DC: Es quivalente hacer un "data" en el mc88110 (inicializa variables en memoria con un tamaño dado)

*** Del buffer de recepcion de A ***
************************************
A_RECE_BUFF:		DS.B		2001			* Se reservan 2001B para el buffer interno de recepcion de la linea A
A_ESC_RECE:			DC.L		0				* Puntero de escritura del buffer de recepcion
A_LEC_RECE:			DC.L		0				* Puntero de lectura del buffer de recepcion
A_FIN_RECE:			DC.L		0				* Puntero de fin del buffer de recepcion

*** Del buffer de transmision A ***
***********************************
A_TRANS_BUFF:		DS.B		2001			* Se reservan 2001B para el buffer interno de transmision de la linea A
A_ESC_TRANS:		DC.L		0				* Puntero de escritura del buffer de transmision
A_LEC_TRANS:		DC.L		0 				* Puntero de lectura del buffer de transmision
A_FIN_TRANS:		DC.L		0				* Puntero de fin del buffer de transmision

*** Del buffer de recepcion de B ***
************************************
B_RECE_BUFF:		DS.B		2001			* Se reservan 2001B para el buffer interno de recepcion de la linea B
B_ESC_RECE:			DC.L		0				* Puntero de escritura del buffer de recepcion
B_LEC_RECE:			DC.L		0				* Puntero de lectura del buffer de recepcion
B_FIN_RECE:			DC.L		0				* Puntero de fin del buffer de recepcion

*** Del buffer de transmision de B ***
**************************************
B_TRANS_BUFF:		DS.B		2001			* Se reservan 2001B para el buffer interno de recepcion de la linea B
B_ESC_TRANS:		DC.L		0				* Puntero de escritura del buffer de transmision
B_LEC_TRANS:		DC.L		0 				* Puntero de lectura del buffer de transmision
B_FIN_TRANS:		DC.L		0				* Puntero de fin del buffer de transmision

*** Definicion de variables ***
*******************************
COPIA_IMR:			DC.B		0				* Copia del registro de mascara de interrupcion (para poder leerlo)


VAR_LIBRE:			DC.W		0				* Se rellena con 0's para completar una palabra (junto a los flags)

*** Buffer para las pruebas de PRINT y SCAN ***
***********************************************

BUFFER:				DS.B		2100			* Buffer para lectura y escritura de caracteres

*** ///////////////////////////////////////////////////////////////////////////////////////////// ***


**********************
*** Subrutina INIT ***
**********************

INIT:
		
        MOVE.B      #%00000011,MR1A     		* 8 bits por caracter en A ademas de solicitar una interrupcion por cada caracter
        MOVE.B      #%00000011,MR1B     		* 8 bits por caracter en B ademas de solicitar una interrupcion por cada caracter
        
		MOVE.B      #%00000000,MR2A     		* Modo eco desactivado en el puerto A
		MOVE.B      #%00000000,MR2B     		* Modo eco desactivado en el puerto B
        
		MOVE.B      #%00000000,ACR      		* Seleccionamos velocidad conjunto 1 = 38400 bps
        
		MOVE.B      #%11001100,CSRA     		* Velocidad = 38400 bps (tranmision y recepcion)
        MOVE.B      #%11001100,CSRB     		* Velocidad = 38400 bps (tranmision y recepcion)
        
		MOVE.B      #%00000101,CRA      		* Transmision y recepcion activada para A
        MOVE.B      #%00000101,CRB      		* Transmision y recepcion activada para B
		
		MOVE.B		#$40,IVR					* Se establece el vector de interrupcion 0x40
		
		MOVE.B		#%00100010,COPIA_IMR		* Se actualiza el valor de la copia de la mascara de interrupciones
		
		MOVE.B COPIA_IMR,IMR 				  *copia_IMR A IMR (Habilita las interrupciones de A y B)
		MOVE.B  #0,flagA                    *Inicializo a 0 el flag TBA 
		MOVE.B  #0,flagB                    *Inicializo a 0 el flag TBB

		MOVE.L  #RTI,$100	                    *0x40*0x04=0x100
		
		MOVE.B  #0,fPRINT                    *Inicializo a 0 el flag auxiliar que se usa en PRINT
		
*** Inicializacion de bufferes ***
**********************************

		MOVE.L		#0,A1						* A1 = 0 (Registro auxiliar para inicializar los bufferes)
		
		LEA			A_RECE_BUFF,A1				* A1 = dir. del buffer de recepcion de la linea A
		MOVE.L		A1,A_ESC_RECE				* A_ESC_RECE = dir. de inicio del buffer de recepcion de A
		MOVE.L		A1,A_LEC_RECE				* A_LEC_RECE = dir. de inicio del buffer de recepcion de A
		ADDA.L		#2000,A1					* A1 = dir. de inicio del buffer de recepcion de A + 2000
		MOVE.L		A1,A_FIN_RECE				* A_FIN_RECE = dir. final del buffer de recepcion de A
		
		MOVE.L		#0,A1						* A1 = 0
		
		LEA			A_TRANS_BUFF,A1				* A1 = dir. del buffer de transmision de la linea A
		MOVE.L		A1,A_ESC_TRANS				* A_ESC_TRANS = dir. de escritura del buffer de transmision de A
		MOVE.L		A1,A_LEC_TRANS				* A_LEC_TRANS = dir. de lectura del buffer de transmision de A
		ADDA.L		#2000,A1					* A1 = dir. de inicio del buffer de transmision de A + 2000 A
		MOVE.L		A1,A_FIN_TRANS				* A_FIN_TRANS = dir. final del buffer de transmision de A
		
		MOVE.L		#0,A1						* A1 = 0
		
		LEA			B_RECE_BUFF,A1				* A1 = dir. del buffer de recepcion de la linea B		
		MOVE.L		A1,B_ESC_RECE				* B_ESC_RECE = dir. de escritura del buffer de recepcion de B
		MOVE.L		A1,B_LEC_RECE				* B_LEC_RECE = dir. de lectura del buffer de recepcion de B
		ADDA.L		#2000,A1					* A1 = dir. del buffer de recepcion de la linea B + 2000
		MOVE.L		A1,B_FIN_RECE				* B_FIN_RECE = dir. final del buffer de recepcion de B
		
		MOVE.L		#0,A1						* A1 = 0
		
		LEA			B_TRANS_BUFF,A1				* A1 = dir. del buffer de transmision de la linea B
		MOVE.L		A1,B_ESC_TRANS				* B_ESC_TRANS = dir. de escritura del buffer de transmision de B
		MOVE.L		A1,B_LEC_TRANS				* B_LEC_TRANS = dir. de lectura del buffer de transmision de B
		ADDA.L		#2000,A1					* A1 = dir. del buffer de transmision de la linea B + 2000
		MOVE.L		A1,B_FIN_TRANS				* B_FIN_TRANS = dir. final del buffer de transmision de B

		MOVE.L		#0,A1						* Se limpia el contenido del registro A1
		MOVE.L		#0,A2						* Se limpia el contenido del registro A2

		
		ANDI.W		#$2000,SR					* Se activa el modo supervisor y las interrupciones
		
		RTS										* Retorno

*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

**************
*** LEECAR ***
**************

* LEECAR(Buffer)
* Parametros: Buffer --> Se pasa por valor en el registro D0. Dos bits significativos:
* 							bit 0 --> Selecciona la linea de transmision: 0 Para la linea A
*																		  1 para la linea B
*
*							bit 1 --> Selecciona el tipo de buffer:		  0 Para el buffer de recepcion
*																		  1 Para el buffer de transmision

LEECAR:

		LINK		A6,#-16				* Se crea un marco de pila de 16B para variables locales
		
		MOVE.L		A1,-4(A6)			* Se almacena el valor de A1 en el marco de pila
		MOVE.L		A2,-8(A6)			* Se almacena el valor de A2 en el marco de pila
		MOVE.L		A3,-12(A6)			* Se almacena el valor de A3 en el marco de pila
		MOVE.L		A4,-16(A6)			* Se almacena el valor de A4 en el marco de pila
		
		CMP.B		#0,D0				* Si D0 = 00 entonces: buffer de recepcion de la linea A
		BEQ			BUFF_RA
		
		CMP.B		#1,D0				* Si D0 = 01 entonces: buffer de recepcion de la linea B
		BEQ			BUFF_RB
		
		CMP.B		#2,D0				* Si D0 = 10 entonces: buffer de transmision de la linea A
		BEQ			BUFF_TA
		
		CMP.B		#3,D0				* Si D0 = 11 entonces: buffer de transmision de la linea B
		BEQ			BUFF_TB
		
		MOVE.L		#$FFFFFFFF,D0		* Si se llega a este punto, hay error ( D0 != {0, 1, 2, 3} ) --> D0 = 0xFF...F
		
FIN_LEECAR:

		MOVE.L		-4(A6),A1			* Se devuelve el valor del registro A1
		MOVE.L		-8(A6),A2			* Se devuelve el valor del registro A2
		MOVE.L		-12(A6),A3			* Se devuelve el valor del registro A3
		MOVE.L		-16(A6),A4			* Se devuelve el valor del registro A4
		
		UNLK		A6					* Se destruye el marco de pila
		
		RTS								* Retorno
		
********************************
*** Buffer de recepcion de A ***
********************************

BUFF_RA:

		LEA			A_RECE_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de A
		MOVE.L		A_LEC_RECE,A2		* A2 = dir. de lectura del buffer de recepcion de A
		MOVE.L		A_ESC_RECE,A3		* A3 = dir. de escritura del buffer de recepcion de A
		MOVE.L		A_FIN_RECE,A4		* A4 = dir. de fin del buffer de recepcion de A
		
		CMP.L		A2,A3				* Si A2 == A3 entonces: No hay datos por leer
		BEQ			FIN_BRA
		
		MOVE.B		(A2),D0				* Se lee el caracter del buffer interno
		
		CMP.L		A2,A4				* Si A2 == A4 entonces: estoy en el final del buffer y modifico el puntero de lectura
		BEQ			RES_PLRA			* Salta a resetear el puntero de lectura (del buffer) de recepcion de A
		
		ADD.L		#1,A2				* Avanzo el puntero de lectura al siguiente caracter
		MOVE.L		A2,A_LEC_RECE		* Actualizo el valor del puntero real
		
		JMP			FIN_LEECAR
		
RES_PLRA:

		MOVE.L		A1,A2				* A2 = dir. de inicio del buffer de recepcion de A
		MOVE.L		A1,A_LEC_RECE		* Se modifica la direccion real de lectura del buffer
		JMP			FIN_LEECAR
		
FIN_BRA:

		MOVE.L		#$FFFFFFFF,D0		* No se puede leer --> D0 = 0xFF...F
		JMP			FIN_LEECAR
		
********************************
*** Buffer de recepcion de B ***
********************************

BUFF_RB:

		LEA			B_RECE_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de B
		MOVE.L		B_LEC_RECE,A2		* A2 = dir. de lectura del buffer de recepcion de B
		MOVE.L		B_ESC_RECE,A3		* A3 = dir. de escritura del buffer de recepcion de B
		MOVE.L		B_FIN_RECE,A4		* A4 = dir. de fin del buffer de recepcion de B
		
		CMP.L		A2,A3				* Si A2 == A3 entonces: No hay datos por leer
		BEQ			FIN_BRB
		
		MOVE.B		(A2),D0				* Se lee el caracter del buffer interno
		
		CMP.L		A2,A4				* Si A2 == A4 entonces: estoy en el final del buffer y modifico el puntero de lectura
		BEQ			RES_PLRB			* Salta a resetear el puntero de lectura (del buffer) de recepcion de B
		
		ADD.L		#1,A2				* Avanzo el puntero de lectura al siguiente caracter
		MOVE.L		A2,B_LEC_RECE		* Actualizo el valor del puntero real
		
		JMP			FIN_LEECAR
		
RES_PLRB:

		MOVE.L		A1,A2				* A2 = dir. de inicio del buffer de recepcion de B
		MOVE.L		A2,B_LEC_RECE
		
		JMP			FIN_LEECAR
		
FIN_BRB:

		MOVE.L		#$FFFFFFFF,D0		* No se puede leer --> D0 = 0xFF...F
		JMP			FIN_LEECAR
		
**********************************
*** Buffer de transmision de A ***
**********************************

BUFF_TA:

		LEA			A_TRANS_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de A
		MOVE.L		A_LEC_TRANS,A2		* A2 = dir. de lectura del buffer de recepcion de A
		MOVE.L		A_ESC_TRANS,A3		* A3 = dir. de escritura del buffer de recepcion de A
		MOVE.L		A_FIN_TRANS,A4		* A4 = dir. de fin del buffer de recepcion de A
		
		CMP.L		A2,A3				* Si A2 == A3 entonces: No hay datos por leer
		BEQ			FIN_BTA
		
		MOVE.B		(A2),D0				* Se lee el caracter del buffer interno
		
		CMP.L		A2,A4				* Si A2 == A4 entonces: estoy en el final del buffer y modifico el puntero de lectura
		BEQ			RES_PLTA			* Salta a resetear el puntero de lectura (del buffer) de transmision de A
		
		ADD.L		#1,A2				* Avanzo el puntero de lectura al siguiente caracter
		MOVE.L		A2,A_LEC_TRANS
		
		JMP			FIN_LEECAR
		
RES_PLTA:

		MOVE.L		A1,A2				* A2 = dir. de inicio del buffer de transmision de A
		MOVE.L		A2,A_LEC_TRANS
		
		JMP			FIN_LEECAR
		
FIN_BTA:

		MOVE.L		#$FFFFFFFF,D0		* No se puede leer --> D0 = 0xFF...F
		JMP			FIN_LEECAR
		
**********************************
*** Buffer de transmision de B ***
**********************************

BUFF_TB:

		LEA			B_TRANS_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de B
		MOVE.L		B_LEC_TRANS,A2		* A2 = dir. de lectura del buffer de recepcion de B
		MOVE.L		B_ESC_TRANS,A3		* A3 = dir. de escritura del buffer de recepcion de B
		MOVE.L		B_FIN_TRANS,A4		* A4 = dir. de fin del buffer de recepcion de B
		
		
		CMP.L		A2,A3				* Si A2 == A3 entonces: No hay datos por leer
		BEQ			FIN_BTB
		
		MOVE.B		(A2),D0				* Se lee el caracter
		
		CMP.L		A2,A4				* Si A2 == A4 entonces: estoy en el final del buffer y modifico el puntero de lectura
		BEQ			RES_PLTB
		
		ADD.L		#1,A2				* Avanzo el puntero de lectura al siguiente caracer
		MOVE.L		A2,B_LEC_TRANS
		
		JMP			FIN_LEECAR
		
RES_PLTB:

		MOVE.L		A1,A2				* A2 = dir. de inicio del buffer de transmision de B
		MOVE.L		A2,B_LEC_TRANS
		
		JMP			FIN_LEECAR
		
FIN_BTB:

		MOVE.L		#$FFFFFFFF,D0		* No se puede leer --> D0 = 0xFF...F
		JMP			FIN_LEECAR
		
		
*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

**************
*** ESCCAR ***
**************

* ESCCAR(Buffer, Caracter)
* Parametros: Buffer --> De 4B. Se pasa por valor en el registro D0. Dos bits significativos:
* 							bit 0 --> Selecciona la linea de transmision: 0 Para la linea A
*																		  1 para la linea B
*							bit 1 --> Selecciona el tipo de buffer:		  0 Para el buffer de recepcion
*																		  1 Para el buffer de transmision
*
*			  Caracter --> De 1B. Se pasa por valor en los 8 bits menos significativos de D1.

ESCCAR:

		LINK		A6,#-16				* Se crea un marco de pila de 16B para variables locales.
		
		MOVE.L		A1,-4(A6)			* Se almacena el valor de A1 en el marco de pila.
		MOVE.L		A2,-8(A6)			* Se almacena el valor de A2 en el marco de pila.
		MOVE.L		A3,-12(A6)			* Se almacena el valor de A3 en el marco de pila.
		MOVE.L		A4,-16(A6)			* Se almacena el valor de A4 en el marco de pila.
		
		CMP.B		#0,D0				* Si D0 = 00 entonces: Se desea acceder al buffer de recepcion de A
		BEQ			ESC_RA
		
		CMP.B		#1,D0				* Si D0 = 01 entonces: Se desea acceder al buffer de recepcion de B
		BEQ			ESC_RB
		
		CMP.B		#2,D0				* Si D0 = 10 entonces: Se desea acceder al buffer de transmision de A
		BEQ			ESC_TA
		
		CMP.B		#3,D0				* Si D0 = 11 entonces: Se desea acceder al buffer de transmision de B
		BEQ			ESC_TB
		
		* Si se llega a este punto hay error.
		MOVE.L		#$FFFFFFFF,D0		* D0 = 0xFF...F
		
FIN_ESCCAR:

		MOVE.L		-4(A6),A1			* Devuelvo el valor del registro A1
		MOVE.L		-8(A6),A2			* Devuelvo el valor del registro A2
		MOVE.L		-12(A6),A3			* Devuelvo el valor del registro A3
		MOVE.L		-16(A6),A4			* Devuelvo el valor del registro A4
		
		UNLK		A6					* Destruyo el marco de pila
		
		RTS								* Retorno

********************************
*** Buffer de recepcion de A ***
********************************	
	
ESC_RA:

		LEA			A_RECE_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de A
		MOVE.L		A_LEC_RECE,A2		* A2 = dir. de lectura del buffer de recepcion de A
		MOVE.L		A_ESC_RECE,A3		* A3 = dir. de escritura del buffer de recepcion de A
		MOVE.L		A_FIN_RECE,A4		* A4 = dir. de fin del buffer de recepcion de A
		
		MOVE.B		D1,(A3)			* Se inserta el caracter en el buffer interno de recepcion de A
		
		CMP.L		A3,A4			* Si A3 == A4 entonces: estoy en el final del buffer
		BEQ			RES_PERA		* Se lleva el puntero de escritura de recepcion de A al comienzo del buffer
		
		ADD.L		#1,A3			* Se incrementa en 1B el puntero de escritura.
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: Hay que retroceder en una posicion el puntero de escritura.
		BEQ			RET_PERA
		
FIN_EBRA:

		MOVE.L		#0,D0			* Codigo de que se ha insertado correctamente el caracter en el buffer interno
		MOVE.L		A3,A_ESC_RECE	* Se actualiza el valor del puntero de escritura real.
		JMP			FIN_ESCCAR
		
RES_PERA:

		MOVE.L		A1,A3			* Se resetea el puntero de escritura
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: el buffer esta lleno
		BEQ			FULL_BRA
		
		JMP			FIN_EBRA
		
FULL_BRA:

		MOVE.L		A4,A3			* Se lleva el puntero de escritura al final (de nuevo)
		MOVE.L		A3,A_ESC_RECE	* Se actualiza el valor del puntero de escritura
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error en D0 por estar lleno el buffer
		
		JMP			FIN_ESCCAR
		
RET_PERA:

		SUB.L		#1,A3			* Llevo el puntero de escritura una posicion atras
		MOVE.L		A3,A_ESC_RECE	* Actualizo el puntero de escritura real
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error por estar el buffer lleno
		
		JMP			FIN_ESCCAR
		
********************************
*** Buffer de recepcion de B ***
********************************

ESC_RB:

		LEA			B_RECE_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de B
		MOVE.L		B_LEC_RECE,A2		* A2 = dir. de lectura del buffer de recepcion de B
		MOVE.L		B_ESC_RECE,A3		* A3 = dir. de escritura del buffer de recepcion de B
		MOVE.L		B_FIN_RECE,A4		* A4 = dir. de fin del buffer de recepcion de B
		
		MOVE.B		D1,(A3)			* Se inserta el caracter en el buffer interno de recepcion de B
		
		CMP.L		A3,A4			* Si A3 == A4 entonces: estoy en el final del buffer
		BEQ			RES_PERB		* Se lleva el puntero de escritura de recepcion de B al comienzo del buffer
		
		ADD.L		#1,A3			* Se incrementa en 1B el puntero de escritura.
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: Hay que retroceder en una posicion el puntero de escritura.
		BEQ			RET_PERB
		
FIN_EBRB:

		MOVE.L		#0,D0			* Codigo de que se ha insertado correctamente el caracter en el buffer interno
		MOVE.L		A3,B_ESC_RECE	* Se actualiza el valor del puntero de escritura real.
		JMP			FIN_ESCCAR
		
RES_PERB:

		MOVE.L		A1,A3			* Se resetea el puntero de escritura
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: el buffer esta lleno
		BEQ			FULL_BRB
		
		JMP			FIN_EBRB
		
FULL_BRB:

		MOVE.L		A4,A3			* Se lleva el puntero de escritura al final (de nuevo)
		MOVE.L		A3,B_ESC_RECE	* Se actualiza el valor del puntero de escritura
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error en D0 por estar lleno el buffer
		
		JMP			FIN_ESCCAR
		
RET_PERB:

		SUB.L		#1,A3			* Llevo el puntero de escritura una posicion atras
		MOVE.L		A3,B_ESC_RECE	* Actualizo el puntero de escritura real
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error por estar el buffer lleno
		
		JMP			FIN_ESCCAR
		
**********************************
*** Buffer de transmision de A ***
**********************************

ESC_TA:

		LEA			A_TRANS_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de A
		MOVE.L		A_LEC_TRANS,A2		* A2 = dir. de lectura del buffer de recepcion de A
		MOVE.L		A_ESC_TRANS,A3		* A3 = dir. de escritura del buffer de recepcion de A
		MOVE.L		A_FIN_TRANS,A4		* A4 = dir. de fin del buffer de recepcion de A
		
		MOVE.B		D1,(A3)			* Se inserta el caracter en el buffer interno de transimison de A
		
		CMP.L		A3,A4			* Si A3 == A4 entonces: estoy en el final del buffer
		BEQ			RES_PETA		* Se lleva el puntero de escritura de transimison de A al comienzo del buffer
		
		ADD.L		#1,A3			* Se incrementa en 1B el puntero de escritura.
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: Hay que retroceder en una posicion el puntero de escritura.
		BEQ			RET_PETA
		
FIN_EBTA:

		MOVE.L		#0,D0			* Codigo de que se ha insertado correctamente el caracter en el buffer interno
		MOVE.L		A3,A_ESC_TRANS	* Se actualiza el valor del puntero de escritura real.
		JMP			FIN_ESCCAR
		
RES_PETA:

		MOVE.L		A1,A3			* Se resetea el puntero de escritura
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: el buffer esta lleno
		BEQ			FULL_BTA
		
		JMP			FIN_EBTA
		
FULL_BTA:

		MOVE.L		A4,A3			* Se lleva el puntero de escritura al final (de nuevo)
		MOVE.L		A3,A_ESC_TRANS	* Se actualiza el valor del puntero de escritura
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error en D0 por estar lleno el buffer
		
		JMP			FIN_ESCCAR
		
RET_PETA:

		SUB.L		#1,A3			* Llevo el puntero de escritura una posicion atras
		MOVE.L		A3,A_ESC_TRANS	* Actualizo el puntero de escritura real
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error por estar el buffer lleno
		
		JMP			FIN_ESCCAR
		
**********************************
*** Buffer de transmision de B ***
**********************************

ESC_TB:

		LEA			B_TRANS_BUFF,A1		* A1 = dir. de inicio del buffer de recepcion de B
		MOVE.L		B_LEC_TRANS,A2		* A2 = dir. de lectura del buffer de recepcion de B
		MOVE.L		B_ESC_TRANS,A3		* A3 = dir. de escritura del buffer de recepcion de B
		MOVE.L		B_FIN_TRANS,A4		* A4 = dir. de fin del buffer de recepcion de B
		
		MOVE.B		D1,(A3)			* Se inserta el caracter en el buffer interno de transimison de B
		
		CMP.L		A3,A4			* Si A3 == A4 entonces: estoy en el final del buffer
		BEQ			RES_PETB		* Se lleva el puntero de escritura de transimison de B al comienzo del buffer
		
		ADD.L		#1,A3			* Se incrementa en 1B el puntero de escritura.
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: Hay que retroceder en una posicion el puntero de escritura.
		BEQ			RET_PETB
		
FIN_EBTB:

		MOVE.L		#0,D0			* Codigo de que se ha insertado correctamente el caracter en el buffer interno
		MOVE.L		A3,B_ESC_TRANS	* Se actualiza el valor del puntero de escritura real.
		
		JMP			FIN_ESCCAR
		
RES_PETB:

		MOVE.L		A1,A3			* Se resetea el puntero de escritura
		
		CMP.L		A2,A3			* Si A2 == A3 entonces: el buffer esta lleno
		BEQ			FULL_BTB
		
		JMP			FIN_EBTB
		
FULL_BTB:

		MOVE.L		A4,A3			* Se lleva el puntero de escritura al final (de nuevo)
		MOVE.L		A3,B_ESC_TRANS	* Se actualiza el valor del puntero de escritura
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error en D0 por estar lleno el buffer
		
		JMP			FIN_ESCCAR
		
RET_PETB:

		SUB.L		#1,A3			* Llevo el puntero de escritura una posicion atras
		MOVE.L		A3,B_ESC_TRANS	* Actualizo el puntero de escritura real
		
		MOVE.L		#$FFFFFFFF,D0	* Codigo de error por estar el buffer lleno
		
		JMP			FIN_ESCCAR

*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

*************
*** LINEA ***
*************

* LINEA(Buffer)
* Parametros: Buffer --> Se pasa por valor en el registro D0. Dos bits significativos:
* 							bit 0 --> Selecciona la linea de transmision: 0 Para la linea A
*																		  1 para la linea B
*
*							bit 1 --> Selecciona el tipo de buffer:		  0 Para el buffer de recepcion
*																		  1 Para el buffer de transmision

LINEA:

		LINK		A6,#-20			* Se crea el marco de pila con 20B para variables locales
		
		MOVE.L		A1,-4(A6)		* Se almacena el valor del registro de A1 en el marco de pila
		MOVE.L		A2,-8(A6)		* Se almacena el valor del registro de A2 en el marco de pila
		MOVE.L		A3,-12(A6)		* Se almacena el valor del registro de A3 en el marco de pila
		MOVE.L		A4,-16(A6)		* Se almacena el valor del registro de A4 en el marco de pila
		MOVE.L		D1,-20(A6)		* Se almacena el valor del registro de D1 en el marco de pila
		
		MOVE.L		#0,D1			* Variable auxiliar que tendra el valor del caracter almacenado en el buffer interno
		
		CMP.B		#0,D0			* Si D0 = 00 entonces: se quiere acceder al buffer interno de recepcion de la linea A
		BEQ			LIN_BRA
		
		CMP.B		#1,D0			* Si D0 = 01 entonces: se quiere acceder al buffer interno de recepcion de la linea B
		BEQ			LIN_BRB
		
		CMP.B		#2,D0			* Si D0 = 10 entonces: se quiere acceder al buffer interno de transmision de la linea A
		BEQ			LIN_BTA
		
		CMP.B		#3,D0			* Si D0 = 11 entonces: se quiere acceder al buffer interno de transmision de la linea B
		BEQ			LIN_BTB
		
		MOVE.L		#$FFFFFFFF,D0	* Si se llega a este punto es porque ha habido error
		
FIN_LINEA:

		MOVE.L		-4(A6),A1		* Se devuelve el valor del registro A1
		MOVE.L		-8(A6),A2		* Se devuelve el valor del registro A2
		MOVE.L		-12(A6),A3		* Se devuelve el valor del registro A3
		MOVE.L		-16(A6),A4		* Se devuelve el valor del registro A4
		MOVE.L		-20(A6),D1		* Se devuelve el valor del registro D1
		
		UNLK		A6				* Se destruye el marco de pila
		
		RTS							* Retorno
		
********************************
*** Buffer de recepcion de A ***
********************************

LIN_BRA:

		LEA			A_RECE_BUFF,A1	* A1 = dir. de inicio del buffer de recepcion de la liena A
		MOVE.L		A_LEC_RECE,A2	* A2 = dir. de lectura del buffer de recepcion de la linea A
		MOVE.L		A_ESC_RECE,A3	* A3 = dir. de escritura del buffer de recepcion de la linea A
		MOVE.L		A_FIN_RECE,A4	* A4 = dir. de fin del buffer de recepcion de la linea A
		
		MOVE.L		#0,D0			* Limpio el contenido de D0
		
BUCL_BRA:

		CMP.L		A2,A3			* Si A2 == A3 entonces no hay ninguna linea en el buffer (BUFFER VACIO)
		BEQ			RES_BRAC
		
		CMP.L		A2,A4			* Si A2 == A4 entonces reseteo el puntero de lectura al principio del buffer
		BEQ			FIN_LBRA
		
		MOVE.B		(A2),D1			* D1 = caracter del buffer en la posicion de lectura
		ADD.L		#1,D0			* D0++
		
		CMP.B		#13,D1			* Si D1 == 0xD (Retorno de carro) he encontrado una linea
		BEQ			FIN_LINEA
		
		ADD.L		#1,A2			* Siguiente caracter
		
		JMP			BUCL_BRA

FIN_LBRA:

		MOVE.B		(A2),D1
		ADD.L		#1,D0			* Incrementa el contador contando el ultimo caracter del buffer
		
		CMP.B		#13,D1			* Compruebo si el ultimo caracter del buffer es el retorno de carro
		BEQ			FIN_LINEA

		MOVE.L		A1,A2			* Llevo el puntero de escritura al principio del buffer
		
		JMP			BUCL_BRA
		
RES_BRAC:

		MOVE.L		#0,D0			* D0 = 0
		
		JMP			FIN_LINEA
		
********************************
*** Buffer de recepcion de B ***
********************************

LIN_BRB:

		LEA			B_RECE_BUFF,A1	* A1 = dir. de inicio del buffer de recepcion de la liena B
		MOVE.L		B_LEC_RECE,A2	* A2 = dir. de lectura del buffer de recepcion de la linea B
		MOVE.L		B_ESC_RECE,A3	* A3 = dir. de escritura del buffer de recepcion de la linea B
		MOVE.L		B_FIN_RECE,A4	* A4 = dir. de fin del buffer de recepcion de la linea B
		
		MOVE.L		#0,D0			* Limpio el contenido de D0
		
BUCL_BRB:

		CMP.L		A2,A3			* Si A2 == A3 entonces no hay ninguna linea en el buffer (BUFFER VACIO)
		BEQ			RES_BRBC
		
		CMP.L		A2,A4			* Si A2 == A4 entonces reseteo el puntero de lectura al principio del buffer
		BEQ			FIN_LBRB
		
		MOVE.B		(A2),D1			* D1 = caracter del buffer en la posicion de lectura
		ADD.L		#1,D0			* D0++
		
		CMP.B		#13,D1			* Si D1 == 0xD (Retorno de carro) he encontrado una linea
		BEQ			FIN_LINEA
		
		ADD.L		#1,A2			* Siguiente caracter
		
		JMP			BUCL_BRB

FIN_LBRB:

		MOVE.B		(A2),D1
		ADD.L		#1,D0			* Incrementa el contador contando el ultimo caracter del buffer
		
		CMP.B		#13,D1			* Compruebo si el ultimo caracter del buffer es el retorno de carro
		BEQ			FIN_LINEA

		MOVE.L		A1,A2			* Llevo el puntero de escritura al principio del buffer
		
		JMP			BUCL_BRB
		
RES_BRBC:

		MOVE.L		#0,D0			* D0 = 0
		
		JMP			FIN_LINEA
		
**********************************
*** Buffer de transmision de A ***
**********************************

LIN_BTA:

		LEA			A_TRANS_BUFF,A1	* A1 = dir. de inicio del buffer de transmision de la liena A
		MOVE.L		A_LEC_TRANS,A2	* A2 = dir. de lectura del buffer de transmision de la linea A
		MOVE.L		A_ESC_TRANS,A3	* A3 = dir. de escritura del buffer de transmision de la linea A
		MOVE.L		A_FIN_TRANS,A4	* A4 = dir. de fin del buffer de transmision de la linea A
		
		MOVE.L		#0,D0			* Limpio el contenido de D0
		
BUCL_BTA:

		CMP.L		A2,A3			* Si A2 == A3 entonces no hay ninguna linea en el buffer (BUFFER VACIO)
		BEQ			RES_BTAC
		
		CMP.L		A2,A4			* Si A2 == A4 entonces reseteo el puntero de lectura al principio del buffer
		BEQ			FIN_LBTA
		
		MOVE.B		(A2),D1			* D1 = caracter del buffer en la posicion de lectura
		ADD.L		#1,D0			* D0++
		
		CMP.B		#13,D1			* Si D1 == 0xD (Retorno de carro) he encontrado una linea
		BEQ			FIN_LINEA
		
		ADD.L		#1,A2			* Siguiente caracter
		
		JMP			BUCL_BTA

FIN_LBTA:

		MOVE.B		(A2),D1
		ADD.L		#1,D0			* Incrementa el contador contando el ultimo caracter del buffer
		
		CMP.B		#13,D1			* Compruebo si el ultimo caracter del buffer es el retorno de carro
		BEQ			FIN_LINEA

		MOVE.L		A1,A2			* Llevo el puntero de escritura al principio del buffer
		
		JMP			BUCL_BTA
		
RES_BTAC:

		MOVE.L		#0,D0			* D0 = 0
		
		JMP			FIN_LINEA
		
**********************************
*** Buffer de transmision de B ***
**********************************

LIN_BTB:

		LEA			B_TRANS_BUFF,A1	* A1 = dir. de inicio del buffer de transmision de la liena B
		MOVE.L		B_LEC_TRANS,A2	* A2 = dir. de lectura del buffer de transmision de la linea B
		MOVE.L		B_ESC_TRANS,A3	* A3 = dir. de escritura del buffer de transmision de la linea B
		MOVE.L		B_FIN_TRANS,A4	* A4 = dir. de fin del buffer de transmision de la linea B
		
		MOVE.L		#0,D0			* Limpio el contenido de D0
		
BUCL_BTB:

		CMP.L		A2,A3			* Si A2 == A3 entonces no hay ninguna linea en el buffer (BUFFER VACIO)
		BEQ			RES_BTBC
		
		CMP.L		A2,A4			* Si A2 == A4 entonces reseteo el puntero de lectura al principio del buiffer
		BEQ			FIN_LBTB
		
		MOVE.B		(A2),D1			* D1 = caracter del buffer en la posicion de lectura
		ADD.L		#1,D0			* D0++
		
		CMP.B		#13,D1			* Si D1 == 0xD (Retorno de carro) he encontrado una linea
		BEQ			FIN_LINEA
		
		ADD.L		#1,A2			* Siguiente caracter
		
		JMP			BUCL_BTB

FIN_LBTB:

		MOVE.B		(A2),D1
		ADD.L		#1,D0			* Incrementa el contador contando el ultimo caracter del buffer
		
		CMP.B		#13,D1			* Compruebo si el ultimo caracter del buffer es el retorno de carro
		BEQ			FIN_LINEA

		MOVE.L		A1,A2			* Llevo el puntero de escritura al principio del buffer
		
		JMP			BUCL_BTB
		
RES_BTBC:

		MOVE.L		#0,D0			* D0 = 0
		
		JMP			FIN_LINEA
	

*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

************
*** SCAN ***ok
************

* SCAN(Buffer, Descriptor, Tamaño)
* Parametros: Buffer 	 --> 4B. Buffer por el que se va a devolver los caracteres que se han leido del dispositivo
*			  Descriptor --> 2B. Indica el dispositivo sobre el que se desea realizar la operacion de lectura
*							
*							  0 --> Indica que la lectura se realizara del puerto A
*							  1 --> Indica que la lectura se realizara del puerto B
*									Cualquier otro valor --> ERROR (D0 = 0xFF...F)
*			  Tamaño 	 --> 2B. Indica el numero maximo de caracteres que se deben leer del buffer 
*								  interno y copiar en el parametro buffer

SCAN:

		LINK		A6,#-20			* Se crea un marco de pila de 16B para variables locales.
		*metería un movem aquí pero no quiero jugarmela, solo tienes 3 pruebas
		MOVE.L		A1,-4(A6)		* Se almacena el valor de A1 en el marco de pila.
		MOVE.L		D1,-8(A6)		* Se almacena el valor de D1 en el marco de pila.
		MOVE.L		D2,-12(A6)		* Se almacena el valor de D2 en el marco de pila.
		MOVE.L		D3,-16(A6)		* Se almacena el valor de D3 en el marco de pila.
		MOVE.L		D4,-20(A6)		* Se almacena el valor de D4 en el marco de pila.
		
		MOVE.L		8(A6),A1		* A1 = Direccion del buffer
		MOVE.W		12(A6),D1		* D1 = Descriptor
		MOVE.W		14(A6),D2		* D2 = Tamaño
		
		CMP.W		#0,D2			* Si el tamaño es 0 entonces no hay que leer nada
		BEQ			FIN_CERO
		
		MOVE.L		#0,D3			* D3 = Contador de caracteres
		MOVE.L		#$FFFFFFFF,D4	* D4 = Posible código de error devuelto en LEECAR
		
		CMP.W		#0,D1			* Si D1 == 0 entonces se quiere leer por el puerto A
		BEQ			SCAN_PA
		
		CMP.W		#1,D1			* Si D1 == 1 entonces se quiere leer por el puerto B
		BEQ			SCAN_PB
		
		MOVE.L		D4,D0			* Si el descriptor es incorrecto hay error
		
FIN_SCAN:
		*movem
		MOVE.L		-4(A6),A1		* Se devuelve el valor del registro A1
		MOVE.L		-8(A6),D1		* Se devuelve el valor del registro D1
		MOVE.L		-12(A6),D2		* Se devuelve el valor del registro D2
		MOVE.L		-16(A6),D3		* Se devuelve el valor del registro D3
		MOVE.L		-20(A6),D4		* Se devuelve el valor del registro D4
		
		UNLK		A6				* Se destruye el marco de pila

		RTS							* Retorno
		
FIN_CERO:

		MOVE.L		#0,D0			* Se devuelve D0 = 0
		
		JMP			FIN_SCAN
		
*****************************
********** SCAN_PA **********
*****************************

SCAN_PA:

		MOVE.L		#0,D0			* Se comprueba la linea completa del buffer interno de la linea A
		
		BSR			LINEA
		
		CMP.L		#0,D0			* Si D0 == 0 entonces no hay una linea disponible
		BEQ			F_SCANPA
		
		CMP.L		D2,D0			* Si D0 > D2 entonces no se puede copiar la linea completa del BRA
		BGT			F_SCANPA
		
		MOVE.L		D0,D2			* D2 = Tamaño de la linea completa a copiar en el buffer de la linea A
		
		MOVE.L		#0,D0			* Limpio el contenido de D0

BUCL_PA:

		MOVE.L		#0,D0			* Paso el descriptor a LEECAR
		
		BSR			LEECAR
		
		*CMP.L		D0,D4			* Si D0 = 0xFF...F entonces el buffer está vacío
		*BEQ			F_SCANPA		* Termino de leer por el buffer de recepcion del puerto A (D0 = 0)
		
		ADD.L		#1,D3			* CONTC++ (Contador de caracteres)
		MOVE.B		D0,(A1)			* Se copia lo leido en el buffer de recepcion de A
		
		ADD.L		#1,A1			* Se incrementa el puntero del buffer
		
		CMP.L		D2,D3			* Si CONTC == TAM_MAX entonces se para de leer por el buffer interno de A
		BEQ			F_SCANPA
		
		JMP			BUCL_PA
		
		
F_SCANPA:

		MOVE.L		D3,D0			* Se lleva el numero de caracteres leidos al registro destino
		
		JMP			FIN_SCAN
		
*****************************
********** SCAN_PB **********
*****************************


SCAN_PB:

		MOVE.L		#1,D0			* Se comprueba la linea completa del buffer interno de la linea B
		
		BSR			LINEA
		
		CMP.L		#0,D0			* SI D0 == 0 entonces no hay una linea disponble
		BEQ			F_SCANPB
		
		CMP.L		D2,D0			* Si D0 > D2 entonces no se puede copiar la linea completa del BRB
		BGT			F_SCANPB
		
		MOVE.L		D0,D2			* D2 = tamaño de la linea completa a copiar en el buffer de la linea B
		
		MOVE.L		#0,D0			* Limpio el contenido de D0

BUCL_PB:

		MOVE.L		#1,D0			* Paso el descriptor a LEECAR
		
		BSR			LEECAR
		
		*CMP.L		D0,D4			* Si D0 = 0xFF...F entonces el buffer está vacío
		*BEQ			F_SCANPB		* Termino de leer por el buffer de recepcion de puerto B (D0 = 0)
		
		ADD.L		#1,D3			* CONTC++ (Contador de caracteres)
		MOVE.B		D0,(A1)			* Se copia lo leido en el buffer de recepcion de A
		
		ADD.L		#1,A1			* se incrementa el puntero del buffer
		
		CMP.L		D2,D3			* Si CONTC == TAM_MAX entonces se para de leer por el buffer interno de B
		BEQ			F_SCANPB
		
		JMP			BUCL_PB
		
F_SCANPB:

		MOVE.L		D3,D0			* Se lleva el numero de caracteres leidos al registro destino
		
		JMP			FIN_SCAN
******************************************FIN SCAN*********************************************************************		
		
*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

**********************************PRINT**********************************************
PRINT:

		LINK A6,#0
		MOVE.L #0,D2                            *D2 donde se guardará el descriptor
		MOVE.L #0,D3                            *D3 donde se guaradará el tamano del buffer
		MOVE.W 12(A6),D2                        *Meto el descriptor
		MOVE.L #0,D4                            *Se guardrá la información del buffer
		CMP.W #0,D2                             *En Si el decriptor es 0 
		BEQ PRNT_A                              *Voy a línea A
		CMP.W #1,D2                             *Si el descriptor es 1
		BEQ PRNT_B                              *Voy a lína B
		MOVE.L #$ffffffff,D0                    *Cualquier otro caso guardo en D0, ffffffff
		UNLK A6                             
		RTS
	
	**Si voy por A **
PRNT_A:
		MOVE.L #2,D4                            *Se mete un 2 en D4 porque accede al buffer de Trasmision de A
		BRA PRNT
PRNT_B:
		MOVE.L #3,D4                            *Se mete un 3 en D4 porque accede al buffer de Trasmision de B

PRNT:
		MOVE.L #0,D5                            *Usamos contador
		MOVE.W 14(A6),D3                        *Se guarda el tamano del buffer
		MOVE.L 8(A6),A1                         *Meto el buffer 
PRNT_BUC    
		CMP.L D5,D3                             *SI el contador y tamano son (=) termino
		BEQ PRNT_TER
		MOVE.B (A1)+,D1					        *Sacamos dato y avanzamos buffer
		MOVE.L D4,D0                            *Se mete en D0 el identificador del buffer
		BSR ESCCAR
		CMP #$ffffffff,D0                       *Si el buffer estaba vacío
		BEQ PRNT_TER
		ADD.L #1,D5                             *incremento contador
		CMP.B #13,D1                            *Compruebo el retorno de carro
		BNE PRNT_BUC                            *Si no, vuelvo con bucle
		MOVE.B #1,fPRINT                       *Uso el flag para saber si he escrito o no, aplicando concurrencia
		BRA PRNT_BUC
	
PRNT_TER:
		CMP.B #0,fPRINT                        *Si el flag no está activado termino
		BEQ PRNT_FIN                            
		MOVE.L #0,D6                            *limpieza de D6
		MOVE.W SR,D6                    		*Guardar SR para restituirlo despues 
		MOVE.W   #$2700,SR             			*Impido interrupciones 
		CMP #2,D4                       		*COmpruebo el buffer donde estoy y asi saber que bit del IMR activo 
		BEQ PRNT_ACA                    		*Salto para activatr el bit de A de IMR
		BSET #4,COPIA_IMR               		*Activo el BIT 4
		BRA PRNT_IMR
PRNT_ACA:
		BSET #0,COPIA_IMR
PRNT_IMR:
		MOVE.B COPIA_IMR,IMR
		MOVE.W D6,SR                    		*Restituimos el SR al valor que tenia previamente 
		MOVE.B #0,fPRINT               			*reseteo el flag
PRNT_FIN:
		MOVE.L D5,D0                    		*dejo el contador en d0
		UNLK A6
		RTS
 *************************FIN PRINT****************************************
*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

***************************************RTI***********************************************
	

RTI:    
		MOVEM.L D0-D4,-(A7) 	* Guarda los registros que se usan en la pila

RTI_BUC:
		MOVE.B ISR,D3
		MOVE.B COPIA_IMR,D4
		AND.B D4,D3             *Aplico la mascara 

		BTST #0,D3              *Compruebo el bit 0 de ISR despues de aplicar la máscara
		BNE RTI_T_A             *Salto a Trasmision de A si el bit estaba activado

		BTST #1,D3              *Compruebo el bit 1 de ISR despues de aplicar la máscara
		BNE RTI_R_A             *Salto a Recepcion de A si el bit estaba activado

		BTST #4,D3              *Compruebo el bit 4 de ISR despues de aplicar la máscara
		BNE RTI_T_B             *Salto a Transmision de B si el bit estaba activado

		BTST #5,D3              *Compruebo el bit 5 de ISR despues de aplicar la máscara
		BNE RTI_R_B             *Salto Recepcion de B si el bit estaba activado

FIN_RTI:
		MOVEM.L (A7)+,D0-D4 	*Restauramos los registros 
		RTE


RTI_T_A:
		CMP.B #1,flagA           *Comparo con 1 el Flag de trasmision de A (está activado)
		BNE RTI_SALA               *Si Flag != 1 salto a RTI_SALA 

		MOVE.B #10,TBA            *Pongo un salto de linea en el buffer
		MOVE.B #0,flagA         *Pongo a cero el Flag observado

		MOVE.L #2,D0               *Meto un 2 en el registro cero para hacer que linea use el Buffer de Trasmision A
		BSR LINEA   
		CMP.L #0,D0                
		BNE RTI_BUC                *Si no hay una linea se deben deshabilitar las interrupciones de Trasmision

		BCLR    #0,COPIA_IMR      *Inhibe interrupciones
		MOVE.B COPIA_IMR,IMR      *Actualizamos el IMR
		BRA RTI_BUC

RTI_SALA:
		MOVE.L #2,D0               *Meto un 2 en el registro cero para hacer que linea use el Buffer de Trasmision A 
		BSR LEECAR
		MOVE.B D0,TBA              *Meto el caracter leido en el buffer TBA

		CMP.B #13,D0               *Compara el caracter leido con el retorno de carro
		BNE RTI_BUC                *Si es un retorno de carro activo el flagA 
		MOVE.B #1,flagA
		BRA RTI_BUC

RTI_T_B:
		CMP.B #1,flagB           *Comparo con 1 el Flag de trasmision de B (está activado)
		BNE RTI_SALB               *Si Flag != 1 salto a RTI_SALB (Salto de B)

		MOVE.B #10,TBB            *Pongo un salto de linea en el buffer
		MOVE.B #0,flagB         *Pongo a cero el Flag observado

		MOVE.L #3,D0              *Meto un 3 en el registro cero para hacer que linea use el Buffer de Trasmision B
		BSR LINEA   
		CMP.L #0,D0                
		BNE RTI_BUC               *Si no hay una linea se deben deshabilitar las interrupciones de Trasmision

		BCLR #4,COPIA_IMR         *Inhibe interrupciones
		MOVE.B COPIA_IMR,IMR      *Actualizamos el IMR
		BRA RTI_BUC

RTI_SALB:
		MOVE.L #3,D0               *Meto un 3 en el registro cero para hacer que linea use el Buffer de Trasmision B 
		BSR LEECAR
		MOVE.B D0,TBB

		CMP.B #13,D0               *Compara el caracter leido con el retorno de carro
		BNE RTI_BUC                *Si es un retorno de carro activo el flagA 
		MOVE.B #1,flagB
		BRA RTI_BUC

RTI_R_A:
		MOVE.L #0,D0               *Meto un 0 en el registro cero para hacer que ESSCAR use el Buffer de recepcion A                 
		MOVE.L #0,D1               *Limpio D1 
		MOVE.B RBA,D1              *Escribo el catacter del puerto RBA en D1 para llamar a esscar 
		BSR ESCCAR
		CMP.L #-1,D0               *Si la llamada ha devuelto un 0 termino
		BEQ FIN_RTI
		BRA RTI_BUC        
RTI_R_B: 
		MOVE.L #1,D0                *Meto un 0 en el registro cero para hacer que ESSCAR use el Buffer de recepcion A  
		MOVE.L #0,D1                *Limpio D1 
		MOVE.B RBB,D1               *Escribo el catacter del puerto RBA en D1 para llamar a esscar 
		BSR ESCCAR
		CMP.L #-1,D0                *Si la llamada ha devuelto un 0 termino
		BEQ FIN_RTI
		BRA RTI_BUC
*************************** FIN RTI ************************************************************

*** ///////////////////////////////////////////////////////////////////////////////////////////// ***

CONTL:		DC.W			0			* Contador de lineas
CONTC:		DC.W			0			* Contador de caracteres
DIRLEC:		DC.L			0			* Direccion de lectura para SCAN
DIRESC:		DC.L			0			* Direccion de escritura para PRINT
TAME:		DC.W			0			* Tamaño de escritura para PRINT

DESA:		EQU				0			* Descriptor linea A
DESB:		EQU				1			* Descriptor linea B
NLIN:		EQU				10			* Numero de lineas a leer
TAML:		EQU				30			* Tamaño de lineas para SCAN
TAMB:		EQU				5			* Tamaño de bloque para PRINT


PPAL:

		MOVE.L		#$0,A0
		MOVE.L		#$0,A1
		MOVE.L		#$0,A2
		MOVE.L		#$0,A3
		MOVE.L		#$0,A4
		MOVE.L		#$0,A5
		MOVE.L		#$0,A6
		MOVE.L		#$8000,A7
		
		MOVE.L		#$0,D0
		MOVE.L		#$0,D1
		MOVE.L		#$0,D2
		MOVE.L		#$0,D3
		MOVE.L		#$0,D4
		MOVE.L		#$0,D5
		MOVE.L		#$0,D6
		MOVE.L		#$0,D7
		
INICIO:

		MOVE.L		#BUS_ERROR,8				* Bus error handler
		MOVE.L		#ADDRESS_ER,12				* Address error handler
		MOVE.L		#ILEGAL_IN,16				* Illegal instruction handler
		MOVE.L		#PRIV_VIOLT,32				* Privilege violation handler
		
		BSR			INIT						* Se pasa a inicializar todas las variables locales necesarias ademas del modo supervisor
		MOVE.W		#$2000,SR					* Permite las interrupciones
		
******************************
*** PRUEBA DE SCAN Y PRINT ***
******************************
		
*** Se insertan 500 caracteres en el buffer interno de recepcion de la linea A ***
*************************************************************************************

*		LEA			PRUEBA_SCAN,A1				* A1 = dir. inicio de PRUEBA_LC
*		
*		MOVE.L		A1,A2						* A2 = A1
*		MOVE.L		A1,A3						* A3 = A1
*		
*		ADDA.L		#20,A3						* A3 apunta al final de los caracteres de PRUEBA_SCAN
*		
*		MOVE.L		#500,D5						* D5 = 500 caracteres como maximo*		
*
*INS_CAR1:
*
*		MOVE.B		#0,D0						* Leo del buffer de recepcion de A
*		
*		CMP.L		#1,D5						* Si D5 = 1 se han transferido todos los caracteres
*		BEQ			FIN_PRUEBA
*		
*		MOVE.B		(A2),D1						* Caracter a escribir
*		
*		BSR			ESCCAR
*		
*		ADD.L		#1,A2						* Siguiente caracter
*		SUB.L		#1,D5						* D5--
*		
*		CMP.L		A2,A3						* Si A2 = A3 entonces es el final del mensaje a escribir
*		BEQ			RESTART
*		
*CONTINUA:
*		
*		CMP.L		#0,D0
*		BEQ			SUM_CONT
*
*		JMP			INS_CAR1
*		
*SUM_CONT:
*
*		ADD.W		#1,CONTC
*		
*		JMP			INS_CAR1
*		
*RESTART:
*		
*		MOVE.B		#13,D1
*		MOVE.L		#0,D0
*		
*		BSR			ESCCAR
*		
*		MOVE.L		A1,A2						* Comienza de nuevo la palabra
*		
*		JMP			CONTINUA
*		
*FIN_PRUEBA:
*
*		MOVE.L		#0,D0
*		MOVE.L		#0,A1
*		MOVE.L		#0,A2
*		MOVE.L		#0,A3
*		MOVE.L		#0,D1
*		MOVE.L		#0,D5
*		MOVE.W		#0,CONTC
	
BUCPR:

		MOVE.W		#0,CONTC					* Inicializa el contador de caracteres
		MOVE.W		#NLIN,CONTL					* Inicializa el contador de lineas
		MOVE.L		#BUFFER,DIRLEC				* Direccion de lectura = comienzo del buffer
		
OTRAL:

		MOVE.W		#TAML,-(A7)					* Tamaño maximo de la linea
		MOVE.W		#DESA,-(A7)					* Puerto A
		MOVE.L		DIRLEC,-(A7)				* Direccion de lectura
		
ESPL:

		BSR			SCAN
		
		CMP.L		#0,D0
		BEQ			ESPL
		
		ADD.L		#8,A7						* Restablece la pila
		
		ADD.L		D0,DIRLEC					* Calcula la nueva direccion de lectura
		ADD.W		D0,CONTC					* Actualiza el numero de caracteres leidos
		SUB.W		#1,CONTL					* Actualiza el numero de lineas leidas.
		
		BNE			OTRAL						* Si no se han leido todas las lineas se vuelve a leer

		MOVE.L		#BUFFER,DIRLEC				* Direccion de lectura = comienzo de buffer

OTRAE:

		MOVE.W		#TAMB,TAME					* Tamaño de escritura = Tamaño de bloque
		
ESPE:

		MOVE.W		TAME,-(A7)					* Tamaño de escritura
		MOVE.W		#DESB,-(A7)					* Puerto B
		MOVE.L		DIRLEC,-(A7)				* Direccion de lectura
		
		BSR			PRINT
		
		ADD.L		#8,A7						* Restablece la pila
		ADD.L		D0,DIRLEC					* Calcula la nueva direccion del buffer
		SUB.W		D0,CONTC					* Actualiza el contador de caracteres
		
		BEQ			SALIR						* Si no quedan caracteres se acaba
		SUB.W		D0,TAME						* Actualiza el tamaño de escritura
		BNE			ESPE						* Si no se ha escrito todo el bloque se insiste
		
		CMP.W		#TAMB,CONTC					* Si el nº de caracteres que quedan es menor que el 
												* tamaño establecido se transmite ese numero
												
		BHI			OTRAE						* Siguiente bloque
		
		MOVE.W		CONTC,TAME
		
		BRA			ESPE						* Siguiente bloque
		
SALIR:

		BRA			BUCPR
		
FIN:

		BREAK

*********************************
*** PRUEBA DE ESCCAR Y LEECAR ***
*********************************
*		
*		LEA			PRUEBA_LC,A1				* A1 = dir. inicio de PRUEBA_LC
*		
*		MOVE.L		A1,A2						* A2 = A1
*		MOVE.L		A1,A3						* A3 = A1
*		
*		ADDA.L		#10,A3						* A3 apunta al final de los caracteres de PRUEBA_LC
*		
*		MOVE.L		#2000,D5					* D5 = 2000 caracteres como maximo
*		
*** Se insertan 2000 caracteres en el buffer interno de transmision de la linea B ***
*************************************************************************************
*INS_CAR1:
*
*		MOVE.B		#3,D0						* Leo del buffer de transmision de B
*		
*		CMP.L		#0,D5						* Si D5 = 0 se han transferido todos los caracteres
*		BEQ			FIN_PRUEBA
*		
*		MOVE.B		(A2),D1						* Caracter a escribir
*		
*		BSR			ESCCAR
*		
*		ADD.L		#1,A2						* Siguiente caracter
*		SUB.L		#1,D5						* D5--
*		
*		CMP.L		A2,A3						* Si A2 = A1 entonces es el final del mensaje a escribir
*		BEQ			RESTART
*		
*CONTINUA:
*		
*		CMP.L		#0,D0
*		BEQ			SUM_CONT
*
*		JMP			INS_CAR1
*		
*SUM_CONT:
*
*		ADD.W		#1,CONTC
*		
*		JMP			INS_CAR1
*		
*RESTART:
*
*		MOVE.L		A1,A2						* Comienza de nuevo la palabra
*		
*		JMP			CONTINUA
*		
*FIN_PRUEBA:
*
*		MOVE.L		#0,D0
*		MOVE.L		#0,A1
*		MOVE.L		#0,A2
*		MOVE.L		#0,A3
*		MOVE.L		#0,D1
*		MOVE.L		#0,D5
*		MOVE.W		#0,CONTC
*		
*** Se leen 1000 caracteres del buffer interno de transmision de la linea B ***
*******************************************************************************
*
*		MOVE.L		#1000,D5
*
*LEE_CAR1:
*
*		MOVE.L		#3,D0						* Leo del buffer de transmision de B
*
*		CMP.L		#0,D5
*		BEQ			FIN_LEE1
*		
*		BSR			LEECAR
*		
*		SUB.L		#1,D5
*		
*		CMP.L		#$FFFFFFFF,D0
*		BNE			SUM_LEE1
*		
*		JMP			LEE_CAR1
*	
*SUM_LEE1:
*
*		ADD.W		#1,CONTC
*		
*		JMP			LEE_CAR1
*		
*FIN_LEE1:
*	
*		MOVE.L		#0,D0
*		MOVE.L		#0,D5
*		MOVE.W		#0,CONTC
*		
*** Se insertan 1000 caracteres en el buffer interno de transmision de la linea B ***
*************************************************************************************
*
*		MOVE.L		#1000,D5					* INSERTO 1000 CARACTERES
*		
*		LEA			PRUEBA_LC,A1				* A1 = dir. inicio de PRUEBA_LCQ
*		
*		MOVE.L		A1,A2						* A2 = A1
*		MOVE.L		A1,A3						* A3 = A1
*		
*		ADDA.L		#10,A3						* A3 apunta al final de los caracteres de PRUEBA_LC
*		
*INS_CAR2:
*
*		MOVE.B		#3,D0
*		
*		CMP.L		#0,D5						* Si D5 = 0 se han transferido todos los caracteres
*		BEQ			FIN_INS2
*		
*		MOVE.B		(A2),D1						* Caracter a escribir
*		
*		BSR			ESCCAR
*		
*		ADD.L		#1,A2						* Siguiente caracter
*		SUB.L		#1,D5						* D5--
*		
*		CMP.L		A2,A3						* Si A2 = A3 entonces es el final del mensaje a escribir
*		BEQ			RESTART2
*		
*CONT2:
*		
*		CMP.L		#0,D0
*		BEQ			SUM_CON2
*
*		JMP			INS_CAR2
*		
*SUM_CON2:
*
*		ADD.W		#1,CONTC
*		
*		JMP			INS_CAR2
*		
*RESTART2:
*
*		MOVE.L		A1,A2						* Comienza de nuevo la palabra
*		
*		JMP			CONT2
*		
*FIN_INS2:
*
*		MOVE.L		#1,D0						* Salto al buffer de recepcion de la linea B
*		
*		BSR			LINEA
*
*		MOVE.L		#0,A1
*		MOVE.L		#0,A2
*		MOVE.L		#0,A3
*		MOVE.L		#0,D1
*		MOVE.L		#0,D5
*		MOVE.W		#0,CONTC
*		
*		
*** Se leen 1500 caracteres del buffer interno de transmision de la linea B ***
*******************************************************************************
*
*		MOVE.L		#1500,D5
*
*LEE_CAR2:
*
*		CMP.L		#0,D5
*		BEQ			FIN_LEE2
*
*		MOVE.L		#3,D0						* Leo del buffer de transmision de B
*		
*		BSR			LEECAR
*		
*		SUB.L		#1,D5
*		
*		CMP.L		#$FFFFFFFF,D0
*		BNE			SUM_LEE2
*		
*		JMP			LEE_CAR2
*		
*SUM_LEE2:
*
*		ADD.W		#1,CONTC
*		
*		JMP			LEE_CAR2
*		
*FIN_LEE2:
*	
*		MOVE.L		#0,D0
*		MOVE.L		#0,D5
*		MOVE.W		#0,CONTC
	
BUS_ERROR:

		BREAK
		NOP
		
ADDRESS_ER:

		BREAK
		NOP
		
ILEGAL_IN:

		BREAK
		NOP
		
PRIV_VIOLT:

		BREAK
		NOP