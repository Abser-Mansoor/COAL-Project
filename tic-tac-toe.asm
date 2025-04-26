include irvine32.inc

.data
    ; Game board (3x3), 0=empty, -1=X, 1=O
    board sbyte 9 dup(0)
    
    ; Game messages
    titleMsg byte "Welcome to Tic Tac Toe", 0
    promptMode byte "Select mode: 1-Easy, 2-Hard, 3-2Player: ", 0
    invalidMode byte "Invalid mode selected", 0
    oTurn byte "O's Turn: ", 0
    xTurn byte "X's Turn: ", 0
    yourTurn byte "Your Turn:", 0
    promptMove byte "Enter your move (1-9):", 0
    compMove byte "Computer moving...", 0
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
    currentPlayer byte -1  ; -1=X, 1=O
    gameMode byte 0       ; 1=Easy, 2=Hard, 3=2Player
    gameOver byte 0       ; 0=playing, 1=over
    
    ; For input handling
    inputStr byte 16 dup(0)
    moveVal dword ?
    
.code
    ; Main game function
    main proc
        ; Initialize random seed
        call randomize       ; Irvine32 function
    
        ; Print title
        mov edx, offset titleMsg
        call WriteString
        call crlf
        call crlf
    
        ; Get game mode
        get_mode:
            mov edx, offset promptMode
            call writestring
    
            ; Read mode (1-3)
            call readint        
            call crlf
    
            cmp eax, 1
            jl invalid_mode
            cmp eax, 3
            jg invalid_mode
    
            mov gameMode, al
            jmp mode_selected
    
        invalid_mode:
            mov edx, offset invalidMode
            call writestring
            call crlf
            jmp get_mode
    
        mode_selected:
        
        ; Main game loop
        game_loop:
            call printBoard
    
            ; Check if game is over
            call evaluate
            cmp eax, 2
            jne game_end

            cmp gameMode, 3
            jne single_player
            cmp currentPlayer, -1
            je x_turn
            mov edx, offset oTurn
            jmp temp
            
            x_turn:
                mov edx, offset xTurn
            
            temp:
            call writestring
            call crlf

            jmp player_move

            single_player:

            cmp currentPlayer, -1
            jne computer_turn
            
            mov edx, offset yourTurn
            call writestring
            call crlf
            jmp player_move
    
            computer_turn:

            mov edx, offset compmove
            call writestring
            call crlf

            ; Easy or Hard AI
            cmp gameMode, 1
            jne hard
    
            ; Easy AI
            call easyMode
            jmp switch_player
    
            ; Hard AI
            hard:
            
            call hardMode
            jmp switch_player
    
            ; Get player move
            player_move:
                call readPlayerMove
    
                ; Make move
                mov cl, currentPlayer
                mov board[eax], cl
    
            ; Switch players
            switch_player:
                neg currentPlayer  ; -1 <-> 1
                jmp game_loop
    
            game_end:    
                cmp eax, -1
                jne check_o_win
    
                ; X wins
                mov edx, offset playerXWins
                call writestring
                jmp exit_game
    
            check_o_win:
                cmp eax, 1
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
            call crlf
            exit
    main endp

    ; Checks if the game is over (win or tie)
    ; Returns: eax = 0 (tie), -1 (X wins), 1 (O wins), 2 (continue)
    evaluate proc
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
            movsx eax, al
            jmp _end
    
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
            movsx eax, al
            jmp _end
    
            next_col:
                inc esi
                cmp esi, 3
                jl col_loop
            
        ; Check First diagonal
        first_diag:
            mov al, board[0]
            cmp al, 0
            je second_diag
    
            cmp al, board[4]
            jne second_diag
            cmp al, board[8]
            jne second_diag
    
            ; Found a winning diagonal
            movsx eax, al
            jmp _end

        second_diag:
            mov al, board[2]
            cmp al, 0
            je check_tie
    
            cmp al, board[4]
            jne check_tie
            cmp al, board[6]
            jne check_tie
    
            ; Found a winning diagonal
            movsx eax, al
            jmp _end
    
        ; Only check for tie if no winner found
        check_tie:
            call isMovesLeft
        
        _end:
            ret
    evaluate endp
    
    isMovesleft proc
        mov esi, 0
        mov ecx, 9

        check:
            cmp board[esi], 0
            je not_tie
            inc esi
        loop check

        mov eax, 0
        jmp _end

        not_tie:
            mov eax, 2
            
        _end:
            ret
    isMovesLeft endp

    ; Prints the current board
    printBoard proc
        mov edx, offset currentBoard
        call writestring
        call crlf
    
        mov ecx, 0          ; counter
        mov esi, 0
    
        print_loop:
            movsx eax, board[esi]
            cmp eax, 0
            je print_empty
            cmp eax, -1
            je print_x
    
            ; print O
            mov edx, offset oChar
            call writestring
            jmp print_space
    
            print_empty:
                mov edx, offset emptyChar
                call writestring
                jmp print_space
    
            print_x:
                mov edx, offset xChar
                call writestring
    
            print_space:
                mov al, ' '
                call writechar
    
            inc ecx
            
            ; Check for newline (every 3 cells)
            mov eax, ecx
            cdq ; converts double to quead (EAX to EDX:EAX)
            mov ebx, 3
            div ebx ; Division by 3 to check when new line needs to be printe
            cmp edx, 0 ; EDX contains remainder after division so compare with 0
            jne no_newline
    
            call crlf
    
            no_newline:
                inc esi
                cmp ecx, 9
                jl print_loop
    
        call crlf
        ret
    printBoard endp

    ; Reads a number from input (1-9)
    ; Returns: eax = valid number (0-8)
    readPlayerMove proc
        read_again:
            mov edx, offset promptMove
            call writestring
    
            ; Read string input
            mov edx, offset inputStr
            mov ecx, sizeof inputStr
            call readstring
    
            ; Convert to number
            mov edx, offset inputStr
            call parseinteger32   ; (string to int function)
    
            ; Validate (1-9)
            cmp eax, 1
            jl invalid
            cmp eax, 9
            jg invalid
    
            ; Check if cell is empty
            dec eax               ; convert to 0-based index
            cmp board[eax], 0
            jne invalid
    
            ret
    
            invalid:
                mov edx, offset invalidMove
                call writestring
                call crlf
                jmp read_again
    readPlayerMove endp


    ; Easy Mode - makes random moves
    easyMode proc
        try_again:
            ; Generate random number between 0-8
            mov eax, 9
            call randomrange    ; (returns random int from 0 to eax-1)
    
            ; Check if cell is empty
            cmp board[eax], 0
            jne try_again
    
        ; Make the move
        mov board[eax], 1  ; O's move
    
        ret
    easyMode endp

    ; Hard AI - uses minimax algorithm
    hardMode proc uses ebx ecx edx esi edi
        ; Initialize best score and move
        mov ebx, -1000      ; bestScore = -infinity
        mov edi, -1         ; bestMove = -1
    
        ; Try all possible moves
        mov esi, 0       ; i = 0
        move_loop:
            cmp board[esi], 0
            jne next_move
    
            ; Make the move
            mov board[esi], 1   ; O's move
    
            ; Call minimax
            push 0              ; isMaximizing = false (O is minimizing)
            push 0              ; depth = 0
            call minimax
    
            ; Undo the move
            mov board[esi], 0
    
            ; Update best move
            cmp eax, ebx
            jle next_move
            mov ebx, eax
            mov edi, esi
    
            next_move:
                inc esi
                cmp esi, 9
                jl move_loop
    
        ; Make the best move
        mov board[edi], 1
    
        ret
    hardMode endp

    ; Minimax algorithm
    ; Parameters: isMaximizing (bool), depth (int)
    ; Returns: score (int)
    minimax proc uses ebx ecx edx esi edi,
        depth:dword, isMax:dword

        ; Check if game is over
        call evaluate
        cmp eax, 2
        jne minimax_end
    
        ; not_terminal:
            cmp isMax, 0
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
            mov eax, depth      ; depth
            inc eax
            push eax
            call minimax
    
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
    
        ; Minimizing player (O)
        minimizing:
            mov ebx, 1000       ; bestScore = +infinity
            mov esi, 0          ; i = 0
    
            min_loop:
                cmp board[esi], 0
                jne min_next
    
                ; Try the move
                mov board[esi], -1
    
                ; Recursive call
                push 1              ; isMaximizing = true
                mov eax, depth      ; depth
                inc eax
                push eax
                call minimax
    
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
            ret
    minimax endp

end main
