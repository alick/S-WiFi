# Copyright (c) 1997 Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#      This product includes software developed by the Computer Systems
#      Engineering Group at Lawrence Berkeley Laboratory.
# 4. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# simple-wireless.tcl
# A simple example for wireless simulation

# ======================================================================
# Handle command line arguments
# ======================================================================
proc usage {} {
	global argv0
	puts "$argv0 func mode"
	puts "    func    One of pcf (default), rtt, reliability, and delay"
	puts "    mode    One of baseline or smart (default) or number if func is pcf;"
	puts "            one of downlink (default) or uplink otherwise"
	exit 0
}
if {$argc < 1} {
	set func "pcf"
} else {
	set func [lindex $argv 0]
}
# Allow abbreviated command line arguments.
# e.g. `ns swifi.tcl d` is the same as `ns swifi.tcl delay`
switch -glob -nocase $func {
	d* {
		set func "delay"
	}
	re* {
		set func "reliability"
	}
	rt* {
		set func "rtt"
	}
	p* {
		set func "pcf"
	}
	default {
		usage
	}
}
if {$argc < 2} {
	if {0 == [string compare $func "pcf"]} {
		set mode "smart"
	} else {
		set mode "downlink"
	}
} else {
	set mode [lindex $argv 1]
}
switch -glob -nocase $mode {
	d* {
		set mode "downlink"
	}
	u* {
		set mode "uplink"
	}
	b* {
		set mode "baseline"
	}
	s* {
		set mode "smart"
	}
	[0-9]* {
		# Do nothing.
	}
	default {
		usage
	}
}
if {0 == [string compare $func "pcf"]} {
	# Disable retry in MAC layer.
	set retry_mac 0
} else  {
	  if {0 == [string compare $mode "uplink"] || 0 == [string compare $mode "downlink"]} {
		if {0 == [string compare $func "delay"]} {
			if {$argc < 3} {
				set retry_mac 1
			} else {
				set retry_mac [lindex $argv 2]
			}
		}
		else {
			set retry_mac 1
	  	}
	  } else {
 		usage
	  }
}

puts "func: $func, mode: $mode"

if {0 == [string compare $func "pcf"]} {
	if {$argc < 5} {
		set val(nn)     6          ;# number of mobilenodes
	} else {
		set val(nn)     [lindex $argv 4]		
	}
} else {
	set val(nn)             2          ;# number of mobilenodes
}

set interval 10
puts "interval: $interval, number of nodes: $val(nn)"

if {0 == [string compare $func "pcf"]} {
	if {$argc < 3} {
		set dist 1000
	} else {
		set dist [lindex $argv 2]
	}
	if {$argc < 4} {
		set symmetry "sym"
	} else {
		set symmetry [lindex $argv 3]
	}
	switch -glob -nocase $symmetry {
		s* {
			set symmetry "sym"
			for {set i 1} {$i < $val(nn)} {incr i} {
				set distance([expr $i - 1]) $dist
			}
		}
		a* {
			set symmetry "asym"
			# Asymmetric channel: put the first two clients near
			# the AP and the others of the same distance.
			for {set i 1} {$i <= 2} {incr i} {
				set distance([expr $i - 1]) 1
			}
			for {set i 3} {$i < $val(nn)} {incr i} {
				set distance([expr $i - 1]) $dist
			}
		}
		default {
			usage
		}
	}
} elseif {0 == [string compare $func "delay"]} {
	# Set the distance that the reliability is >= 55% per Problem 3.
	set distance(0) 1000
} else {
	set distance(0) 1
}
for {set i 1} {$i < $val(nn)} {incr i} {
	puts "distance of node $i: $distance([expr $i - 1])"
}


# ======================================================================
# Define options
# ======================================================================

set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/Shadowing      ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(rp)             DumbAgent                  ;# routing protocol

# ======================================================================
# Main Program
# ======================================================================


# ======================================================================
# Initialize Global Variables
# ======================================================================

set ns_		[new Simulator]
set tracefname  [format "swifi_%s_%s.tr" $func $mode]
set tracefd     [open $tracefname w]
$ns_ trace-all $tracefd

# set up topography object
set topo       [new Topography]

$topo load_flatgrid 500 500

# ======================================================================
# Create God (General Operations Director)
# ======================================================================

create-god $val(nn)

# ======================================================================
# Configure node
# ======================================================================

