TITLE Low-Level I/O   (assignment6.asm)

; Author: Brian Rud
; Last Modified: 6/8/2020
; OSU email address: rudb@oregonstate.edu
; Course number/section: CS271/400
; Project Number: 6				            Due Date: 6/8/2020

; Description: A program that implements low-level I/O procedures.  Gets
; strings from users and converts to signed integers while performing data
; validation, and converts signed integers to strings to display on the 
; console.  Includes a small test program to get 10 integers from the user
; and display them along with their sum and average.

INCLUDE Irvine32.inc

;---------------------------------------------------------------------------
mGetString	MACRO mStringToRead
; 
; Reads a user entered string into the block of memory pointed to 
; by mStringToRead
;
; Receives: mStringToRead: The offset of the block of memory in which to store
;                          the user's input.
;
;---------------------------------------------------------------------------
	mov		edx, mStringToRead
	mov		ecx, 20
	call	ReadString

ENDM

;---------------------------------------------------------------------------
mDisplayString	MACRO mStringToWrite
;
; Writes a string with to the console.
;
; Receives: mStringToWrite = reference to a zero terminated string
;---------------------------------------------------------------------------

	mov		edx, mStringToWrite
	call	WriteString

ENDM

.data
 
	intro1					BYTE	"Programming Assignment 6: Designing low-level I/O procedures",13, 10,  0							
	intro2					BYTE	"Programmed by Brian Rud", 13, 10 ,13, 10, 0	
	intro3					BYTE	"Please provide 10 signed decimal integers", 13, 10,
									"Each number needs to be small enough to fit inside a 32-bit register." , 13, 10,
									"After you have finished inputting the raw numbers, I will display a list",13,10,
									"of the integers, their sum, and thier average value.",13,10, 13, 10,0
	promptForInteger1		BYTE	"Please enter a signed number: ", 0
	promptForInteger2		BYTE	"Please try again: ", 0
	userEnteredInteger		SDWORD	0
	userEnteredString		BYTE	20 DUP(?)
	
	;isValidDigit			DWORD	0
	;multiplicationFactor	DWORD	1
	;charToConvert			DWORD	'a'
	error					BYTE	"ERROR: You did not enter a signed number, or your number was too big", 13, 10, 0
	farewell_string			BYTE	"Results certified by Brian.  Thanks for using this program! Goodbye.",13,10,13,10, 0
	integerToPrint			BYTE	30 DUP(?)
	userIntegerArray		DWORD	10 DUP(?)
	displayNumberString		BYTE	13,10, "You entered the following numbers:",13,10,0
	sumString				BYTE	13,10, "The sum of these numbers is: ", 0
	arraySum				DWORD	0
	averageString			BYTE	13, 10, "The rounded average is: ", 0

.code

main PROC
	
	; print out the introduction strings
	push	OFFSET intro1
	push	OFFSET intro2
	push	OFFSET intro3
	call	introduction
	
	; fill userIntegerArray with integers that the user enters into the console
	push	LENGTHOF userIntegerArray
	push	OFFSET userIntegerArray
	push	OFFSET userEnteredString
	push	OFFSET userEnteredInteger
	push	OFFSET promptForInteger1
	push	OFFSET promptForInteger2
	push	OFFSET error
	call	fillIntegerArray
	
	; print a title prior to displaying the numbers that the user entered
	mov		edx, OFFSET displayNumberString
	call	WriteString

	; display the numbers that the users entered
	push	LENGTHOF	userIntegerArray
	push	OFFSET		userIntegerArray
	push	OFFSET		integerToPrint
	call	displayIntegerArray

	; print a title prior to calculatong adn displaying the sum of the 
	; numbers the user entered
	mov		edx, OFFSET sumString
	call	WriteString

	; calculate the sum of the numbers that the user entered
	push	OFFSET		userIntegerArray
	push	LENGTHOF	userIntegerArray
	push	OFFSET		arraySum
	call	sumArray

	; display the sum of the numbers that the user entered
	mov		eax, arraySum
	call	WriteInt

	; print a title prior to calculating and displaying the average 
	mov		edx, OFFSET averageString
	call	WriteString

	; calculate and display the average
	mov		eax, arraySum
	cdq
	mov		ebx, LENGTHOF userIntegerArray
	idiv	ebx
	call	WriteInt
	
	call	CrLf
	call	CrLf
	
	; print a goodby message
	mov		edx, OFFSET farewell_string
	call	WriteString

	exit	; exit to operating system

