set ix [lsearch $argv -display]
if {$ix >= 0} {
    incr ix
    set env(DISPLAY) [lindex $argv $ix]
    set argc 0
    set argv {}
exec /opt/X11/bin/xclock
}
