# plosc
OSC client and server for SWI Prolog


This module allows Prolog code to send and receive Open Sound Control (OSC)
messages using liblo.


## PREREQUISITES

- SWI Prolog
- liblo


## INSTALLATION

First check and edit as necessary the variables in the top half of the
root Makefile.

The build process installs a Prolog module file and a foreign library
to ~/lib/prolog by default. If you wish to change this, edit the root Makefile
accordingly and be sure that the referenced directories are in your
Prolog file_search_path.

In the root directory of this package, type

	$ make install



## USAGE

This example talks to a Supercollider server running on the local machine
listening to port 57110. It sends a message to create a Synth from SynthDef 'Square'
with some given parameters.

```
:- use_module(library(plosc)).
:- dynamic osc_addr/1.

init :-
	osc_mk_address(localhost,57110, A),
	assert(osc_addr(A)).

bing :-
	osc_addr(A),
	get_time(T),
	osc_send(A,'/s_new',[string('Square'),int(-1),int(0),int(1),string('freq'),float(440)],T).

:- init, bing.
```


The following code shows how to make an OSC server.
```
	:- use_module(library(plosc)).

	dumposc(P,A) :- writeln(msg(P,A)).
	forward(P,[string(Host),int(Port),string(Msg)|Args]) :- 
		osc_mk_address(Host,Port,Addr),
		osc_send(Addr,Msg,Args).

	:- osc_mk_server(7770,S), 
		osc_mk_address(localhost,7770,P),
		osc_add_handler(S,'/fish',any,dumposc),
		osc_add_handler(S,'/fwd',any,forward),
		assert(server(S,P)).

	% start and stop the asynchronous server
	start :- server(S,_), osc_start_server(S).
	stop  :- server(S,_), osc_stop_server(S).

	% run the server synchronously - send /plosc/stop to stop it
	run   :- server(S,_), osc_run_server(S).

	% send a message to the current server
	send(M,A) :- server(_,P), osc_send(P,M,A).
```
	

To run the code in the example directory, from the shell type

	$ swipl -s example/testosc.pl



## BUGS AND LIMITATIONS

The message sending predicates are limited in the types of arguments
they can use - currently, the following functors can be used:

	Head functor      OSC Type
	------------      --------
	int               i - 32 bit integer
	float             f - Single precision float
	double            d - Double precision float
	string            s - String
	symbol            S - Symbol
	true              T - True
	false             F - False
	nil               N - Nil
	inf               I - Infinitum or Impuse

BLOBs, 64 bit integers, 8 bit integers, time tags and MIDI messages cannot be sent.
However, all types can be received except BLOBs.