main ENDP

;---------------------------------------------------------------------------
introduction PROC
;
; A procedure to display the program title and author.
;
; receives:
;	[ebp + 16] = reference to the first string to be printed
;	[ebp + 12] = reference to the second string to be printed
;	[ebp + 8]  = reference to the third string to be printed
;---------------------------------------------------------------------------
	; setup stack frame, save registers
	push	ebp
	mov		ebp, esp
	pushad

	; print first string
	mDisplayString [ebp + 16]

	; print second string
	mDisplayString [ebp + 12]

	; print third string
	mDisplayString [ebp + 8]

	; clean up stack frame, restore registers
	popad
	pop		ebp
	ret		12

introduction ENDP

;---------------------------------------------------------------------------
fillIntegerArray PROC
;
; A procedure that gets a signed integer from the user in string format,
; converts it to an integer (while validating that it is a valid 32-bit
; signed integer) and stores the resulting integer as an element of a
; DWORD array passed to the procedure.  The procedure loops through until
; the entire array has been filled with valid 32-bit signed integers.
;
; receives:
;   
;	 [ebp + 32] = Size of the DWORD array that will store the user entered ints
;	 [ebp + 28] = Reference to the DWORD array that will store the user entered ints
;	 [ebp + 24] = Reference to the block of memory that the user entered
;					string will be stored.
;	
;	 [ebp + 20] = Reference to the variable where the integer will be stored
;	 [ebp + 16] = Reference to string prompting users to enter an integer
;	 [ebp + 12] = Reference to string prompting users to enter an integer after
;         they have entered one incorrectly
;	 [ebp + 8]  = Reference to string with error message for entering an invalid number
;
;               
;---------------------------------------------------------------------------
	
	; set up the stack frame and save registers
	push	ebp
	mov		ebp, esp

	push eax
	push ecx
	push edi

	; setup loop to loop over the array of DWORD signed integers to be filled
	mov		ecx, [ebp + 32]
	mov		edi, [ebp + 28]
	
getUserIntegersLoop:
	
	mov		ebx, [ebp + 20]
	mov		eax, 0
	mov		[ebx], eax

	; get a string from the user, convert it to an integer, and store the integer
	; in [ebp + 20]
	push	[ebp + 24]
	push	[ebp + 20]
	push	[ebp + 16]
	push	[ebp + 12]
	push	[ebp + 8]
	call	readVal

	; move the integer returned from readVal in [ebp + 20] to the next element in the 
	; array referenced at [ebp + 28]
	mov		esi, [ebp + 20]
	mov		eax, [esi]
	cld
	stosd

	loop	getUserIntegersLoop

	;restore variables, clean up stack
	pop		edi
	pop		ecx
	pop		eax

	pop		ebp
	ret		28

fillIntegerArray ENDP

;---------------------------------------------------------------------------
displayIntegerArray PROC
;
; A procedure that displays the values of an array of signed integers, 
; separated by a comma.
;
; receives:
;   
;	 [ebp + 16] = Size of the DWORD array that will store the user entered ints
;	 [ebp + 12] = Reference to the DWORD array that will store the user entered ints
;	 [ebp + 8] = Reference to a string buffer that will store the string to be printed
;
;               
;---------------------------------------------------------------------------
	; set up stack frame, save registers
	push	ebp
	mov		ebp, esp

	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	; set up to loop over the array of signed integers
	mov		esi, [ebp + 12]
	mov		ecx, [ebp + 16]

displayIntegerLoop:

	; send the next value in the array of signed integers to 
	; writeVal to be printed to the screen
	push	[esi]
	push	[ebp + 8]
	call	writeVal
	
	; print a comma/space (unless you have just printed the last value in the 
	; array)
	cmp		ecx, 1
	je		dontPrintComma
	mov		al, ','
	call	WriteChar
	mov		al, ' '
	call	WriteChar

dontPrintComma:
	
	add		esi, 4
	loop	displayIntegerLoop

	; clean up stack frame, restore registers
	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax

	pop		ebp
	ret		16

displayIntegerArray ENDP

