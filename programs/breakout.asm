.NOLIST
#include "ti83plus.inc"

;AppBackUpScreen = 9872
#DEFINE PaddleWidth 24
#DEFINE PaddleHeight 4
#DEFINE BrickWidth 11
#DEFINE BrickHeight 6
#DEFINE BrickStartY 10

.LIST
    .org 9D93h
    .db $BB,$6D
    
; Brick data
brickFirstRow = AppBackupScreen

ProgramStart:
    ; Initialize variables
    LD A, (96 / 2) - (PaddleWidth / 2)
    LD (paddleX), A
    LD A, 60
    LD (paddleY), A
    LD A, 45
    LD (ballX), A
    LD A, 56
    LD (ballY), A
    LD A, 1
    LD (ballVelocityX), A
    LD A, -1
    LD (ballVelocityY), A
    LD A, 0
    LD (drawBricksCol), A
    LD A, BrickStartY
    LD (drawBricksRow), A
    LD A, 32
    LD (bricksLeft), A

    ; Initialize the bricks
    LD A, $FF
    LD (brickFirstRow), A
    LD (brickFirstRow + 1), A
    LD (brickFirstRow + 2), A
    LD (brickFirstRow + 3), A

    ; Draw the first frame
    CALL cls
    CALL DrawBricks
	; Draw ball
	LD A, (ballY)
	LD L, A
	LD A, (ballX)
    CALL DrawBall	
    bcall(_GrBufCpy)
	; Draw Paddle
	LD A, (paddleY)
	LD L, A
    LD A, (paddleX)
    LD B, PaddleWidth
    LD C, PaddleHeight
    CALL DrawRectangle
	
    JP UpdateBall

MainLoop:
    ; Check for input
    LD A, $FE ; Left, and Right are in group FE
    OUT (1), A
    NOP
    NOP
    IN A, (1)
    BIT 2, A ; If right was pressed.
    JR Z, RightPressed
    BIT 1, A; If left was pressed.
    JR Z, LeftPressed
    LD A, $FD ; Clear is in group FD
    OUT (1), A
    NOP
    NOP
    IN A, (1)
    BIT 6, A ; If clear was pressed.
    JR Z, ClearPressed
    ; If nothing was pressed, no need to update paddle
    JR UpdateBall

    ; Right arrow moves right
RightPressed:
    ; Clear previous paddle
    LD A, (paddleY)
    LD L, A
    LD A, (paddleX)
    LD B, PaddleWidth
    LD C, PaddleHeight
    CALL DrawRectangle

    LD A, (paddleX)
    ; Make sure the paddle doesn't go beyond the right side
    CP 96 - PaddleWidth
    JR Z, DrawPaddle
    INC A
    INC A
    LD (paddleX), A
    JR DrawPaddle

    ; Left arrow moves left
LeftPressed:
    ; Clear previous paddle
    LD A, (paddleY)
    LD L, A
    LD A, (paddleX)
    LD B, PaddleWidth
    LD C, PaddleHeight
    CALL DrawRectangle

    LD A, (paddleX)    
    ; Make sure the paddle doesn't go beyond the left side
    CP 0
    JR Z, DrawPaddle
    DEC A
    DEC A
    LD (paddleX), A
    JR DrawPaddle

    ; Clear closes the program 
ClearPressed:
    CALL cls
    bcall(_GrBufCpy)
    bcall(_ClrScrnFull)    
    LD HL, 0
    LD (CurRow), HL
    RET

DrawPaddle:
    LD A, (paddleY)
    LD L, A
    LD A, (paddleX)
    LD B, PaddleWidth
    LD C, PaddleHeight
    CALL DrawRectangle

UpdateBall: 
	; Clear previous ball
	LD A, (ballY)
	LD L, A
	LD A, (ballX)
    CALL DrawBall	
	
	; Move and draw ball
	LD A, (ballVelocityY)
	LD D, A
	LD A, (ballY)
	ADD A, D 
	LD (ballY), A
	LD L, A
	LD A, (ballVelocityX)
	LD D, A
	LD A, (ballX)
	ADD A, D
	LD (ballX), A
    CALL DrawBall

	; Check for collision with right or left side
	LD A, (ballX)
	CP 0
	JR Z, BallXHit
	CP 93
	JR NC, BallXHit
	JR NoBallXHit
	; Ball hit left or right side
