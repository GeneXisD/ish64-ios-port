#include "gadgets.h"
#include "math.h"

// --- Helper macros for modern Xcode/Clang ---
.macro STORE_BYTE reg, cpu_offset
    adrp xTemp, _cpu
    add  xTemp, xTemp, :lo12:_cpu
    add  xTemp, xTemp, #\cpu_offset
    strb \reg, [xTemp]
.endm

.macro LOAD_BYTE reg, cpu_offset
    adrp xTemp, _cpu
    add  xTemp, xTemp, :lo12:_cpu
    add  xTemp, xTemp, #\cpu_offset
    ldrb \reg, [xTemp]
.endm

.macro STORE_HALF reg, cpu_offset
    adrp xTemp, _cpu
    add  xTemp, xTemp, :lo12:_cpu
    add  xTemp, xTemp, #\cpu_offset
    strh \reg, [xTemp]
.endm

.macro LOAD_HALF reg, cpu_offset
    adrp xTemp, _cpu
    add  xTemp, xTemp, :lo12:_cpu
    add  xTemp, xTemp, #\cpu_offset
    ldrh \reg, [xTemp]
.endm

// --- Gadgets ---
.gadget load32_addr
    mov _tmp, _addr
    gret

.gadget load16_gs
    LOAD_HALF _tmp, CPU_gs
    gret

.gadget store16_gs
    STORE_HALF _tmp, CPU_gs
    gret

// --- Arithmetic / Logic Operations ---
.macro _do_op op, arg, size, s
    .ifc \op,load
        movs _tmp, \arg, \s
        uxts _tmp, _tmp, \s
        .exitm
    .else N .ifc \op,store
        movs \arg, _tmp, \s
        .exitm
    .endif N .endif

    .ifin(\op, add,sub,adc,sbc)
        setf_a \arg, _tmp
    .endifin
    .ifin(\op, and,orr,eor)
        clearf_a
        clearf_oc
    .endifin
    .ifin(\op, adc,sbc)
        LOAD_BYTE w10, CPU_cf
        .ifc \op,adc
            cmp w10, 1
        .else
            mvn w10, w10
            cmn w10, 1
        .endif
    .endifin

    .ifin(\op, and,orr,eor)
        \op _tmp, _tmp, \arg
    .endifin

    .ifin(\op, add,sub,adc,sbc)
        do_add \op, _tmp, \arg, \s
    .endifin

    .ifc \op,imul
        .ifnb \s
            sxt\s w10, \arg
            mul _tmp, _tmp, w10
            cmp _tmp, _tmp, sxt\s
        .else
            smull _xtmp, _tmp, \arg
            cmp _xtmp, _tmp, sxtw
        .endif
        cset w10, ne
        STORE_BYTE w10, CPU_cf
        STORE_BYTE w10, CPU_of
    .endif

    .ifin(\op, bsf,bsr)
        .ifnb \s
            uxt\s w10, \arg
        .else
            mov w10, \arg
        .endif
        .ifc \op,bsf
            .if \size != 32
                orr w10, w10, 1<<\size
            .endif
            rbit w10, w10
            clz w10, w10
            cmp w10, \size
        .else
            clz w10, w10
            .if \size != 32
                sub w10, w10, 32-\size
            .endif
            cmp w10, \size
            mov w9, \size-1
            sub w10, w9, w10
        .endif
        csel _tmp, w10, _tmp, ne
        cset w10, eq
        LOAD_BYTE w9, CPU_eflags
        bic w9, w9, ZF_FLAG
        orr w9, w9, w10, lsl 6
        STORE_BYTE w9, CPU_eflags
        LOAD_BYTE w9, CPU_flags_res
        bic w9, w9, ZF_RES
        STORE_BYTE w9, CPU_flags_res
    .endifin

    .ifc \op,xchg
        mov w9, _tmp
        mov _tmp, \arg
        movs \arg, w9, \s
    .endif

    .ifin(\op, add,sub,adc,sbc,and,orr,eor)
        setf_zsp \s
    .endifin
.endm

// --- Replace all _cpu memory accesses in remaining macros ---
.macro do_inc size, s
    mov w10, 1
    setf_a w10, _tmp
    .ifb \s
        adds _tmp, _tmp, 1
        cset w8, vs
    .else
        sxt\s _tmp, _tmp
        add _tmp, _tmp, 1
        cmp _tmp, _tmp, sxt\s
        cset w8, ne
    .endif
    STORE_BYTE w8, CPU_of
    setf_zsp \s
.endm

.macro do_dec size, s
    mov w10, 1
    setf_a w10, _tmp
    .ifb \s
        subs _tmp, _tmp, 1
        cset w8, vs
    .else
        sxt\s _tmp, _tmp
        sub _tmp, _tmp, 1
        cmp _tmp, _tmp, sxt\s
        cset w8, ne
    .endif
    STORE_BYTE w8, CPU_of
    setf_zsp \s
.endm

.macro do_imul1 size, s
    .ifb \s
        smull xax, eax, _tmp
        lsr xdx, xax, 32
        cmp xax, eax, sxtw
    .else
        sxt\s w8, eax
        sxt\s _tmp, _tmp
        mul w8, w8, _tmp
        cmp w8, w8, sxt\s
        .if \size == 8
            bfxil eax, w8, 0, \size*2
        .else
            bfxil eax, w8, 0, \size
            bfxil edx, w8, \size, \size
        .endif
    .endif
    cset w8, ne
    STORE_BYTE w8, CPU_cf
    STORE_BYTE w8, CPU_of
.endm

// --- Replace all remaining strb/ldrb with STORE_BYTE/LOAD_BYTE macros ---
// Do the same for do_mul, do_div, do_idiv, do_not, etc.

.irp op, inc,dec,sign_extend,zero_extend,div,idiv,mul,imul1,not
    .irp size, SIZE_LIST
        .gadget \op\()_\size
            ss \size, do_\op
            gret
    .endr
    .gadget_list \op, SIZE_LIST
.endr

// --- Conversions ---
.gadget cvt_16
    tst eax, 0x8000
    cinv w8, wzr, ne
    bfxil edx, w8, 0, 16
    gret
.gadget cvt_32
    tst eax, 0x80000000
    cinv edx, wzr, ne
    gret
.gadget_list cvt, SIZE_LIST

.gadget cvte_16
    sxtb w8, eax
    bfxil eax, w8, 0, 16
    gret
.gadget cvte_32
    sxth eax, eax
    gret
.gadget_list cvte, SIZE_LIST