;---------------------------------------------------------------------------
readVal PROC
;
; A procedure that gets a signed integer from the user in string format,
; converts it to an integer (while validating that it is a valid 32-bit
; signed integer) and stores the resulting integer in a memory address
;
; receives:
;   
;	 [ebp + 24] = Reference to the block of memory that the user entered
;					string will be stored.
;	
;	 [ebp + 20] = Reference to the variable where the integer will be stored
;	 [ebp + 16] = Reference to string prompting users to enter an integer
;	 [ebp + 12] = Reference to string prompting users to enter an integer after
;         they have entered one incorrectly
;	 [ebp + 8]  = Reference to string with error message for entering an invalid number
;
;               
;---------------------------------------------------------------------------
	
	; set up stack frame save registers
	push	ebp
	mov		ebp, esp
	sub		esp, 12

	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi

	
	; initialize local variables
	multiplicationFactor EQU DWORD PTR [ebp - 4]
	sign				 EQU DWORD PTR [ebp - 8]
	stringLength		 EQU DWORD PTR [ebp - 12]
	
	mov	multiplicationFactor, 1
	mov	sign, 0

	; display a prompt to the user to enter a signed integer
askForInteger:
	
	mDisplayString [ebp + 16]
	jmp getStringFromUser

	; display a prompt to the user to enter a signed integer 
	; this prompt is used if the user entered an invalid integer
askForIntegerAgain:

	mDisplayString [ebp + 12]

getStringFromUser:	

	mGetString	[ebp + 24]
	mov		stringLength, eax
	
	; check to see if the user entered a negative number, if so, set multiplicationFactor to -1
checkSign:

	mov		esi, [ebp + 24]
	cld		
	lodsb
	cmp		eax, 45
	jne		setupForLoop
	mov		sign, 1
	mov		multiplicationFactor, -1

	; point esi to the last element of the string entered by the user. point edi
	; to the variable where the integer will be stored once it is converted.
setupForLoop:

	mov		esi, [ebp + 24]
	mov		edi, [ebp + 20]
	mov		ecx, stringLength
	; check if length of string is obviously too long
	mov		eax, stringLength
	dec		eax
	add		esi, eax

LoopThroughCharacters:
	
	; loop through the string in reverse order, loading each character into eax
	std
	mov		eax, 0
	lodsb

	; subtract 48 from eax to get the decimal digit correspoinding to the ASCII code
	sub		eax, 48
	
	; If the result is greater than 9, it is not a digit
	cmp		eax, 9
	jg		invalidEntry

	; If the result is less than 0, it is not a digit but we still need to check 
	; if it is a + or - located in the first character of the user entered string.
	cmp		eax, 0
	jl		checkNonDigit

	; multiply the digit by the multiplication factor (1, 10, 100 etc.) and add
	; to the total
	mov		ebx, multiplicationFactor
	imul	ebx
	add		[edi], eax
	jo		invalidEntry
	
	; multiply the multiplication factor by 10
	mov		eax, 0
	mov		eax, multiplicationFactor
	mov		ebx, 10
	imul	ebx
	mov		multiplicationFactor, eax

	loop	LoopThroughCharacters
	jmp		done
	
checkNonDigit:
	; check that we are on the first element of the string entered by the user.
	; a + or - anywhere else is invalid.
	cmp		ecx, 1
	jne		invalidEntry

	; check if the current character is a '+'
	cmp		eax, -5
	je		gotSign
	
	; check if the current character is a '-'.  If not, the entry is invalid
	; if it is, set sign, to 1 and continue processing the number.
	cmp		eax, -3
	jne		invalidEntry
	mov		sign, 1

gotSign:
	jmp		done
	
invalidEntry:
	
	; reset the userEnteredInteger
	mov		eax, 0
	mov		ebx, [ebp + 20]
	mov		[ebx], eax

	; reset multiplicationFactor
	mov		eax, 1
	mov		multiplicationFactor, eax

	mDisplayString	[ebp + 8]
	jmp		askForIntegerAgain
	
	; clean up stack frame, restore registers.
done:	

	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax

	mov		esp, ebp
	pop		ebp
	ret		20


readVal ENDP