BallXHit:
	LD A, (ballVelocityX)
	NEG
	LD (ballVelocityX), A	
NoBallXHit:

	; Check for collision with top
	LD A, (ballY)
	CP 0
	JR Z, BallYHit
	; Check for collision with bottom
	CP 62
	JP NC, DisplayLoss

    ; Check collision with paddle
	CP 58
	JP NZ, NoBallYHit
    LD A, (ballX)
    INC A
    LD B, A
    LD A, (paddleX)
    CP B
    JR NC, NoBallYHit
    ADD A, PaddleWidth
    CP B
    JR C, NoBallYHit

	; Ball hit top or bottom side
BallYHit
	LD A, (ballVelocityY)
	NEG
	LD (ballVelocityY), A
NoBallYHit:

    ; Check collision with bricks
    LD A, (ballY)
    SUB A, 10 ; Sub because bricks are offset from top by 10
    ; If ball is not between 10 and 34 skip it to avoid out of bounds 
    CP 28
    JP NC, NoBrickHit
    ; Get the relevant brick row based on ball y coordinate
    ; row = floor((ballY + 1) / (BrickHeight + 1))
    INC A
    LD H, 0
    LD L, A
    LD D, BrickHeight + 1
    CALL DivHLD
    LD E, L
    LD (collisionLR), A
    ; E has the correct brick row

    LD A, (ballX)
    LD H, 0
    LD L, A
    LD D, BrickWidth + 1
    CALL DivHLD

    LD A, L
    LD B, L
    LD C, L
    ; A and C have the correct brick column
    CP 0
    LD A, %10000000
    JR Z, CollisionMaskShiftLoopEnd
CollisionMaskShiftLoop:
    RRCA
    DJNZ CollisionMaskShiftLoop
CollisionMaskShiftLoopEnd:
    
    ; Add E's offset to brickFirstRow to get the address of the actual row
    LD HL, brickFirstRow
    LD D, 0
    ADD HL, DE
    ; If the brick bit is reset we don't have a collision
    LD B, A
    AND (HL)
    CP 0
    JR Z, NoBrickHit
    ; If hit swap Y or X based on position between bricks
    LD A, (collisionLR)
    CP 0
    JR NC, BrickHitVertical
BrickHitHorizontal:
	LD A, (ballVelocityY)
	NEG
	LD (ballVelocityY), A
    JR EndBrickHit
BrickHitVertical:
    CP BrickHeight
    JR NC, BrickHitHorizontal
	LD A, (ballVelocityX)
	NEG
	LD (ballVelocityX), A
EndBrickHit:

    ; Remove the hit brick
    LD A, B
    XOR (HL)
    LD (HL), A
    ; Calculate the position of the hit brick
    LD B, E
    LD A, E
    CP 0
    LD A, BrickStartY
    JR Z, CollisionBrickRowEnd
CollisionBrickRowLoop
    ADD A, BrickHeight + 1
    DJNZ CollisionBrickRowLoop
CollisionBrickRowEnd:
    LD L, A
    ; L has the Y position
    LD B, C
    LD A, C
    CP 0
    LD A, 0
    JR Z, CollisionBrickColEnd
CollisionBrickColLoop
    ADD A, BrickWidth + 1
    DJNZ CollisionBrickColLoop
CollisionBrickColEnd:
    ; A has the X position
    ; Clear the brick
    LD B, BrickWidth 
    LD C, BrickHeight
    CALL DrawRectangle

    ; Check for win
    LD A, (bricksLeft)
    DEC A
    LD (bricksLeft), A
    CP 0
    JR Z, DisplayWin

NoBrickHit:
    ; Draw the graph screen to display
    bcall(_GrBufCpy)
    JP MainLoop


DisplayLoss:
    CALL Cls
    bcall(_GrBufCpy)
    ; Display the win text at 4, 2
    LD HL, 3*256+2
    LD (CurRow), HL
    LD HL, looseText
    bcall(_PutS)
    JR DisplayOptions
