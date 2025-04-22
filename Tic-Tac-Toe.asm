.386
.model flat, stdcall
.stack 4096
option casemap :none
TITLE TIC_TAC_TOE
INCLUDE irvine32.inc

.data
    ; Game board (3x3), 0=empty, 1=X, 2=O
    board byte 9 dup(0)
    
    ; Game messages
    titleMsg byte "Tic Tac Toe in MASM (Irvine32)", 0
    promptMode byte "Select mode: 1-Easy, 2-Hard, 3-2Player: ", 0
    invalidMode byte "Invalid mode selected", 0
    promptMove byte "Enter your move (1-9): ", 0
    invalidMove byte "Invalid move! Try again.", 0
    playerXWins byte "Player X wins!", 0
    playerOWins byte "Player O wins!", 0
    tieMsg byte "It's a tie!", 0
    currentBoard byte "Current board:", 0
    newline byte 13, 10, 0
    
    ; Characters for display
    emptyChar byte '.', 0
    xChar byte 'X', 0
    oChar byte 'O', 0
    
    ; Game state
    currentPlayer byte 1  ; 1=X, 2=O
    gameMode byte 0       ; 1=Easy, 2=Hard, 3=2Player
    gameOver byte 0       ; 0=playing, 1=over
    
    ; For input handling
    inputStr byte 16 dup(0)
    moveVal dword ?
    
.code

; Prints the current board
PrintBoard proc
    mov edx, offset currentBoard
    call WriteString
    call Crlf
    
    mov ecx, 0          ; counter
    mov esi, offset board
    
print_loop:
    movzx eax, byte ptr [esi]
    cmp eax, 0
    je print_empty
    cmp eax, 1
    je print_x
    
    ; print O
    mov edx, offset oChar
    call WriteString
    jmp print_space
    
print_empty:
    mov edx, offset emptyChar
    call WriteString
    jmp print_space
    
print_x:
    mov edx, offset xChar
    call WriteString
    
print_space:
    mov al, ' '
    call WriteChar
    
    ; Check for newline (every 3 cells)
    inc ecx
    mov eax, ecx
    cdq ; converts double to quead (EAX to EDX:EAX)
    mov ebx, 3
    div ebx ; Division by 3 to check when new line needs to be printe
    cmp edx, 0 ; EDX contains remainder after division so compare with 0
    jne no_newline
    
    call Crlf
    
no_newline:
    inc esi
    cmp ecx, 9
    jl print_loop
    
    call Crlf
    ret
PrintBoard endp

; Checks if the game is over (win or tie)
; Returns: eax = 0 (continue), 1 (X wins), 2 (O wins), 3 (tie)
CheckGameOver proc
    ; First check for wins (X or O)
    ; Check rows
    mov esi, 0
row_loop:
    mov al, board[esi]
    cmp al, 0
    je next_row
    
    cmp al, board[esi+1]
    jne next_row
    cmp al, board[esi+2]
    jne next_row
    
    ; Found a winning row
    movzx eax, al
    ret
    
next_row:
    add esi, 3
    cmp esi, 9
    jl row_loop
    
    ; Check columns
    mov esi, 0
col_loop:
    mov al, board[esi]
    cmp al, 0
    je next_col
    
    cmp al, board[esi+3]
    jne next_col
    cmp al, board[esi+6]
    jne next_col
    
    ; Found a winning column
    movzx eax, al
    ret
    
next_col:
    inc esi
    cmp esi, 3
    jl col_loop
    
    ; Check diagonals
    mov al, board[0]
    cmp al, 0
    je check_first_diag
    
    cmp al, board[4]
    jne check_first_diag
    cmp al, board[8]
    jne check_first_diag
    
    ; Found a winning diagonal
    movzx eax, al
    ret

check_first_diag:
    mov al, board[0]
    cmp al, 0
    je check_second_diag
    
    cmp al, board[4]
    jne check_second_diag
    cmp al, board[8]
    jne check_second_diag
    
    ; Found a winning diagonal
    movzx eax, al
    ret

check_second_diag:
    mov al, board[2]
    cmp al, 0
    je check_tie
    
    cmp al, board[4]
    jne check_tie
    cmp al, board[6]
    jne check_tie
    
    ; Found a winning diagonal
    movzx eax, al
    ret
    
check_tie:
    ; Only check for tie if no winner found
    mov esi, 0
tie_check:
    cmp board[esi], 0
    je not_tie
    inc esi
    cmp esi, 9
    jl tie_check
    
    ; It's a tie
    mov eax, 3
    ret
    
not_tie:
    mov eax, 0
    ret
CheckGameOver endp

; Easy AI - makes random moves
EasyAIMove proc
    push ecx
    
try_again:
    ; Generate random number between 0-8
    mov eax, 9
    call RandomRange    ; (returns random int from 0 to eax-1)
    
    ; Check if cell is empty
    cmp board[eax], 0
    jne try_again
    
    ; Make the move
    mov board[eax], 2  ; O's move
    
    pop ecx
    ret
EasyAIMove endp

; Hard AI - uses minimax algorithm
HardAIMove proc
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Initialize best score and move
    mov ebx, -1000   ; bestScore = -infinity
    mov ecx, -1       ; bestMove = -1
    
    ; Try all possible moves
    mov esi, 0       ; i = 0
