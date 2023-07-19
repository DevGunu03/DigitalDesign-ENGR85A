module twoscomp(input  logic clk,
                input  logic reset,
                input  logic a,
                output logic n);

  typedef enum logic {C0, C1} statetype;
  statetype state, nextstate;
  // Defines C0 = 0 and C1 = 1

  logic a_prev;
  // Defining some internal signals for holding up prev. values of a

  // state register logic
  always_ff@(posedge clk, posedge reset)
    if (reset) state <= C1;
    else       state <= nextstate;
  // nextstate is always C1 initialised because of default case

  // next-state logic
  always_comb
    case(state)
      C1: if (a) nextstate = C0;
	  else   nextstate = C1;
      C0:        nextstate = C0;
      default:   nextstate = C1;
    endcase

  // output logic
  flopr object2(clk, reset, a, a_prev);
  // Uses asynchronously resettable flip-flop
  assign n = (nextstate == C0 ? ~a_prev: a_prev);
  // Unless state changes, don't output the values of a
endmodule


// asynchronously resettable flip-flop
module flopr(input  logic clk, reset, d,
            output logic q);
            
  always_ff @(posedge clk or posedge reset)
    if (reset) q <= 0; // resets state to 0 on reset
    else       q <= d;
endmodule

// asynchronously settable flip-flop
module flops(input  logic clk, reset, d,
            output logic q);
            
  always_ff @(posedge clk or posedge reset)
    if (reset) q <= 1;  // sets state to 1 on reset
    else       q <= d;
endmodule

module testbench(); 
  logic        clk, reset;
  logic        a, n, nexpected;
  logic [6:0]  hash;
  logic [31:0] vectornum, errors;
  logic [1:0]  testvectors[10000:0];

  // instantiate device under test 
  twoscomp dut(clk, reset, a, n);

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors and pulse reset
  initial 
    begin
      $readmemb("twoscomp.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; 
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {a, nexpected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if (n !== nexpected) begin // check result 
        $display("Error: input = %b", a);
        $display(" output = %b (%b expected)", n, nexpected); 
        errors = errors + 1; 
      end
      vectornum = vectornum + 1;
      hash = hash ^ n;
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 2'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("Hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 
