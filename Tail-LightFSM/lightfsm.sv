module lightfsm(input  logic clk,
                input  logic reset,
                input  logic left, right,
                output logic la, lb, lc, ra, rb, rc);

  // put your logic here
  typedef enum logic [2:0] {S0, S1, S2, S3, S4, S5, S6} statetype;
  statetype state, nextstate;

  always_ff@(posedge clk, posedge reset)
    if (reset) state <= S0;
    else       state <= nextstate;

  always_comb
    case(state)
      S0: if (left)       nextstate = S1;
          else if (right) nextstate = S3;
	  else            nextstate = S0;
      S1:       	  nextstate = S2;
      S2:		  nextstate = S4;
      S3:		  nextstate = S6;
      S4:		  nextstate = S0;
      S5:		  nextstate = S0;
      S6:		  nextstate = S5;
      default:		  nextstate = S0;
    endcase

  assign la = (state == S1 | state == S2 | state == S4);
  assign lb = (state == S2 | state == S4);
  assign lc = (state == S4);
  assign ra = (state == S3 | state == S6 | state == S5);
  assign rb = (state == S6 | state == S5);
  assign rc = (state == S5);
  
endmodule

module testbench(); 
  logic        clk, reset;
  logic        left, right, la, lb, lc, ra, rb, rc;
  logic [5:0]  expected;
  logic [6:0]  hash;
  logic [31:0] vectornum, errors;
  logic [7:0]  testvectors[10000:0];

  // instantiate device under test 
  lightfsm dut(clk, reset, left, right, la, lb, lc, ra, rb, rc); 

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors and pulse reset
  initial 
    begin
      $readmemb("lightfsm.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; 
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {left, right, expected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if ({la, lb, lc, ra, rb, rc} !== expected) begin // check result 
        $display("Error: inputs = %b", {left, right});
        $display(" outputs = %b %b %b %b %b %b (%b expected)", 
          la, lb, lc, ra, rb, rc, expected); 
        errors = errors + 1; 
      end
      vectornum = vectornum + 1;
      hash = hash ^ {la, lb, lc, ra, rb, rc};
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 8'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("Hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 
 
