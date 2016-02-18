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
set val(nn)             2                          ;# number of mobilenodes
set val(rp)             DumbAgent                  ;# routing protocol


# ======================================================================
# Main Program
# ======================================================================


# ======================================================================
# Initialize Global Variables
# ======================================================================

set ns_		[new Simulator]
set tracefd     [open WiFi_downlink.tr w]
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
Propagation/Shadowing set pathlossExp_ 0.0			 
Mac/802_11 set dataRate_  11.0e6
Mac/802_11 set basicRate_ 11.0e6
Mac/802_11 set CWMin_         1
Mac/802_11 set CWMax_         1
Mac/802_11 set PreambleLength_  144                   ;# long preamble 
Mac/802_11 set RTSThreshold_  5000
Mac/802_11 set PLCPDataRate_  1.0e6                   ;# 1Mbps
Mac/802_11 set ShortRetryLimit_       1               ;# retransmittions
Mac/802_11 set LongRetryLimit_        1               ;# retransmissions
Mac/802_11 set TxFeedback_ 0;

#Agent/SWiFi set packet_size_ 160
#Agent/SWiFi set slot_interval_ 0.01

set dRNG [new RNG]
$dRNG seed [lindex $argv 0]
$dRNG default

$ns_ node-config -adhocRouting $val(rp) \
				 -llType $val(ll) \
			 	 -macType $val(mac) \
			 	 -ifqType $val(ifq) \
			 	 -ifqLen $val(ifqlen) \
			 	 -antType $val(ant) \
			 	 -propType $val(prop) \
			 	 -phyType $val(netif) \
			 	 -channelType $val(chan) \
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
	$node_($i) set X_ [expr 3.0 + $i*1]
	$node_($i) set Y_ 100
	$node_($i) set Z_ 0
	set sw_($i) [new Agent/SWiFi]
	$ns_ attach-agent $node_($i) $sw_($i)
}

# ======================================================================
# Specify events
# ======================================================================

set mymac [$node_(0) set mac_(0)]
$ns_ at 0.0 "$sw_(0) mac $mymac"
$ns_ at 0.5 "$sw_(0) server"
#$mymac setTxFeedback 1

$ns_ connect $sw_(1) $sw_(0)
#$ns_ at 3.0 "$sw_(1) register 200 1 0 1"

set period     100.0
set num_runs   1
set num_trans  10000

for {set k 0} {$k < num_runs} {incr k} {
	if [expr $k > 0] {
		$ns_ at [expr $period*($k + 1) - 0.001] "$sw_(0) restart" 		
	}
	for {set i 0} {$i < num_trans} {incr i} {
		$ns_ at [expr $period*($k + 1) + $i/100.0] "$sw_(0) send"
	}
}

#$ns_ at 8000.0 "$sw_(0) report" 

$ns_ at 10000.0 "stop"

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
    global ns_ tracefd
    #$ns_ flush-trace
    close $tracefd
}

$ns_ run
