// Defining the rooms as global variable of type 'roomnum'
typedef enum logic[6:0] {CC, TT, RR, SS, DD, VV, GG} roomnum;

// Top-level module connecting the rest two-fsm
module adventuregame(input  logic clk, reset,
                     input  logic n, s, e, w,
                     output logic win, die);
  roomnum state;
  // room instance will be called all the time but has an updated value on posedge clk
  // since roomFSM updates value at that time
  // Also, this means this is the most naive implementation
  room instance1(clk, reset, n, s, e, w, state, win, die);
endmodule

// The roomFSM keeping check in which room we are
module room(input  logic clk, reset,
	    input  logic n, s, e, w,
	    output roomnum name, 
	    output logic win, die);
  roomnum state, nextstate;
  logic has_sword;
  always_ff@(posedge clk, posedge reset)
    if (reset) state <= CC;
    else       state <= nextstate;
  always_comb
    case(state)
      CC: nextstate = TT;
      TT: nextstate = RR;
      RR: if (w) nextstate = SS;
          else   nextstate = DD;
      SS: nextstate = RR;
      DD: if (has_sword) nextstate = VV;
	  else	         nextstate = GG;
      VV: nextstate = VV;
      GG: nextstate = GG;
      default: nextstate = CC;
    endcase
  sword instance2(clk, reset, state, nextstate, has_sword);
  assign win = (state == VV);
  assign die = (state == GG);
  assign name = state;
endmodule

// The swordFSM keeping the note if we have the sword
module sword(input  logic clk, reset, 
	     input roomnum S, roomnum NS,
	     output logic has_sword);
  always_ff@(posedge clk & S == RR & NS == SS, posedge reset)
    if (reset) has_sword <= 1'b0;
    else       has_sword <= 1'b1;
endmodule

module testbench(); 
  logic        clk, reset;
  logic        n, s, e, w, win, die, winexpected, dieexpected;
  logic [31:0] vectornum, errors;
  logic [5:0]  testvectors[10000:0];
  logic [6:0]  hash;

  // instantiate device under test 
  adventuregame dut(clk, reset, n, s, e, w, win, die); 

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors 
  // and pulse reset
  initial 
    begin
      $readmemb("adventuregame.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; #70; reset = 1; #10; reset = 0;
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {n, s, e, w, winexpected, dieexpected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if (win !== winexpected || die !== dieexpected) begin // check result 
        $display("Error: inputs = %b", {n, s, e, w});
        $display(" state = %b", dut.state);
        $display(" outputs = %b %b (%b %b expected)", 
                 win, die, winexpected, dieexpected); 
        errors = errors + 1; 
      end
      hash = hash ^ {win, die};
      hash = {hash[5:0], hash[6]^hash[5]};
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 6'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 

