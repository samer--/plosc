/*
 * Prolog library for sending and receiving OSC messages
 * Samer Abdallah (2009)
*/
	  
:- module(plosc, [
		osc_now/2			% -Seconds:int, -Fraction:int
	,	osc_now/1			% -TS:osc_timestamp
	,	osc_mk_address/3	% +Host:atom, +Port:nonneg, -Ref:osc_addr
	,	osc_split_address/3	% +Ref:osc_addr, -Host:atom, -Port:nonneg
	,	osc_is_address/1  % +Ref
	,	osc_send/3			% +Ref, +Path:atom, +Args:list(osc_arg)
	,	osc_send/4			% +Ref, +Path:atom, +Args:list(osc_arg), +Time:float
	,	osc_send_from/5	% +Ref, +Ref, +Path:atom, +Args:list(osc_arg), +Time:float
	,	osc_mk_server/2	% +Port:nonneg, -Ref
	,	osc_start_server/1 % +Ref
	,	osc_stop_server/1  % +Ref
	,	osc_run_server/1   % +Ref
	,	osc_del_handler/3  % +Ref, +Path:atom, +Types:list(osc_arg)
	,	osc_add_handler/4  % +Ref, +Path:atom, +Types:list(osc_arg), +Goal:callable
	,	osc_add_handler_x/4  % +Ref, +Path:atom, +Types:list(osc_arg), +Goal:callable

	,	osc_time_ts/2
	]).
	
:- meta_predicate osc_add_handler(+,+,+,2).
:- meta_predicate osc_add_handler_x(+,+,+,4).

/** <module> OSC server and client

	==
	time == float.
	osc_timestamp ---> osc_ts(int,int).
	==
*/
:-	use_foreign_library(foreign(plosc)).

%% osc_mk_address(+Host:atom, +Port:nonneg, -Ref:osc_addr) is det.
%
%  Construct a BLOB atom representing an OSC destination.
%
%  @param Host is the hostname or IP address of the OSC receiver
%  @param Port is the port number of the OSC receiver
%  @param Ref is an atom representing the address

%% osc_split_address(+Ref:osc_addr,-Host:atom, -Port:nonneg) is det.
%
%  Deconstruct a BLOB atom representing an OSC destination.
%
%  @param Ref is an atom representing the OSC address
%  @param Host is the IP address of the OSC receiver
%  @param Port is the port number of the OSC receiver

%% osc_is_address(+Ref) is semidet.
%
%  Succeeds if Ref is an OSC address created by osc_mk_address/3

%% osc_send(+Ref:osc_addr, +Path:atom, +Args:list(osc_arg)) is det.
%% osc_send(+Ref:osc_addr, +Path:atom, +Args:list(osc_arg), +Time:time) is det.
%
%  Sends an OSC message scheduled for immediate execution (osc_send/3) or
%  at a given time (osc_send/4).
%
%  @param Ref is an OSC address BLOB as returned by osc_mk_address/3.
%  @param Path is an atom representing the OSC message path, eg '/foo/bar'
%  @param Args is a list of OSC message arguments, which can be any of:
%  	* string(+X:text)
%  	String as atom or Prolog string
%  	* symbol(+X:atom)
%  	* double(+X:float)
%  	Double precision floating point
%  	* float(+X:float)
%  	Single precision floating point
%  	* int(+X:integer)
%  	* true
%  	* false
%  	* nil
%  	* inf
%
osc_send(A,B,C) :- osc_send_now(A,B,C).
osc_send(A,B,C,T) :- T1 is T, osc_send_at(A,B,C,T1).

%% osc_send_from(+Server:osc_server, +Address:osc_addr, +Path:atom, +Args:list(osc_arg), +T:time) is det.
%
%	Like osc_send/4 but sets the return address to that of the given server.
osc_send_from(Srv,Targ,Path,Args,Time) :- T1 is Time, osc_send_from_at(Srv,Targ,Path,Args,T1).

%% osc_now(-Secs:integer,-Frac:integer) is det.
%
%  Gets the current OSC time in seconds and 1/2^64 ths of second.

