/* ELEC334 Microprocessor Midterm Project 1
 *
 * Fatma Nisa MERCAN
 * 1801022004
 * f.mercan2018@gtu.edu.tr
 */


.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb

/* make linker see this */
.global Reset_Handler

/* get these from linker script */
.word _sdata
.word _edata
.word _sbss
.word _ebss


/* define peripheral addresses */
.equ RCC_BASE,			(0x40021000)			// RCC base address
.equ RCC_IOPENR,		(RCC_BASE   + (0x34))	// RCC IOPENR register with offset

.equ GPIOA_BASE,		(0x50000000)			// GPIOA base address
.equ GPIOA_MODER,		(GPIOA_BASE + (0x00))	// GPIOA MODER register offset
.equ GPIOA_ODR,			(GPIOA_BASE + (0x14))	// GPIOA ODR register offset
.equ GPIOA_IDR,			(GPIOA_BASE + (0x10))	// GPIOA IDR register offset

.equ GPIOB_BASE,		(0x50000400)			// GPIOB base address
.equ GPIOB_MODER,		(GPIOB_BASE + (0x00))	// GPIOB MODER register offset
.equ GPIOB_ODR,			(GPIOB_BASE + (0x14))	// GPIOB ODR register offset
.equ GPIOB_IDR,			(GPIOB_BASE + (0x10))


/* the random number */
.equ DIGIT_1,	(0x3)
.equ DIGIT_2,	(0x6)
.equ DIGIT_3,	(0x5)
.equ DIGIT_4,	(0x1)


/* vector table, +1 thumb mode */
.section .vectors
vector_table:
	.word _estack             /*     Stack pointer */
	.word Reset_Handler +1    /*     Reset handler */
	.word Default_Handler +1  /*       NMI handler */
	.word Default_Handler +1  /* HardFault handler */
	/* add rest of them here if needed */


/* reset handler */
.section .text
Reset_Handler:
	/* set stack pointer */
	ldr r0, =_estack
	mov sp, r0

	/* initialize data and bss
	 * not necessary for rom only code
	 * */
	bl init_data
	/* call main */
	bl main
	/* trap if returned */
	b .


/* initialize data and bss sections */
.section .text
init_data:

	/* copy rom to ram */
	ldr r0, =_sdata
	ldr r1, =_edata
	ldr r2, =_sidata
	movs r3, #0
	b LoopCopyDataInit

	CopyDataInit:
		ldr r4, [r2, r3]
		str r4, [r0, r3]
		adds r3, r3, #4

	LoopCopyDataInit:
		adds r4, r0, r3
		cmp r4, r1
		bcc CopyDataInit

	/* zero bss */
	ldr r2, =_sbss
	ldr r4, =_ebss
	movs r3, #0
	b LoopFillZerobss

	FillZerobss:
		str  r3, [r2]
		adds r2, r2, #4

	LoopFillZerobss:
		cmp r2, r4
		bcc FillZerobss

	bx lr


/* default handler */
.section .text
Default_Handler:
	b Default_Handler


/* main function */
.section .text
main:

	/* enable GPIOA and GPIOB clock, bit0 and bit1 on IOPENR */
	ldr r6, =RCC_IOPENR
	ldr r5, [r6]
	movs r4, 0x3
	orrs r5, r5, r4
	str r5, [r6]

	/* setup PA4, PA5, PA6, PA7 for d1, d2, d3, d4 of 7seg with bits in MODER */
	ldr r6, =GPIOA_MODER
	ldr r5, [r6]
	ldr r4, =0xFF00
	mvns r4, r4
	ands r5, r5, r4
	ldr r4, =0x5500
	orrs r5, r5, r4
	str r5, [r6]
	/* setup bit1-0 as input mode for button */
	ldr r4, =0x0003
	mvns r4, r4
	ands r5, r5, r4
	str r5, [r6]

	/* setup PA1 for external LED with bits in MODER */
	ldr r6, =GPIOA_MODER
	ldr r5, [r6]
	ldr r4, =0xC
	mvns r4, r4
	ands r5, r5, r4
	ldr r4, =0x4
	orrs r5, r5, r4
	str r5, [r6]