DisplayWin:
    CALL Cls
    bcall(_GrBufCpy)
    ; Display the win text at 4, 2
    LD HL, 4*256+2
    LD (CurRow), HL
    LD HL, winText
    bcall(_PutS)
DisplayOptions:
    ; Display continue and exit in small text
    LD HL, $211A
    LD (PenCol), HL
    LD HL, gameEndText1
    bcall(_VPutS)
    LD HL, $2A18
    LD (PenCol), HL
    LD HL, gameEndText2
    bcall(_VPutS)
GameOverInputLoop:
    LD A, $FD ; Clear and Enter are in group FD
    OUT (1), A
    NOP
    NOP
    IN A, (1)
    BIT 6, A ; If clear was pressed
    JP Z, ClearPressed
    BIT 0, A ; If enter was pressed
    JP Z, ProgramStart
    JR GameOverInputLoop

; Draw all the breakable bricks
DrawBricks:
    ; Draw each colum in a row of bricks
DrawBricksColLoop:
    ; Draw the brick
    LD A, (drawBricksRow)
    LD L, A
    LD A, (drawBricksCol)
    LD B, BrickWidth
    LD C, BrickHeight
    CALL DrawRectangle

    ; Continue column loop
    LD A, (drawBricksCol)
    ADD A, BrickWidth + 1
    LD (drawBricksCol), A
    CP 96 - BrickWidth + 1
    JP C, DrawBricksColLoop

    ; Continue row loop
    LD A, 0
    LD (drawBricksCol), A
    LD A, (drawBricksRow)
    ADD A, BrickHeight + 1
    LD (drawBricksRow), A
    CP 4 * BrickHeight + 10
    JR C, DrawBricks
    RET

; Draw the ball. Top-left at x(A), y(L)
DrawBall:    
    ; Get the starting address and offset
    LD H, 0
    ; Multiply y by 12
    ADD HL, HL
    ADD HL, HL
    LD D, H
    LD E, L
    ADD HL, HL
    ADD HL, DE
    ; Divide x by 8
    LD D, 0
    LD E, A
    SRL E
    SRL E
    SRL E
    ; Add them to PlotSScreen
    ADD HL, DE
	EX DE, HL
    LD IX, PlotSScreen
    ADD IX, DE
    AND 7 ; % 8
    LD H, A

    ; H has byte offset, IX has starting address

    ; Calculate the upper bytes into H and L and middle bytes into D and E
    LD A, H
    CP 0
    LD H, 01000000b
    LD L, 0
    LD D, 11100000b
    LD E, 0
    JR Z, _DrawBall_ShiftLoopEnd ; Skip shift if offset is 0
    LD B, A
_DrawBall_ShiftLoop:
    ; Shifting upper bytes
    SRL L
    SRL H
    JR NC, _DrawBall_SkipCarryUpper
    SET 7, L
_DrawBall_SkipCarryUpper:
    ; Shifting middle bytes
    SRL E
    SRL D
    JR NC, _DrawBall_SkipCarryLower
    SET 7, E
_DrawBall_SkipCarryLower:
    DJNZ _DrawBall_ShiftLoop
_DrawBall_ShiftLoopEnd:

    ; Draw top row pixels
    LD A, H
    XOR (IX)
    LD (IX), A
    INC IX
    LD A, L
    XOR (IX)
    LD (IX), A

    ; Draw middle row pixels
    LD BC, 11
    ADD IX, BC
    LD A, D
    XOR (IX)
    LD (IX), A
    INC IX
    LD A, E
    XOR (IX)
    LD (IX), A

    ; Draw bottom row pixels
    ADD IX, BC
    LD A, H
    XOR (IX)
    LD (IX), A
    INC IX
    LD A, L
    XOR (IX)
    LD (IX), A

    RET