Phy/WirelessPhy set Pt_ 1
Propagation/Shadowing set pathlossExp_ 2.0  ;# path loss exponent
Propagation/Shadowing set std_db_ 4.0       ;# shadowing deviation (dB)
Propagation/Shadowing set dist0_ 1.0        ;# reference distance (m)
Propagation/Shadowing set seed_ 0           ;# seed for RNG

Mac/802_11 set dataRate_  11.0e6
Mac/802_11 set basicRate_ 1.0e6
Mac/802_11 set CWMin_         1
Mac/802_11 set CWMax_         1
Mac/802_11 set PreambleLength_  144                   ;# long preamble 
Mac/802_11 set RTSThreshold_  5000
Mac/802_11 set PLCPDataRate_  1.0e6                   ;# 1Mbps
Mac/802_11 set ShortRetryLimit_  [expr $retry_mac + 1]    ;# retransmittions
Mac/802_11 set LongRetryLimit_   [expr $retry_mac + 1]    ;# retransmissions
Mac/802_11 set TxFeedback_ 0;

# Build a LUT of (distance, reliability).
set lutfp [open "report/swifi_reliability_uplink.dat" r]
set lutfile [read $lutfp]
close $lutfp
set pattern {([\.0-9]+)\s+([\.0-9]+)}
foreach {fullmatch m1 m2} [regexp -all -line -inline $pattern $lutfile] {
	set lut($m1) $m2
}

if {0 == [string compare $func "pcf"]} {
	if {0 == [string compare $mode "smart"]} {
		set modenum 7
	} elseif {0 == [string compare $mode "baseline"]} {
		set modenum 0
	} else {
		set modenum $mode
	}
	set selective [expr ($modenum & 1) ? 1 : 0]
	set piggyback [expr ($modenum & 2) ? 1 : 0]
	set use_retry_limit [expr ($modenum & 4) ? 1 : 0]
	puts "selective=$selective, piggyback=$piggyback, use_retry_limit=$use_retry_limit"
	Agent/SWiFi set pcf_policy_ $modenum
	Agent/SWiFi set use_retry_limit_ $use_retry_limit

	# Determine the number of selected clients for selective scheduling.
	set reliability [list]
	for {set i 1} {$i < $val(nn) } {incr i} {
		lappend reliability $lut([expr abs($distance([expr $i - 1]))])
	}
	set num_clients [expr $val(nn) - 1]
	set reliability_sorted [lsort -real -decreasing $reliability]
	set num_select 1
	set retry_limit 1
	set max_throughput_est 0.0 ;# It will be overriden by the correct value.
	for {set k 1} {$k <= $num_clients} {incr k} {
		# Calculate the estimated total throughput
		# for the k clients with largest channel reliabilities.
		set cum_reliability 0.0
		# Estimated number of slots for POLL_NUM (may not be an integer)
		set num_slots_num 0.0
		for {set i 0} { $i < $k } {incr i} {
			set cum_reliability [expr $cum_reliability + [lindex $reliability_sorted $i]]
			set p [lindex $reliability_sorted $i]
			if {$use_retry_limit} {
				set num_slots_num_k 0.0
				set cum_prob 0.0
				for {set j 1} {$j < $retry_limit} {incr j} {
					set prob [expr pow(1 - $p, $j - 1) * $p]
					set cum_prob [expr $cum_prob + $prob]
					set num_slots_num_k_j [expr $j * $prob]
					set num_slots_num_k [expr $num_slots_num_k + $num_slots_num_k_j]
				}
				set prob [expr 1 - $cum_prob]
				set num_slots_num_k_j [expr ($retry_limit + 1) * $prob]
				set num_slots_num_k [expr $num_slots_num_k + $num_slots_num_k_j]
			} else {
				set num_slots_num_k [expr 1.0 / [lindex $reliability_sorted $i]]
			}
			set num_slots_num [expr $num_slots_num + $num_slots_num_k]
		}
		if {$piggyback} {
			set num_slots_data $interval
		} else {
			set num_slots_data [expr max(0, $interval - $num_slots_num)]
		}
		set th [expr min($k, [expr $num_slots_data * $cum_reliability / $k])]
		# Add a small guard amount to avoid variance of floating point computation.
		if {$th > [expr $max_throughput_est + 1e-3]} {
			set num_select $k
			set max_throughput_est $th
		}
	}
	if {$selective} {
		puts "num_select: $num_select"
		Agent/SWiFi set num_select_ $num_select
	}
	if {$use_retry_limit} {
		puts "retry_limit: $retry_limit"
		Agent/SWiFi set retry_limit_ $retry_limit
	}
}