button_ctrl:

	/* control the button to start generate random number */
	ldr r6, =GPIOA_IDR
	ldr r5, [r6]
	movs r4, #0x1
	ands r5, r5, r4

	cmp r5, #0x1
	beq buttonOn
	bne buttonOff


buttonOff:

	/* counting is not in progress, turn on the LED */
	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	movs r4, 0x2
	orrs r5, r5, r4
	str r5, [r6]

	movs r0, 0x2
	movs r1, 0x0
	movs r2, 0x0
	movs r3, 0x4

	/* idle state, ID is shown in SSD */
	bl d1
	bl d2
	bl d3
	bl d4

	b button_ctrl

buttonOn:

	movs r0, DIGIT_1
	movs r1, DIGIT_2
	movs r2, DIGIT_3
	movs r3, DIGIT_4

countdown:
	/* countdown is started, turn off the LED */
	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x2
	mvns r4, r4
	ands r5, r5, r4
	str r5, [r6]

	/* Nested loop for countdown the digits */
	a: // 1st digit
		b: // 2nd digit
			c: // 3rd digit
				d: // 4th digit
					subs r3, #1
					bl isButtonStillPressed // check if button is still pressed
					bl d1
					bl d2
					bl d3
					bl d4
					cmp r3, #0
					bge d

			movs r3, #9
			subs r2, #1
			bl d3
			cmp r2, #0
			bge c

		movs r2, #9
		subs r1, #1
		bl d2
		cmp r1, #0
		bge b

	movs r1, #9
	subs r0,  #1
	bl d1
	cmp r0, #0
	bne a
	beq display


	isButtonStillPressed:

		/* control the button for resume or pause */
		ldr r6, =GPIOA_IDR
		ldr r5, [r6]
		movs r4, #0x1
		ands r5, r5, r4

		cmp r5, #0x1
		bne pause
		bx lr

		pause:
				/* counting is not in progress, turn on the LED */
				ldr r6, =GPIOA_ODR
				ldr r5, [r6]
				movs r4, 0x2 //0010
				orrs r5, r5, r4
				str r5, [r6]

				/* check if there is input for counting to resume */
				ldr r6, =GPIOA_IDR
				ldr r5, [r6]
				movs r4, #0x1
				ands r5, r5, r4

				cmp r5, #0x1
				bne pause
				bx lr

		display:

				/* counting is not in progres, turn the LED on */
				ldr r6, =GPIOA_ODR
				ldr r5, [r6]
				movs r4, 0x2 //0010
				orrs r5, r5, r4
				str r5, [r6]

			/* counting is reached 0, now show 0000 */

				/* setup PB0-5 for 7seg A to F for bits in MODER */
				ldr r6, =GPIOB_MODER
				ldr r5, [r6]
				bics r5, r5
				ldr r4, =0x0555
				orrs r5, r5, r4
				str r5, [r6]

				/* turn on all digits PB0-5*/
				ldr r6, =GPIOB_ODR
				ldr r5, [r6]
				movs r4, 0xC0
				ands r5, r5, r4
				str r5, [r6]

				/* turn on d1-d2-d3-d4 */
				ldr r6, =GPIOA_ODR
				ldr r5, [r6]
				movs r4, 0xF0
				orrs r5, r5, r4
				str r5, [r6]

			ldr r7, =#3200000 //0000 just for 1 second
			b delay1
			delay1:
				subs r7, #1
				cmp r7, #0
				bne delay1

			/* get back to idle state */
				movs r0, 0x2
				movs r1, 0x0
				movs r2, 0x0
				movs r3, 0x4

				bl d1
				ldr r7, =#100000
				b delay2

				bl d2
				ldr r7, =#100000
				b delay2

				bl d3
				ldr r7, =#100000
				b delay2

				bl d4
				ldr r7, =#6000000
				b delay2

			delay2:
				subs r7, #1
				cmp r7, #0
				bne delay2

			b button_ctrl