; Draw a rectangle starting at x(A), y(L), w(B), h(C)
; Destroys everything
DrawRectangle:
    ; Get the starting address and offset
    LD H, 0
    ; Multiply y by 12
    ADD HL, HL
    ADD HL, HL
    LD D, H
    LD E, L
    ADD HL, HL
    ADD HL, DE
    ; Divide x by 8
    LD D, 0
    LD E, A
    SRL E
    SRL E
    SRL E
    ; Add them to PlotSScreen
    ADD HL, DE
	EX DE, HL
    LD IX, PlotSScreen
    ADD IX, DE
    AND 7 ; % 8
    LD H, A
	; BC to DE
	LD D, B
	LD E, C
	
    ; H has byte offset, IX has starting 
    ; address, D has width, E has height
    
    ; Special case for if width is less than 8
    LD A, B
    CP 8
    JR C, _DrawRectangle_ShortSprite

    ; Calculate the leading byte into L
    LD A, H
    CP 0
    LD A, $FF
    JR Z, _DrawRectangle_ShiftRLoopEnd ; Skip shift if offset is 0
    LD B, H
_DrawRectangle_ShiftRLoop:
    SRL A
    DJNZ _DrawRectangle_ShiftRLoop
_DrawRectangle_ShiftRLoopEnd:
    LD L, A
    
    ; Remove the leading byte count from width
    LD A, D
    SUB A, 8 ; Subtract full byte
    ADD A, H ; Add back the offset amount
	LD D, A
    ; Trailing offset = width % 8 -> C
    AND 7
    LD C, A
    ; Number of full bytes = (width - leading bytes - trailing bytes) / 8 -> D
    LD A, D
    SUB A, C
	SRL A
	SRL A
	SRL A
    LD D, A

    ; Calculate the trailing byte into H
    LD A, 8
    SUB A, C
    LD B, A
    LD A, $FF
_DrawRectangle_ShiftLLoop:
    SLA A
    DJNZ _DrawRectangle_ShiftLLoop
    LD H, A
    JR _DrawRectangle_RowLoop

    ; Special case for width < 8
    ; TODO implementation
_DrawRectangle_ShortSprite:
    RET

    ; L has leading byte, H has trailing byte, D has number of full bytes, E has height, and IX has starting address

_DrawRectangle_RowLoop:
    ; Write the first byte before loop if applicable
    LD A, L
    XOR (IX)
    LD (IX), A
    INC IX

    ; Skip loop if D = 0
    LD A, D
    CP 0
    JR Z, _DrawRectangle_FullLoopEnd 
    LD B, D
    ; Fill each byte with $FF for D iterations
_DrawRectangle_FullLoop:
    LD A, $FF
    XOR (IX)
    LD (IX), A
    INC IX
    DJNZ _DrawRectangle_FullLoop
_DrawRectangle_FullLoopEnd:

    ; Write the last byte after loop if applicable
    LD A, H
    XOR (IX)
    LD (IX), A
    INC IX

    ; Increment IX by (10 - full bytes) to move to next row
    LD A, 10
    SUB A, D
    LD B, A
_DrawRectangle_IncrementLoop:
    INC IX
    DJNZ _DrawRectangle_IncrementLoop

    DEC E
    JR NZ, _DrawRectangle_RowLoop
; End Row Loop
    RET


; Clear the graph buffer. Destroys HL, DE, BC
Cls:
    LD HL, 0
    LD (PlotSScreen), HL
    LD BC, 768
    LD HL, PlotSScreen
    LD DE, PlotSScreen + 1
    LDIR
    RET

; HL = HL ÷ D, A = remainder
DivHLD:
    XOR A
    LD B, 16
DivHLD_loop:
    ADD HL, HL
    RLA
    JR C, DivHLD_overflow
    CP D
    JR C, DivHLD_skip
DivHLD_overflow:
    SUB D
    INC L
DivHLD_skip:
    DJNZ DivHLD_loop
    RET

; Position data of the paddle, top-left
paddleX: .DB (96 / 2) - (PaddleWidth / 2)
paddleY: .DB 60

; Position data of the ball
ballX: .DB 45
ballY: .DB 56
ballVelocityX: .DB 1
ballVelocityY: .DB -1

; Brick data
drawBricksCol: .DB 0
drawBricksRow: .DB BrickStartY
bricksLeft: .DB 32
collisionLR: .DB 0

winText: .DB "YOU WIN!", 0
looseText: .DB "YOU LOOSE!", 0
gameEndText1: .DB "CLEAR to Quit", 0
gameEndText2: .DB "ENTER to Retry", 0

.end