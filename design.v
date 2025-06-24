// ===============================
// Module: Row_Signal
// Purpose: Decodes pressed key position based on active column
// ===============================

module Row_Signal(
  input wire [15:0] Key,     // Key is a 16-bit input representing the 4x4 keypad switches
  input wire [3:0] Col,      // Col is a 4-bit input representing the active column lines
  output reg [3:0] Row       // Row is a 4-bit output indicating which row(s) are active
);

  always @(*) begin // Trigger block whenever any input changes (combinational)
    Row[0] = (Key[0] && Col[0]) || (Key[1] && Col[1]) || (Key[2] && Col[2]) || (Key[3] && Col[3]); // Set Row[0] if any key in row 0 is pressed
    Row[1] = (Key[4] && Col[0]) || (Key[5] && Col[1]) || (Key[6] && Col[2]) || (Key[7] && Col[3]); // Set Row[1] if any key in row 1 is pressed
    Row[2] = (Key[8] && Col[0]) || (Key[9] && Col[1]) || (Key[10] && Col[2]) || (Key[11] && Col[3]); // Set Row[2] if any key in row 2 is pressed
    Row[3] = (Key[12] && Col[0]) || (Key[13] && Col[1]) || (Key[14] && Col[2]) || (Key[15] && Col[3]); // Set Row[3] if any key in row 3 is pressed
  end

endmodule


// ===============================
// Module: Synchronizer
// Purpose: Double flip-flop synchronizer for Row signal
// ===============================

module Synchronizer(
  input wire [3:0] Row,      // Row is a 4-bit asynchronous signal from keypad
  input wire clock,          // Clock input to drive synchronization
  input wire reset,          // Reset to clear the synchronizer state
  output reg S_Row           // Synchronized output signal to logic domain
);

  reg stage1;                // stage1 is first D flip-flop to catch the input
  reg stage2;                // stage2 is second D flip-flop to stabilize the signal

  wire any_row_active;       // any_row_active goes high if any row bit is high
  assign any_row_active = |Row; // Reduction OR: true if any Row[i] is high

  always @(posedge clock or posedge reset) begin // Trigger on rising clock edge or reset
    if (reset) begin // If reset is high, clear both flip-flops
      stage1 <= 0; // Reset first stage
      stage2 <= 0; // Reset second stage
    end else begin // Otherwise, shift the row signal into flip-flops
      stage1 <= any_row_active; // First stage gets current row signal
      stage2 <= stage1; // Second stage gets delayed version
    end
  end

  always @(*) begin // Combinational output block
    S_Row = stage2; // Output synchronized signal from second stage
  end

endmodule


// ===============================
// Module: Hex_Keypad_Grayhill_072
// Purpose: FSM to scan keypad and decode keypress
// ===============================

module Hex_Keypad_Grayhill_072(
  input [3:0] Row,             // Row input from keypad (synchronized)
  input S_Row,                 // One-bit signal if any row is active
  input clock,                 // Clock for FSM
  input reset,                 // Reset to initialize FSM
  output reg [3:0] Code,       // Output key code in hex
  output wire Valid,                // Signal that a valid key was pressed
  output reg [3:0] Col         // Column drive signal to keypad
);

  parameter S_0 = 6'b000001,   // S_0: Idle state, scan for activity
            S_1 = 6'b000010,   // S_1: Check column 0
            S_2 = 6'b000100,   // S_2: Check column 1
            S_3 = 6'b001000,   // S_3: Check column 2
            S_4 = 6'b010000,   // S_4: Check column 3
            S_5 = 6'b100000;   // S_5: Wait for key release

  reg [5:0] state, next_state; // FSM state and next state variables
  
  reg valid_internal;
  assign Valid = valid_internal;

  always @(*) begin
  	valid_internal = ((state == S_1) || (state == S_2) || (state == S_3) || (state == S_4)) && (Row != 4'b0000);
   end


  //assign Valid = ((state == S_1) || (state == S_2) || (state == S_3) || (state == S_4)) && (|Row); // Valid if in scan state and row is active

  always @(*) begin // Combinational decoder to convert Row and Col to hex code
    case ({Row, Col}) // Combine Row and Col into 8-bit value
      8'b0001_0001: Code = 4'h0; // Row 0, Col 0 => Key 0
      8'b0001_0010: Code = 4'h1;
      8'b0001_0100: Code = 4'h2;
      8'b0001_1000: Code = 4'h3;
      8'b0010_0001: Code = 4'h4;
      8'b0010_0010: Code = 4'h5;
      8'b0010_0100: Code = 4'h6;
      8'b0010_1000: Code = 4'h7;
      8'b0100_0001: Code = 4'h8;
      8'b0100_0010: Code = 4'h9;
      8'b0100_0100: Code = 4'hA;
      8'b0100_1000: Code = 4'hB;
      8'b1000_0001: Code = 4'hC;
      8'b1000_0010: Code = 4'hD;
      8'b1000_0100: Code = 4'hE;
      8'b1000_1000: Code = 4'hF;
      default:       Code = 4'h0; // Default if unmatched
    endcase
  end

  always @(posedge clock or posedge reset) begin // State register updated on clock or reset
    if (reset)
      state <= S_0; // Set to idle state on reset
    else
      state <= next_state; // Otherwise go to next state
  end

  always @(*) begin // Next-state and column control logic
    next_state = state; // Default next state is current state
    Col = 4'b0000; // Default column value

    case (state)
      S_0: begin Col = 4'b1111; if (S_Row) next_state = S_1; end // Idle: check for key press
      S_1: begin Col = 4'b0001; if (Row != 4'b0000) next_state = S_5; else next_state = S_2; end // Scan Col 0
      S_2: begin Col = 4'b0010; if (Row != 4'b0000) next_state = S_5; else next_state = S_3; end // Scan Col 1
      S_3: begin Col = 4'b0100; if (Row != 4'b0000) next_state = S_5; else next_state = S_4; end // Scan Col 2
      S_4: begin Col = 4'b1000; if (Row != 4'b0000) next_state = S_5; else next_state = S_0; end // Scan Col 3
      S_5: begin Col = 4'b1111; if (Row != 4'b0000) next_state = S_0; end // Wait for release
    endcase
  end