;---------------------------------------------------------------------------
writeVal PROC 
;
; A procedure that stores a signed integer as a zero terminated string
; and writes the string to the console.
;
; receives:
;		[ebp + 12] = signed integer value to be displayed on the conosle
;		[ebp + 8] = reference to a string containing the farewell message to
;                the user.
;---------------------------------------------------------------------------
	
	; set up stack frame, save registers
	push	ebp
	mov		ebp, esp
	sub		esp, 16

	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi

	mov		eax, [ebp + 12]
	mov		edi, [ebp + 8]

	; initialize local variables
	sign			EQU DWORD PTR [ebp - 4]
	quotient		EQU DWORD PTR [ebp - 8]
	stringLength	EQU DWORD PTR [ebp - 12]
	index_a			EQU	DWORD PTR [ebp - 16]
	
	mov		quotient, eax
	mov		sign, 0
	mov		stringLength, 0
	mov		index_a, 0

	; check if the number is negative, if so negate it and set sign to 1
checkSign:
	
	cmp eax, 0
	jge processInteger

numberIsNegative:
	
	neg		eax
	mov		quotient, eax
	mov		sign, 1
	inc		stringLength

processInteger:
	
	; divide the integer by 10
	cld
	mov		edx, 0
	mov		eax, quotient
	mov		ebx, 10
	div		ebx
	mov		quotient, eax

	; add 48 to the remainder to get the ASCII code for the digit and store 
	; the result in the string to be printed to the screen
	add		edx, 48
	mov		eax, edx
	stosb
	
	; set up for the next iteration.  If the result of the division is 0
	; we are done
	inc		stringLength
	cmp		quotient, 0
	jne		processInteger
	
	cmp		sign, 1
	jne		reverseString

addMinusSign:
	
	mov		al, '-'
	stosb
	
	; the string is in reverse order, we need to reverse it to get it in the 
	; right order.
reverseString:
	;point esi to the beginning of the string
	mov		esi, [ebp + 8]
	
	; point edi to the end of the string
	mov		edi, esi
	mov		eax, stringLength
	dec		eax
	add		edi, eax
	
	; if the length of the string is 1, we do not need to reverse the string, otherwise
	; set ecx to length of the string divided by two
	mov		eax, stringLength
	cmp		eax, 1
	je		displayInteger
	mov		ebx, 2
	mov		edx, 0
	div		ebx
	mov		ecx, eax

reverseStringLoop:

	; swap the first and last characters, second and second to last characters etc.
	mov		al, [esi]
	mov		bl, [edi]
	mov		[esi], bl
	mov		[edi], al
	
	; move esi and edi index_a characters toward the middle of the string
	inc		esi
	dec		edi
	
	loop	reverseStringLoop

displayInteger:	
	
	; terminate the string with a 0
	mov		edi, [ebp + 8]
	mov		eax, stringLength
	add		edi, eax
	mov		al, 0
	stosb

	mDisplayString [ebp + 8]
	
	; clean up stack frame, restore registers
	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
		
	mov	esp, ebp
	pop ebp
	ret 8

writeVal ENDP

;---------------------------------------------------------------------------
sumArray PROC
;
; A procedure that sums the elements in an array of signed integers
;
; receives:
;		[ebp + 16] = Reference to the array of signed integers to be summed
;		[ebp + 12] = The number of elements in the array
;		[ebp + 8]  = Reference to the variable in which to store the sum
;---------------------------------------------------------------------------
	
	; set up stack frame, save registers
	push	ebp
	mov		ebp, esp

	push	eax
	push	ecx
	push	edi
	push	esi

	mov		ecx, [ebp + 12]		; number of elements in array
	mov		esi, [ebp + 16]		; reference to array
	mov		edi, [ebp + 8]		; reference to variable in whcih to store the sum
	
	mov		eax, 0				; eax will store the sum
	
	
	; loop over elements of the array, adding each one to the sum in eax

addElementsLoop:
	add		eax, [esi]
	add		esi, TYPE DWORD
	loop	addElementsLoop

	; store the sum in [edi]
	stosd
	
	; clean up stack frame, restore registers
	pop		esi
	pop		edi
	pop		ecx
	pop		eax

	pop		ebp
	ret		12

sumArray ENDP

;---------------------------------------------------------------------------
farewell PROC
;
; A procedure to print a farewell message to the user
;
; receives:
;    [ebp + 8] = reference to a string containing the farewell message to
;                the user.
;---------------------------------------------------------------------------
	; setup stack frame, save registers
	push	ebp
	mov		ebp, esp
	pushad

	; print farewell string
	mov		edx, [ebp + 8]
	call	WriteString
	call	CrLf

	; clean up stack frame, restore registers
	popad
	pop		ebp
	ret		4

farewell ENDP

END main