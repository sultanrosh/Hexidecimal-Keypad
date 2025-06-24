`timescale 1ns/1ps

// =============================================================
// Testbench: Hex_Keypad_tb
// Purpose: Full testbench with individual key signals (K0-K15)
//          for easier waveform interaction and debugging.
// =============================================================

module Hex_Keypad_tb;
  reg clock;          // Clock signal
  reg reset;          // Reset signal

  // Declare each key as a separate signal for visibility in waveform viewer
  reg K0, K1, K2, K3, K4, K5, K6, K7;
  reg K8, K9, K10, K11, K12, K13, K14, K15;

  // Concatenate all individual keys into a single 16-bit vector for module use
  wire [15:0] Key = {
    K15, K14, K13, K12,
    K11, K10, K9,  K8,
    K7,  K6,  K5,  K4,
    K3,  K2,  K1,  K0
  };

  wire [3:0] Col;     // Column output from FSM
  wire [3:0] Row;     // Row signal from Row_Signal module
  wire S_Row;         // Synchronized Row activity signal
  wire [3:0] Code;    // Output decoded key code
  wire Valid;         // Indicates valid key press

  // Generate clock signal: toggles every 5ns
  initial clock = 0;
  always #5 clock = ~clock;

  // Instantiate Row_Signal module
  Row_Signal row_logic(
    .Row(Row),
    .Key(Key),
    .Col(Col)
  );

  // Instantiate Synchronizer module
  Synchronizer synch_test(
    .S_Row(S_Row),
    .Row(Row),
    .clock(clock),
    .reset(reset)
  );

  // Instantiate FSM module
  Hex_Keypad_Grayhill_072 keypad_fsm(
    .Row(Row),
    .S_Row(S_Row),
    .clock(clock),
    .reset(reset),
    .Code(Code),
    .Valid(Valid),
    .Col(Col)
  );

  initial begin
    // Create VCD waveform file and dump all relevant signals
    $dumpfile("dump.vcd"); // Create dump file
    $dumpvars(1, Hex_Keypad_tb); // Dump top-level signals

    // Dump individual key signals for easy clicking in waveform viewer
    $dumpvars(0, K0, K1, K2, K3, K4, K5, K6, K7);
    $dumpvars(0, K8, K9, K10, K11, K12, K13, K14, K15);

    // Aha! We declare each key as an individual signal (K0-K15),
    // then pack them into the Key[15:0] bus for logic modules.
    // This way, each key appears as a named clickable signal in the waveform,
    // making debugging and test control much easier.

    // Reset system
    reset = 1;
    {K15,K14,K13,K12,K11,K10,K9,K8,K7,K6,K5,K4,K3,K2,K1,K0} = 16'b0;
    #10;
    reset = 0;
    #10;

    // Test 1: Press key 0 and hold
    K0 = 1; #50;

    // Test 2: Release key 0 and press key 1
    K0 = 0; K1 = 1; #50;

    // Test 3: Press keys 5 and 6 together
    K1 = 0; K5 = 1; K6 = 1; #20;

    // Test 4: Press all keys then release quickly
    {K15,K14,K13,K12,K11,K10,K9,K8,K7,K6,K5,K4,K3,K2,K1,K0} = 16'hFFFF; #10;
    {K15,K14,K13,K12,K11,K10,K9,K8,K7,K6,K5,K4,K3,K2,K1,K0} = 16'b0; #10;

    // Test 5: Press key 9 fast, release, then press again
    K9 = 1; #5; K9 = 0; #5; K9 = 1; #5;

    // Test 6: Rapid switching between key 1 and 4
    K1 = 1; #5; K1 = 0; K4 = 1; #5; K4 = 0; K1 = 1; #5; K1 = 0; K4 = 1; #5;

    // Test 7: Hold keys 2 and 3 while switching to keys C and D
    K2 = 1; K3 = 1; #10;
    K2 = 0; K3 = 0; K12 = 1; K13 = 1; #5;
    K12 = 0; K13 = 0; K2 = 1; K3 = 1; #5;
    K2 = 0; K3 = 0; K12 = 1; K13 = 1; #5;

    // Test 8: Two keys pressed and released quickly
    K0 = 1; K1 = 1; #5;
    K0 = 0; K1 = 0; #5;

    // Test 9: All keys pressed/released rapidly
    {K15,K14,K13,K12,K11,K10,K9,K8,K7,K6,K5,K4,K3,K2,K1,K0} = 16'hFFFF; #5;
    {K15,K14,K13,K12,K11,K10,K9,K8,K7,K6,K5,K4,K3,K2,K1,K0} = 16'b0; #5;
    {K15,K14,K13,K12,K11,K10,K9,K8,K7,K6,K5,K4,K3,K2,K1,K0} = 16'hFFFF; #5;
    {K15,K14,K13,K12,K11,K10,K9,K8,K7,K6,K5,K4,K3,K2,K1,K0} = 16'b0; #5;

    // Test 10: One key held, other switches every #5
    K0 = 1; K4 = 1; #5;
    K4 = 0; K5 = 1; #5;
    K5 = 0; K6 = 1; #5;
    K6 = 0; K7 = 1; #5;
    K7 = 0; K0 = 0; #5;

    // Test 11: Proper pace switching
    K1 = 1; #20; K1 = 0; K2 = 1; #20;
    K2 = 0; K1 = 1; #20; K1 = 0; K2 = 1; #20;

    // Test 12: Switch between two pairs
    K4 = 1; K5 = 1; #30; K4 = 0; K5 = 0;
    K6 = 1; K7 = 1; #30; K6 = 0; K7 = 0;
    K4 = 1; K5 = 1; #30; K4 = 0; K5 = 0;
    K6 = 1; K7 = 1; #30; K6 = 0; K7 = 0;

    // End simulation
    $finish;
  end
endmodule