move_loop:
    cmp board[esi], 0
    jne next_move
    
    ; Make the move
    mov board[esi], 2  ; O's move
    
    ; Call minimax
    push 0              ; isMaximizing = false (O is minimizing)
    push 0              ; depth = 0
    call Minimax
    add esp, 8
    
    ; Undo the move
    mov board[esi], 0
    
    ; Update best move
    cmp eax, ebx
    jle next_move
    mov ebx, eax
    mov ecx, esi
    
next_move:
    inc esi
    cmp esi, 9
    jl move_loop
    
    ; Make the best move
    mov board[ecx], 2
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
HardAIMove endp

; Minimax algorithm
; Parameters: isMaximizing (bool), depth (int)
; Returns: score (int)
Minimax proc
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Check if game is over
    call CheckGameOver
    cmp eax, 0
    je not_terminal
    
    ; Handle terminal state
    cmp eax, 1       ; X wins
    je x_wins
    cmp eax, 2       ; O wins
    je o_wins
    
    ; Tie
    mov eax, 0
    jmp minimax_end
    
x_wins:
    mov eax, -10
    jmp minimax_end
    
o_wins:
    mov eax, 10
    jmp minimax_end
    
not_terminal:
    mov ebx, [ebp+8]   ; isMaximizing
    cmp ebx, 0
    je minimizing
    
    ; Maximizing player (X)
    mov ebx, -1000      ; bestScore = -infinity
    mov esi, 0          ; i = 0
    
max_loop:
    cmp board[esi], 0
    jne max_next
    
    ; Try the move
    mov board[esi], 1
    
    ; Recursive call
    push 0              ; isMaximizing = false
    mov eax, [ebp+12]   ; depth
    inc eax
    push eax
    call Minimax
    add esp, 8
    
    ; Undo the move
    mov board[esi], 0
    
    ; Update best score
    cmp eax, ebx
    jle max_next
    mov ebx, eax
    
max_next:
    inc esi
    cmp esi, 9
    jl max_loop
    
    mov eax, ebx
    jmp minimax_end
    
minimizing:
    ; Minimizing player (O)
    mov ebx, 1000       ; bestScore = +infinity
    mov esi, 0          ; i = 0
    
min_loop:
    cmp board[esi], 0
    jne min_next
    
    ; Try the move
    mov board[esi], 2
    
    ; Recursive call
    push 1              ; isMaximizing = true
    mov eax, [ebp+12]   ; depth
    inc eax
    push eax
    call Minimax
    add esp, 8
    
    ; Undo the move
    mov board[esi], 0
    
    ; Update best score
    cmp eax, ebx
    jge min_next
    mov ebx, eax
    
min_next:
    inc esi
    cmp esi, 9
    jl min_loop
    
    mov eax, ebx
    
minimax_end:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret
Minimax endp

; Reads a number from input (1-9)
; Returns: eax = valid number (1-9)
ReadPlayerMove proc
read_again:
    mov edx, offset promptMove
    call WriteString
    
    ; Read string input
    mov edx, offset inputStr
    mov ecx, sizeof inputStr
    call ReadString
    
    ; Convert to number
    mov edx, offset inputStr
    call ParseInteger32   ; (string to int function)
    
    ; Validate (1-9)
    cmp eax, 1
    jl invalid
    cmp eax, 9
    jg invalid
    
    ; Check if cell is empty
    dec eax               ; convert to 0-based index
    cmp board[eax], 0
    jne invalid
    
    inc eax               ; return 1-based
    ret
    
invalid:
    mov edx, offset invalidMove
    call WriteString
    call Crlf
    jmp read_again
ReadPlayerMove endp

; Main game function
main proc
    ; Initialize random seed
    call Randomize       ; Irvine32 function
    
    ; Print title
    mov edx, offset titleMsg
    call WriteString
    call Crlf
    
    ; Get game mode
get_mode:
    mov edx, offset promptMode
    call WriteString
    
    ; Read mode (1-3)
    call ReadInt        
    call Crlf
    
    cmp eax, 1
    jl invalid_mode
    cmp eax, 3
    jg invalid_mode
    
    mov gameMode, al
    jmp mode_selected
    
invalid_mode:
    mov edx, offset invalidMode
    call WriteString
    call Crlf
    jmp get_mode
    
mode_selected:
    ; Main game loop
game_loop:
    call PrintBoard
    
    ; Check if game is over
    call CheckGameOver
    cmp eax, 0
    jne game_end
    
    ; Handle player moves
    cmp currentPlayer, 1
    je player_move
    
    ; AI move (if not 2-player mode)
    cmp gameMode, 3
    je player_move
    
    ; Easy or Hard AI
    cmp gameMode, 1
    jne hard_ai
    
    ; Easy AI
    call EasyAIMove
    jmp switch_player
    
hard_ai:
    ; Hard AI
    call HardAIMove
    jmp switch_player
    
player_move:
    ; Get player move
    call ReadPlayerMove
    
    ; Convert to 0-based index and make move
    dec eax
    mov cl, currentPlayer
    mov board[eax], cl
    
switch_player:
    ; Switch players
    xor currentPlayer, 3  ; 1 <-> 2
    jmp game_loop
    
game_end:
    call PrintBoard
    
    cmp eax, 1
    jne check_o_win
    
    ; X wins
    mov edx, offset playerXWins
    call WriteString
    jmp exit_game
    
check_o_win:
    cmp eax, 2
    jne tie
    
    ; O wins
    mov edx, offset playerOWins
    call WriteString
    jmp exit_game
    
tie:
    ; Tie
    mov edx, offset tieMsg
    call WriteString
    
exit_game:
    call Crlf
    exit
main endp

end main