/* How to display the numbers in SSD */

	/* 1- Choose the digit */

	d1:
		movs r7, r0

		/* turn on d1 connected to A6 in ODR*/
		ldr r6, =GPIOA_ODR
		ldr r5, [r6]
		bics r5, r5
		movs r4, 0x10 //0001_0000
		orrs r5, r5, r4
		str r5, [r6]

		b cmpDigits



	d2:
		movs r7, r1

		/* turn on d2 connected to A6 in ODR*/
		ldr r6, =GPIOA_ODR
		ldr r5, [r6]
		bics r5, r5
		movs r4, 0x20 //0010_0000
		orrs r5, r5, r4
		str r5, [r6]

		b cmpDigits



	d3:
		movs r7, r2

		/* turn on d2-d3 connected to A6 in ODR*/
		ldr r6, =GPIOA_ODR
		ldr r5, [r6]
		bics r5, r5
		movs r4, 0x40 //0100_0000
		orrs r5, r5, r4
		str r5, [r6]

		b cmpDigits



	d4:
		movs r7, r3

		/* turn on d4 connected to A6 in ODR*/
		ldr r6, =GPIOA_ODR
		ldr r5, [r6]
		bics r5, r5
		movs r4, 0x80 //1000_0000
		orrs r5, r5, r4
		str r5, [r6]

		b cmpDigits



	/* 2- Find the number by comparing  */

	cmpDigits:
		cmp	r7, #0
		beq ssd0

		cmp r7, #1
		beq ssd1

		cmp r7, #2
		beq ssd2

		cmp r7, #3
		beq ssd3

		cmp r7, #4
		beq ssd4

		cmp r7, #5
		beq ssd5

		cmp r7, #6
		beq ssd6

		cmp r7, #7
		beq ssd7

		cmp r7, #8
		beq ssd8

		cmp r7, #9
		beq ssd9



	/* 3- Go to implementation of the number*/

	ssd0:
		ldr r7, =#1000

		/* 0: 0,1,2,3,4,5 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x0555 //0000_0101_0101_0101
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd1:
		ldr r7, =#1000

		/* 1: 1,2 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x0014 //0000_0000_0001_0100
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd2:
		ldr r7, =#1000

		/* 2: 0,1,3,4,6 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x1145 //0001_0001_0100_0101
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd3:
		ldr r7, =#1000

		/*3: 0,1,2,3,6 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x1055 //0001_0000_0101_0101
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd4:
		ldr r7, =#1000

		/*4: 1,2,5,6*/
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x1414 //0001_0100_0001_0100
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd5:
		ldr r7, =#1000

		/*5: 0,2,3,5,6 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x1451 //0001_0100_0101_0001
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd6:
		ldr r7, =#1000

		/*6: 0,2,3,4,5,6 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x1551 //0001_0101_0101_0001
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd7:
		ldr r7, =#1000

		/* 7: 0,1,2 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x0015 //0000_0000_0001_0101
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd8:
		ldr r7, =#1000

		/*8: 0,1,2,3,4,5,6 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x1555 //0001_0101_0101_0101
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	ssd9:
		ldr r7, =#1000

		/*9: 0,1,2,3,5,6 */
		ldr r6, =GPIOB_MODER
		ldr r5, [r6]
		bics r5, r5
		ldr r4, =0x1455 //0001_0100_0101_0101
		orrs r5, r5, r4
		str r5, [r6]
		b delay

	delay:
		subs r7, #1
		cmp r7, #0
		bne delay
		bx lr


	/* for(;;); */
	b .

	/* this should never get executed */
	nop