%% osc_now(-TS:osc_timestamp) is det.
%
%  Gets the current OSC time as an OSC timestamp term.
osc_now(osc_ts(Secs,Fracs)) :- osc_now(Secs,Fracs).

%% osc_time_ts(+Time:float,-TS:osc_timestamp) is det.
%% osc_time_ts(-Time:float,+TS:osc_timestamp) is det.
%
%  Convert between floating point time as returned by get_time/1 and OSC
%  timestamp structure as returned by osc_now/1.
osc_time_ts(Time,osc_ts(Secs,Fracs)) :-
	(	var(Time) -> time_from_ts(Time,Secs,Fracs)
	;	time_to_ts(Time,Secs,Fracs)).

%% osc_mk_server(+Port:nonneg, -Ref:osc_server) is det.
%
%  Create an OSC server and return a BLOB atom representing it.
%
%  @param Port is the port number of the OSC server
%  @param Ref is an atom representing the server

%% osc_start_server(+Ref:osc_server) is det.
%
%  Run the OSC server referred to by Ref in a new thread. The new thread
%  dispatches OSC messages received to the appropriate handlers as registered
%  using osc_add_handler/4.

%% osc_stop_server(+Ref:osc_server) is det.
%
%  If Ref refers to a running server thread, stop the thread.

%% osc_run_server(+Ref:osc_server) is det.
%
%  The OSC server is run in the current thread, and does not return until
%  the message loop terminates. This can be triggered by sending the
%  message /plosc/stop to the server. Using this synchronous server
%  avoids creating a new thread and a new Prolog engine.

%% osc_add_handler( +Ref:osc_server, +Path:atom, +Types:list(osc_arg), +Goal:handler) is det.
%
%  This registers a callable goal to handle the specified message Path for the
%  OSC server referred to by Ref.
%  The handler type is =|handler == pred(+atom,+list(osc_arg)).|=
%
%  @param Types is a list of terms specifying the argument types that this handler
%               will match. The terms are just like those descibed in osc_send/3
%               and osc_send/4, except that the actual values are not used and
%               can be left as anonymous variables, eg [int(_),string(_)].
%               Alternatively, Types can be the atom 'any', which will match any
%               arguments.
%
%  @param Goal  is any term which can be called with call/3 with two further
%               arguments, which will be the message Path and the argument list, eg
%               call( Goal, '/foo', [int(45),string(bar)]).

osc_add_handler(Ref,Path,Types,Goal) :- osc_add_method(Ref,Path,Types,Goal).

%% osc_add_handler_x( +Ref:osc_server, +Path:atom, +Types:list(osc_arg), +Goal:handler_x) is det.
%
%  This registers a callable goal to handle the specified message Path for the
%  OSC server referred to by Ref.
%  The extended handler type is =|handler_x == pred(+osc_addr,+time,+atom,+list(osc_arg)).|=
%
%  @param Types is a list of terms specifying the argument types that this handler
%               will match. The terms are just like those descibed in osc_send/3
%               and osc_send/4, except that the actual values are not used and
%               can be left as anonymous variables, eg [int(_),string(_)].
%               Alternatively, Types can be the atom 'any', which will match any
%               arguments.
%
%  @param Goal  is any term which can be called with call/3 with four further
%               arguments, which will be the address of the sender, the timestamp of the 
%               message, message path and the argument list, eg
%               call( Goal, SomeOSCAddress, Time, '/foo', [int(45),string(bar)]).

osc_add_handler_x(Ref,Path,Types,Goal) :- osc_add_method_x(Ref,Path,Types,Goal).

%% osc_del_handler( +Ref:osc_server, +Path:atom, +Types:list(osc_arg)) is det.
%
%  Deregister a message handler previously registered with osc_add_handler/4.

osc_del_handler(Ref,Path,Types)      :- osc_del_method(Ref,Path,Types).


prolog:message(error(osc_error(Num,Msg,Path)), ['LIBLO error ~w: ~w [~w]'-[Num,Msg,Path] |Z],Z).