Agent/SWiFi set packet_size_ 1000
#Agent/SWiFi set slot_interval_ 0.01
Agent/SWiFi set realtime_ true

set logfname [format "swifi_%s_%s.log" $func $mode]
set logf [open $logfname w]
if {0 == [string compare $func "pcf"]} {
	set datfname [format "swifi_%s_%s_%s.dat" $func $symmetry $mode]
	set datlname [format "swifi_%s_%s_%s_long.dat" $func $symmetry $mode]
} else {
	set datfname [format "swifi_%s_%s.dat" $func $mode]
	set datlname [format "swifi_%s_%s_long.dat" $func $mode]
}
set datf [open $datfname w]
set datl [open $datlname w]
set logqname [format "swifi_%s_%s_queue.log" $func $mode]
set logq [open $logqname w]
set loganame [format "swifi_%s_%s_arrival.log" $func $mode]
set loga [open $loganame w]
if {0 == [string compare $func "delay"]} {
	set delayfname [format "swifi_%s_%s_%d.dat" $func $mode $retry_mac]
	set delayf [open $delayfname w]
}
set n_rx_tot 0
set avg_throughput 0.0
Agent/SWiFi instproc recv {from rtt data} {
	global logf delayf n_rx_tot func n_rx
	set n_rx_tot [expr $n_rx_tot + 1]
	set n_rx($from) [expr $n_rx($from) + 1]
        $self instvar node_
	if {0 != [string compare $func "delay"]} {
		set rtt_name "round-trip-time"
	} else {
		set rtt_name "delay"
	}
        puts $logf "Node [$node_ id] received reply from node $from\
		with $rtt_name $rtt ms and message $data."
	if {0 == [string compare $func "delay"]} {
		puts $delayf "$rtt"
	}
	flush $logf
}
Agent/SWiFi instproc stat {n_run} {
	global n_rx_tot num_slots distance datf interval func avg_throughput n_rx datl num_clients avg_throughput_i throughput_i
	set throughput [expr double($n_rx_tot) * $interval / $num_slots]
	set avg_throughput [expr ($avg_throughput * $n_run + $throughput)/ ($n_run + 1)]
	if {0 != [string compare $func "pcf"]} {
		puts $datf "$distance($n_run) $throughput"
		flush $datf
	}
	for {set i 1} {$i <= $num_clients} {incr i} {
		set throughput_i($i) [expr double($n_rx($i)) * $interval / $num_slots] 
		set avg_throughput_i($i) [expr ($avg_throughput_i($i) * $n_run + $throughput_i($i))/ ($n_run + 1)]
	}
	set n_rx_tot 0
	for {set k 1} {$k <= $num_clients} {incr k} {
		set n_rx($k) 0
	}
}
Agent/SWiFi instproc alog { num } {
	global loga
	$self instvar node_
	puts $loga "Node [$node_ id] current number of data packets = $num"
	flush $loga
}
proc qlog { node qlen } {
	global logq
	puts $logq "Node $node current queue length = $qlen"
	flush $logq
}

set dRNG [new RNG]
$dRNG seed [lindex $argv 0]
$dRNG default

# Create channel
# cf. ns-2.35/tcl/ex/wireless-mitf.tcl
set chan_1_ [new $val(chan)]

$ns_ node-config -adhocRouting $val(rp) \
				 -llType $val(ll) \
			 	 -macType $val(mac) \
			 	 -ifqType $val(ifq) \
			 	 -ifqLen $val(ifqlen) \
			 	 -antType $val(ant) \
			 	 -propType $val(prop) \
			 	 -phyType $val(netif) \
			 	 -channel $chan_1_ \
			 	 -topoInstance $topo \
			 	 -agentTrace ON\
			 	 -routerTrace OFF \
			 	 -macTrace ON \
			 	 -movementTrace OFF			

# ======================================================================
# Create the specified number of mobilenodes [$val(nn)] and "attach" them
# to the channel. 
# Here two nodes are created : node(0) and node(1)
# ======================================================================

set node_(0) [$ns_ node]
$node_(0) set X_ 3
$node_(0) set Y_ 100
$node_(0) set Z_ 0
set sw_(0) [new Agent/SWiFi]
$ns_ attach-agent $node_(0) $sw_(0)

