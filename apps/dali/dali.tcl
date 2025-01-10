##+##########################################################################
#
# dali.tcl -- tk version of Dali Clock where digits morph
# by Keith Vetter, Aug 2009
#

package require Tcl 8.5
package require Tk
package require Img

set S(title) "Tk Dali Clock"
set S(tformat) "%I:%M:%S"
set S(dformat) "%m/%d/%y"
set S(cformat) $S(tformat)
set S(font) {Times 128 bold}
set S(parth) 0                                  ;# Tweak morphing algorithm
set S(steps) 10                                 ;# Steps for a full morph
set S(pause) 500                                ;# Delay between morphs (ms)
set S(date,after) ""
set S(date,pause) 2000
set S(go) 1                                     ;# Debugging way to stop time
set S(lm) 0                                     ;# Margins
set S(tm) 10
set S(clr) cyan

array set CLR {
    steps 100
    delay 20
    big,delay 5000
    afterId ""
    go 0
}

proc DoDisplay {} {
    global S B

    wm title . $S(title)
    set cw [expr {2*$S(lm) + $S(width)}]
    set ccw [expr {2*$S(lm) + $S(cwidth)}]
    set ch [expr {2*$S(tm) + $S(height)}]
    foreach w {.h0 .h1 .c0 .m0 .m1 .c1 .s0 .s1} {
        canvas $w -width $cw -height $ch -highlightthickness 0 -bd 0 -bg $S(clr)
        pack $w -side left
    }
    .c0 config -width $ccw
    .c1 config -width $ccw

    Init
    bind all <1> ShowDate
    bind all <3> ToggleRotateColors
}
##+##########################################################################
#
# Init -- Sets initial numbers for our clock
#
proc Init {} {
    global D S
    set ttime [clock format [clock seconds] -format $S(cformat)]
    foreach c {.h0 .h1 .c0 .m0 .m1 .c1 .s0 .s1} d [split $ttime {}] {
        if {$d eq " "} { set d S }
        DrawBits $c $::B($d,bits)
        set D($c) $d
    }
}
##+##########################################################################
#
# Ticker -- The pulse beat of our clock. Gets called every second.
#
proc Ticker {} {
    global D S

    set ttime [clock format [clock seconds] -format $S(cformat)]
    foreach c {.h0 .h1 .c0 .m0 .m1 .c1 .s0 .s1} d [split $ttime {}] {
        if {$D($c) == $d} continue
        FullMorph $c $D($c) $d $S(steps)
        set D($c) $d
    }
    if {$S(go)} {
        after 1000 Ticker
    }
}
##+##########################################################################
# 
# ShowDate -- Shows us the date. It changes the clock format string
# to the date default, then does an after to restore back to time.
# 
proc ShowDate {} {
    after cancel $::S(date,after)
    set ::S(cformat) $::S(dformat)
    set ::S(date,after) [after $::S(date,pause) {set ::S(cformat) $::S(tformat)}]
}
##+##########################################################################
#
# Pos2Cell -- Converts bit position to canvas location
#
proc Pos2Cell {row col} {
    global S

    set x0 [expr {$S(lm) + $col}]
    set y0 [expr {$S(tm) + $row}]
    set x1 [expr {$x0 + 1}]
    set y1 [expr {$y0 + 1}]

    return [list $x0 $y0 $x1 $y1]
}
##+##########################################################################
#
# DrawBits -- Draws our character in a given canvas.
# Format: list of row data with each row being a
# list of start of ON bits followed by end of ON bits, repeated.
# Example {10 15} {9 12 14 20} => two rows, first with bits
# on between 10-15; second with bits on 9-12 and 14-20.
#
proc DrawBits {c bits} {
    $c delete pixels

    set row -1
    foreach line $bits {
        incr row
        foreach {start end} $line {
            lassign [Pos2Cell $row $start] x0 y0
            lassign [Pos2Cell $row $end] . . x1 y1
            $c create line $x0 $y0 $x1 $y0 -tag pixels -fill black -width 1
        }
    }
}
##+##########################################################################
#
# FullMorph -- Sets up our everything to morph FROM to TO in STEPS
# on canvas C
#
proc FullMorph {c from to steps} {
    set delay [expr {(1000-$::S(pause)) / $steps}]
    set mid [ComputeMorphing $from $to $steps]

    after 10 DoOneStep $c $mid 1 $steps $delay
    return
}
##+##########################################################################
#
# DoOneStep -- Does next step in our morphing process
#
proc DoOneStep {c mid step steps delay} {
    set next [expr {[clock milliseconds] + $delay}]
    if {$step > $steps} return
    set bits [_MorphStep $mid $step]
    DrawBits $c $bits

    incr step
    if {$step > $steps} return
    set next [expr {max(10, $next-[clock milliseconds])}]
    after $next DoOneStep $c $mid $step $steps $delay
}
##+##########################################################################
#
# _MorphStep -- generates on bits for doing this morph (mid)
# at step number $step
#
proc _MorphStep {mid step} {
    global M

    set bits {}
    foreach plan $M($mid) {
        set line {}

        foreach {start0 ds end0 de} $plan {
            if {$start0 eq "not"} break
            set start [expr {round($start0 + $ds*$step)}]
            set end [expr {round($end0 + $de*$step)}]
            if {$start < $end} {
                lappend line $start $end
            }
        }
        lappend bits $line
    }
    return $bits
}
##+##########################################################################
#
# ComputeMorphing -- Computes our morphing plan for FROM to TO
# in STEPS steps
#
proc ComputeMorphing {from to steps} {
    global S B M

    if {[info exists M($from,$to,$steps)]} {return "$from,$to,$steps" }
    set all {}
    foreach row0 $B($from,bits) row1 $B($to,bits) {
        set plan [_ComputeMorphingRow $row0 $row1 $steps]
        lappend all $plan
    }
    set M($from,$to,$steps) $all
    return "$from,$to,$steps"
}
##+##########################################################################
#
# _ComputeMorphingRow -- Computes morphing plan for one given row.
# input format: run# see DrawBits
# output format: startPos deltaSetp endPos deltaStep {repeated as needed}
#
proc _ComputeMorphingRow {run0 run1 steps} {
    set segs0 [expr {[llength $run0] / 2}]
    set segs1 [expr {[llength $run1] / 2}]

    set plan {}
    set pplan {}
    set steps [expr {double($steps)}]

    if {$segs0 == 0} {
        foreach {start end} $run1 {             ;# Need some births
            lappend plan {*}[_PlanOneSegment \
                              $start [expr {$start-$steps/2}] \
                              $start $end $steps]
        }
    } elseif {$segs1 == 0} {
        foreach {start end} $run0 {             ;# Need some deaths
            lappend plan {*}[_PlanOneSegment $start $end $start \
                              [expr {$start-$steps/2}] $steps]
        }
    } elseif {$segs0 > $segs1} {
        lassign [_MatchUpSegments $run0 $run1] die nearest morph
        lassign $die start end

        if {$nearest eq {} || $::S(parth)} {    ;# Kill a segment
            set plan [_PlanOneSegment $start $end $start \
                          [expr {$start-$steps/2}] $steps]
        } else {
            lappend morph {*}$die {*}$nearest
        }
        foreach {start0 end0 start1 end1} $morph {
            set ds [expr {($start1-$start0)/$steps}]
            set de [expr {($end1-$end0)/$steps}]
            lappend plan $start0 $ds $end0 $de
        }
    } elseif {$segs0 < $segs1} {
        lassign [_MatchUpSegments $run1 $run0] birth nearest morph
        lassign $birth start end

        if {$nearest eq {} || $::S(parth)} {    ;# Birth a segment
            set plan [_PlanOneSegment \
                          $start [expr {$start-$steps/2}] \
                          $start $end $steps]
        } else {
            lappend morph {*}$birth {*}$nearest
        }

        foreach {start1 end1 start0 end0} $morph {
            set ds [expr {($start1-$start0)/$steps}]
            set de [expr {($end1-$end0)/$steps}]
            lappend plan $start0 $ds $end0 $de
        }
    } else {
        foreach {start0 end0} $run0 {start1 end1} $run1 {
            set ds [expr {($start1-$start0)/$steps}]
            set de [expr {($end1-$end0)/$steps}]
            lappend plan $start0 $ds $end0 $de
        }
    }

    return $plan
}
proc _PlanOneSegment {start0 end0 start1 end1 steps} {
    set ds [expr {($start1-$start0)/double($steps)}]
    set de [expr {($end1-$end0)/double($steps)}]
    return [list $start0 $ds $end0 $de]
}
##+##########################################################################
#
# _MatchUpSegments -- when one side of morph has less
# segments than the other, this figures out which one
# is orphaned and which ones match up.
#
proc _MatchUpSegments {run0 run1} {
    if {[llength $run0] != [llength $run1] + 2} {
        error "run0 must be one segment longer than run1"
    }

    set idx0 0
    foreach {s e} $run0 {
        set S0($idx0) [list $s $e]
        incr idx0
    }
    set idx1 0
    foreach {s e} $run1 {
        set S1($idx1) [list $s $e]
        incr idx1
    }
    set S1(-1) {}

    # Find the outlier segment to skip
    set best 99999
    for {set skip 0} {$skip < $idx0} {incr skip} {
        set j -1
        set cost 0
        set pairs {}
        for {set i 0} {$i < $idx0} {incr i} {
            if {$i == $skip} continue
            incr j
            incr cost [_ComputeDistance $S0($i) $S1($j)]
            lappend pairs {*}$S0($i) {*}$S1($j)
        }
        if {$cost < $best} {
            set best $cost
            set who [list $S0($skip) {} $pairs]
            set skipped $skip
        }
    }

    set best 99999
    set nearest -1
    for {set j 0} {$j < $idx1} {incr j} {
        set cost [_ComputeDistance $S0($skipped) $S1($j)]
        if {$cost < $best} {
            set best $cost
            set nearest $j
        }
    }
    lset who 1 $S1($nearest)
    return $who
}
##+##########################################################################
#
# _ComputeDistance -- Returns how far apart two segments are
#
proc _ComputeDistance {seg0 seg1} {
    foreach {s0 e0} $seg0 {s1 e1} $seg1 break
    if {$s0 > $e1} { return [expr {$s0-$e1}] }
    if {$e0 < $s1} { return [expr {$s1-$e0}] }
    return 0
}
################################################################
#
# Extract font bit info from a given font
#
proc GetAllBits {font} {
    global S B

    set S(width) 0
    foreach char {/ : S 0 1 2 3 4 5 6 7 8 9} {
        _GetBitsOneChar "" $font $char
        set S(width) [expr {max($S(width), $B($char,width))}]
    }
    _TrimChars
    set S(cwidth) $B(:,width)
}
##+##########################################################################
#
# _GetBitsOneChar -- Returns on bits for a given character in a given font.
# Uses Img to capture the image of a widget
#
proc _GetBitsOneChar {top font char} {
    global B

    destroy $top.l
    label $top.l -text [expr {$char eq "S" ? " " : $char}] -font $font -bg white
    pack $top.l
    update

    image create photo ::img::bits -data $top.l
    set h [image height ::img::bits]
    set w [image width ::img::bits]
    set all {}
    for {set row 0} {$row < $h} {incr row} {
        set lastBit \#ffffff
        set startStop {}
        set bits [::img::bits data -from 0 $row $w [expr {$row+1}]]
        set bits [concat [lindex $bits 0] \#ffffff]
        set col -1
        foreach bit $bits {
            incr col
            if {$bit ne "\#ffffff"} { set bit "\#000000" } ;# Anti-aliasing
            if {$lastBit ne $bit} {
                lappend startStop [expr {$lastBit == 0 ? $col : $col-1}]
                set lastBit $bit
            }
        }
        lappend all $startStop
    }
    set B($char,bits) $all
    set B($char,width) $w
    set B($char,height) $h
    destroy $top.l
}
##+##########################################################################
#
# _TrimChars -- Removes excess blank lines at top and bottom
#
proc _TrimChars {} {
    global B S

    set top 9999
    set bottom 9999
    foreach arr [array names B *,bits] {
        set thisTop [lsearch -not $B($arr) {}]
        set top [expr {min($top,$thisTop)}]
        set thisBottom [lsearch -not [lreverse $B($arr)] {}]
        set bottom [expr {min($bottom,$thisBottom)}]
    }

    foreach arr [array names B *,bits] {
        set B($arr) [lrange $B($arr) $top end-$bottom]
        set char [lindex [split $arr ","] 0]
        set B($char,height) [llength $B($arr)]
    }
    set S(height) $B(0,height)
}
##+##########################################################################
#
# ToggleRotateColors -- Turns on and off rotating background colors
#
proc ToggleRotateColors {} {
    global CLR
    after cancel $CLR(afterId)
    set CLR(go) [expr {! $CLR(go)}]
    RotateColors
}
##+##########################################################################
#
# RotateColors -- Determines next color and spawns $CLR(steps)
# after calls to slowly change to that color. It then reschedules
# itself to repeat again.
#
proc RotateColors {} {
    global CLR

    after cancel $CLR(afterId)
    if {! $CLR(go)} return

    set current [.h0 cget -bg]
    set next [LightColor]
    foreach var {red0 green0 blue0} value [winfo rgb . $current] {
        set $var [expr {$value/256}]
    }
    foreach var {red1 green1 blue1} value [winfo rgb . $next] {
        set $var [expr {$value/256}]
    }
    set dred [expr {$red1 - $red0}]
    set dgreen [expr {$green1 - $green0}]
    set dblue [expr {$blue1 - $blue0}]


    for {set i 0} {$i < $CLR(steps)} {incr i} {
        set red [expr {int($red0 + $dred/double($CLR(steps)) * $i)}]
        set green [expr {int($green0 + $dgreen/double($CLR(steps)) * $i)}]
        set blue [expr {int($blue0 + $dblue/double($CLR(steps)) * $i)}]
        set clr [format "\#%02x%02x%02x" $red $green $blue]
        set aid [after [expr {($i+1) * $CLR(delay)}] [list SetColor $clr]]
        #puts "$aid => [after info $aid]"
    }
    set CLR(afterId) [after $CLR(big,delay) RotateColors]
}
##+##########################################################################
#
# SetColor -- Updates the color of all our widgets
#
proc SetColor {clr} {
    foreach w [winfo child .] {
        $w config -background $clr
    }
}
##+##########################################################################
#
# LightColor -- returns a "light" color. A light color is one in
# which the V value in the HSV color model is greater than .7. Since
# the V value is simply the maximum of R,G,B we simply need at least
# one of R,G,B must be greater than .7.
#
proc LightColor {} {
    set light [expr {255 * .7}]                 ;# Value threshold
    while {1} {
        set r [expr {int (255 * rand())}]
        set g [expr {int (255 * rand())}]
        set b [expr {int (255 * rand())}]
        if {$r > $light || $g > $light || $b > $light} break
    }
    return [format "\#%02x%02x%02x" $r $g $b]
}

################################################################

GetAllBits $S(font)
DoDisplay
Ticker
#RotateColors
return