endmodule

 
      
 
// ===============================
// AHA MOMENTS (PERSONAL NOTES)
// ===============================
// 1. wire is a floating signal used for continuous logic evaluation (combinational paths).
//    It doesn’t store values; it just represents a real-time connection between hardware elements.
//    → Simple terms: wire is a literal physical thing that doesn’t hold a value, just connects logic.

// 2. reg is not an actual register, but a signal that can hold a value between clock edges.
//    It's used inside procedural blocks (like always) and represents storage (like flip-flops).
//    → Simple terms: reg stores values between clock edges; it’s like memory, not just wiring.

// 3. parameter is like a named constant that assigns a fixed value to a label.
//    It’s useful for defining FSM states, constants, or configuration options.
//    → Simple terms: parameter is “this name equals this constant value” and doesn’t change.

// 4. one-hot encoding is a state encoding technique where each state has only one bit set to '1'.
//    It simplifies logic since you don’t need decoding logic—hardware can directly read the active state.
//    → Simple terms: “just look at the hot bit to know the state”—no extra decoding needed.

// 5. <= (non-blocking assignment) is used for sequential logic to model actual hardware flip-flops.
//    = (blocking assignment) is used mostly for combinational logic.
//    → Simple terms: <= stores data with the clock; = is for logic that runs immediately.

// 6. always @(*) is used to describe combinational logic that should evaluate any time its inputs change.
//    → Simple terms: means “always check when anything involved changes.”


// AHA: D flip-flops store data only on the positive edge of the clock — this prevents glitches from async signals
// I understood that they act like gated memory and don't respond immediately, which keeps signals stable

// AHA: Double D flip-flops (a synchronizer) are used to delay and stabilize async inputs before they enter FSM logic
// I saw that using two flip-flops in a row avoids metastability issues when sampling row signals from a keypad

// AHA: The second D flip-flop ensures data is sampled cleanly in sync with the FPGA’s clock domain (D- Flip Flop clock is in sync with FPGA CLOCK
// I realized this avoids race conditions and logic errors due to unsynchronized hardware button presses

// AHA: wire is for combinational logic and physical signal lines; reg is for storing values across clock cycles
// I learned that wire doesn’t "store" anything — it's just used to connect components logically like wires on a board

// AHA: <= is for non-blocking assignments that get scheduled on the next clock edge — used in sequential logic
// I understood that = assigns immediately (used in combinational logic) while <= schedules the update (like a register)

//– AHA: One-hot encoding assigns a unique bit for each state to reduce decoding complexity
// I understood that using one-hot makes it easier to tell which state we’re in since only one bit is active at a time

// AHA: parameter in Verilog is a named constant — it’s like giving a state or config value a readable label
// I realized it's just a way to write more readable code, e.g., parameter S_0 = 6'b000001 for FSM state encoding

// AHA: always @(*) triggers whenever any signal in the RHS changes — it's used for combinational logic
// I now see that this lets the output update instantly when inputs change, which is ideal for logic like assigning S_row

// AHA: Instantiation labels like `row_signal_instance` are just for organizing your testbench
// I realized I can name modules however I want for clarity — they’re like variable names for hardware modules

// AHA: .Row(Row) means "connect the module’s Row port to the signal named Row in the testbench"
// I now get that the left side is the module's internal port name, and the right is the external signal we’re wiring in

// AHA: The $monitor statement is like a printf that updates on signal changes, helping debug signal transitions
// I understood this lets me trace what's going wrong at what time without manually looking at the waveform

// AHA: #5 is a delay of 5 simulation time units, not necessarily 5 clock cycles — it delays actions in simulation
// I clarified that this is purely for testbench timing, not related to actual hardware clock edges

// AHA: If you don't use a synchronizer, async button input can cause glitches or unpredictable FSM behavior
// I finally got why unclocked input from a keypad must be conditioned before being trusted in logic

// Valid is declared as a wire because it is driven by a continuous assign statement 
// and depends on live combinational inputs (Row, state), not stored sequentially

// AHA: output wire must be declared explicitly if it's driven by an assign statement
//      I learned that 'assign' can only drive wire types, not reg or undeclared signals




/*
module Synchronizer(
  input[3:0] Row,
  input clock,
  input reset
  output reg S_row
)
  
  reg A_Row;
  
  always @(negedge clock or posedge reset)
    begin
      if(reset)
        A_Row <= 0;
      	S_Row <= 0;
    end
  	   else
         begin
           A_Row <=(Row[0]||Row[1]||Row[3]);
           S_Row <= A_Row;
         end
  end
endmodule 
*/     

/*
module Synchronizer(
  input a_synch
  input clock
  input reset
  output a_row
  output s_row
)
  
  always @(posedge)
    begin
      if (a_synch == 1 && clock == 1)
        a_row <= a_synch;
      else if (clock == 0)
*/          
 
  
  
  
