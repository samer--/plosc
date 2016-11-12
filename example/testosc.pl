:- module(testosc, [osc/1]).

:- use_module(library(plosc)).

:- dynamic server/2.

ack(_,_) :- writeln(ack_received).

echo(P,A) :- writeln(msg(P,A)).
echo(Sender,Time,P,A) :- 
	format('from ~w at ~w: ~w.\n',[Sender,Time,msg(P,A)]),
	(	Time=osc_immed -> osc_send(Sender,'/ack',[])
	;	osc_time_ts(T0,Time) -> osc_send(Sender,'/ack',[],T0+1)
	).

forward(_,[string(Host),int(Port),string(Msg)|Args]) :- 
	osc_mk_address(Host,Port,Addr),
	osc_send(Addr,Msg,Args).

sched_at(_,[double(Delay),string(Host),int(Port),string(Msg)|Args]) :- 
	get_time(Now), Time is Now+Delay,
	osc_mk_address(Host,Port,Addr),
	osc_send(Addr,Msg,Args,Time).

osc(init(Port)) :- osc_mk_server(Port,S), 
	osc_mk_address(localhost,Port,P),
	osc_add_handler_x(S, '/echox', any, echo),
	osc_add_handler(S, '/echo',  any, echo),
	osc_add_handler(S, '/fwd',   any, forward),
	osc_add_handler(S, '/after', any, sched_in),
	osc_add_handler(S, '/ack',   any, ack),
	assert(server(S,P)).

osc(start) :- server(S,_), osc_start_server(S), at_halt(osc(stop)).
osc(stop)  :- server(S,_), osc_stop_server(S).
osc(run)   :- server(S,_), osc_run_server(S).

osc(send(M,A)) :- server(_,P), osc_send(P,M,A).
osc(send(M,A,T)) :- server(_,P), osc_send(P,M,A,T).
osc(send_from(M,A,T)) :- server(S,P), osc_send_from(S,P,M,A,T).
	
run(Port) :- osc(init(Port)),
	nl, 
	writeln('Commands:'), nl,
	writeln('   osc(start)  to start the server in a new thread.'),
	writeln('   osc(stop)   to stop the server thread.'),
	writeln('   osc(run)    run the server synchronously in the current thread.'),
	writeln('   osc(send(Path,Args)) send message with Path and Args.'),
	writeln('   osc(send(Path,Args,Time)) send timestamped message with Path and Args.'),
	nl,
	writeln('OSC messages:'), nl,
	writeln('   /echo <<args>>'), 
	writeln('         write messages and arguments.'),
	writeln('   /echox <<args>>'), 
	writeln('         write messages and arguments with sender and timestamp.'),
	writeln('   /fwd   s<host> i<port> s<path> <<args>>'),
	writeln('         forward message to given server.'),
	writeln('   /after d<delay> s<host> i<port> s<path> <<args>>'),
	writeln('         forward message after delay.'),
	writeln('   /plosc/stop'),
	writeln('         stop the synchronous server.'),
	nl.
