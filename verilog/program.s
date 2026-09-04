.section ".text.init"

# Memory-mapped I/O addresses
.equ BUTTON_BASE, 0x70000000
.equ LED_BASE,    0x50000000
.equ GAME_STATE,  0x90000000
.equ SP_BASE,     0x9FFFFFC0

# Register offsets for button controller
.equ BTN_SRC_OFF, 4
.equ BTN_PTM_OFF, 8
.equ BTN_STM_OFF, 12

.equ MIE_BIT, 3
.equ MBIP_BIT, 11

.globl _start
_start:
    li sp, SP_BASE

    # Set up game value in memory
    li t0, GAME_STATE
    sw zero, 0(t0)

    # Set up interrupt vector
    lui t0, %hi(interrupt_handler)
    addi t0, t0, %lo(interrupt_handler)
    csrw mtvec, t0

    # ========= Enable global interrupts =========
    li t0, (1 << MIE_BIT)
    csrs mstatus, t0

    # ========= Enable button interrupts =========
    li t0, (1 << MBIP_BIT)
    csrs mie, t0

    # ========= Configure button & switch trigger mode =========
    li t0, BUTTON_BASE

    li t1, 0x55555
    sw t1, BTN_PTM_OFF(t0)

    li t1, 0x5555
    sw t1, BTN_STM_OFF(t0)


    li s1, LED_BASE

    # Long wait loop
    li t0, 5000
wait_loop:
    addi t0, t0, -1
    bnez t0, wait_loop

    # Load and check game result
    li t0, GAME_STATE
    lw t1, 0(t0)
    beqz t1, lose
    j win

lose:
    li t1, 0xFFFF01FF  # Set red LEDs on for all
    sw t1, 0(s1)
    j end_game

win:
    # Turn on green LEDs
    li t1, 0xFFFF02FF  # Set green LEDs on for all
    sw t1, 0(s1)

end_game:
    # Stop execution
    ebreak

interrupt_handler:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)

    # === HANDLE BUTTON INTERRUPT ===
    li t0, GAME_STATE
    li t1, 1
    sw t1, 0(t0)

    # === CLEAR INTERRUPT SOURCE ===
    li t0, BUTTON_BASE
    sw zero, BTN_SRC_OFF(t0)

    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t1, 8(sp)
    lw t2, 12(sp)
    addi sp, sp, 16
    mret