for {set i 1} {$i < $val(nn) } {incr i} {
	set node_($i) [$ns_ node]	
	$node_($i) random-motion 0		;# disable random motion
	$node_($i) set X_ [expr 3.0 + $distance([expr $i - 1])]
	$node_($i) set Y_ 100
	$node_($i) set Z_ 0
	set sw_($i) [new Agent/SWiFi]
	$ns_ attach-agent $node_($i) $sw_($i)
	set n_rx($i) 0
	set avg_throughput_i($i) 0
	set throughput_i($i) 0
}

# ======================================================================
# Specify events
# ======================================================================

set mymac [$node_(0) set mac_(0)]
$ns_ at 0.0 "$sw_(0) mac $mymac"
$ns_ at 0.5 "$sw_(0) server"
#$mymac setTxFeedback 1

for {set i 1} {$i < $val(nn)} {incr i} {
	$ns_ connect $sw_($i) $sw_(0)
	set cmd "$sw_(0) register $i [lindex $reliability [expr $i - 1]]"
	#puts "register cmd: $cmd"
	$ns_ at [expr 3.0 + 0.1*$i] $cmd
}

if {0 == [string compare $func "reliability"]} {
	set num_runs   21
	set delta_dist 100
} elseif {0 == [string compare $func "pcf"]} {
	set num_runs   10
} else {
	set num_runs   1
}
set num_slots  [expr $interval * 1000]
if {0 != [string compare $func "delay"]} {
	set slot 0.01
} else {
	# RTT is acquired from measurements in Problem 1&2.
	set rtt 0.001625
	set slot [expr 2 * $rtt]
}
set period     [expr $num_slots * $slot]

set rand_min 0
set rand_max 2


proc rand_int { min max } {
	return [expr {int(rand()*($max-$min+1) + $min)}]
}

if {0 != [string compare $mode "downlink"]} {
	set command "$sw_(0) poll"
} else {
	set command "$sw_(0) send"
}
for {set k 0} {$k < $num_runs} {incr k} {
	if {0 == [string compare $func "reliability"] && [expr $k > 0]} {
		for {set i 1} {$i < $val(nn)} {incr i} {
			set distance($k) [expr $delta_dist * $k]
			$ns_ at [expr $period*($k + 1) - 0.002] \
				"$node_($i) set X_ [expr 3.0 + $distance($k)]"
		}
	}
	if {[expr $k > 0]} {
		for {set i 0} {$i < $val(nn)} {incr i} {
			$ns_ at [expr $period*($k + 1) - 0.001] "$sw_($i) restart"
		}
	}
	for {set i 0} {$i < $num_slots} {incr i} {
		$ns_ at [expr $period * ($k + 1) + $i * $slot] "$command"
		if { $i % $interval == 0} {
			# boi = beginning of interval
			$ns_ at [expr $period * ($k + 1) + $i * $slot - 0.0002] "$sw_(0) boi"
			for {set j 1} {$j < $val(nn)} {incr j} {
				set rand_val [rand_int $rand_min $rand_max]
				$ns_ at [expr $period * ($k + 1) + $i * $slot - 0.0001] "$sw_($j) pour $rand_val"
			}
		}
	}
	$ns_ at [expr $period*($k + 2) - 0.003] "$sw_(0) stat $k"
}

#$ns_ at 8000.0 "$sw_(0) report" 

$ns_ at 10000.0 "stop"
$ns_ at 10000.01 "puts \"NS EXITING...\" ; $ns_ halt"

#
#Mac/802_11 instproc txfailed {} {
#	upvar sw_(0) mysw
#	$mysw update_failed 
#}

#Mac/802_11 instproc txsucceed {} {
#	upvar sw_(0) mysw
#	$mysw update_delivered 
#}

#Mac/802_11 instproc brdsucced {} {
#}

proc stop {} {
	global ns_ tracefd logf func datf dist avg_throughput datl avg_throughput_i num_clients val
	$ns_ flush-trace
	close $tracefd
	close $logf
	if {0 == [string compare $func "pcf"]} {
		puts "Average throughput: $avg_throughput"
		puts $datf "$dist $avg_throughput $val(nn)"
		flush $datf
		for {set i 1} {$i <= $num_clients} {incr i} {
			puts $datl "$dist $i $avg_throughput_i($i) $val(nn)"
			flush $datl
		}
	}
	close $datf
	close $datl
}


puts "Starting simulation..."
$ns_ run
