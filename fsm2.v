//TEAM NAME: TECHGIRLS
//COLLEGE NAME: PARUL INSTITUTE OF TECHNOLOGY
//PROBLEM STATEMENT:  Design and Implementation of Automated Teller Machine (FSM) Controller

`define true 1'b1
`define false 1'b0

`define FIND 1'b0
`define AUTHENTICATE 1'b1

`define WAITING               4'b0000
`define GET_PIN               4'b0001
`define MENU                  4'b0010
`define BALANCE               4'b0011
`define WITHDRAW              4'b0100
`define WITHDRAW_SHOW_BALANCE 4'b0101
`define TRANSACTION           4'b0110
`define EXIT                  4'b0111
`define OTP_WAITING           4'b1000
`define OTP_VALIDATED         4'b1001


module fsm2(
  input [11:0] accNumber,
  input [3:0] pin,
  input action,
  input deAuth,
  input reset, // Added reset input to reset the failed attempts counter
  output reg  wasSuccessful,
  output reg [3:0] accIndex,
  output reg exitOnThreeFailures // Signal to exit after three failed attempts
);

  reg [11:0] account_db [0:9];
  reg [3:0] pin_db [0:9];
  reg [2:0] failedAttempts;

  // Initializing the database with arbitrary accounts
  initial begin
    account_db[0] = 12'd1234; pin_db[0] = 4'b0000;
    account_db[1] = 12'd5673; pin_db[1] = 4'b0001;
    account_db[2] = 12'd3487; pin_db[2] = 4'b0010;
    account_db[3] = 12'd2352; pin_db[3] = 4'b1111;
    account_db[4] = 12'd9999; pin_db[4] = 4'b1100;
    account_db[5] = 12'd3546; pin_db[5] = 4'b0101;
    account_db[6] = 12'd7896; pin_db[6] = 4'b0110;
    account_db[7] = 12'd6688; pin_db[7] = 4'b0111;
    account_db[8] = 12'd6776; pin_db[8] = 4'b1011;
    account_db[9] = 12'd1356; pin_db[9] = 4'b1001;
  end

  always @(deAuth) begin
    if (deAuth == `true)
      wasSuccessful = 1'bx;
  end

  // Looping through the database, trying to find a match for the given accNumber and pin
  // If action is set to find, it'll simply try to find a match for the given accNumber and returns its index
  integer i;
  always @(accNumber or pin) begin
    wasSuccessful = `false;
    accIndex = 0;

    // Loop through the database
    for (i = 0; i < 10; i = i + 1) begin
      // Found a match for accNumber
      if (accNumber == account_db[i]) begin
        if (action == `FIND) begin
          wasSuccessful = `true;
          accIndex = i;
        end
        if (action == `AUTHENTICATE) begin
          if (pin == pin_db[i]) begin
            wasSuccessful = `true;
            accIndex = i;
          end
        end
      end
    end
  end

  always @(posedge deAuth or posedge reset) begin
    if (reset) begin
      failedAttempts <= 0; // Reset the failed attempts counter
    end else if (deAuth == `true) begin
      if (pin == pin_db[accIndex]) begin
        failedAttempts <= 0; // Reset the failed attempts counter on successful authentication
      end else begin
        failedAttempts <= failedAttempts + 1; // Increment the failed attempts counter
        if (failedAttempts == 3) begin
          exitOnThreeFailures <= `true; // Set the exit signal to true
        end
      end
    end
  end

endmodule

//

module ATM(
  input clk,
  input exit,
  input [11:0] accNumber,
  input [3:0] pin,
  input [11:0] destinationAcc,
  input [2:0] menuOption,
  input [10:0] amount,
  output reg error,
  output reg [10:0] balance
);

  // Initializing the balance database with an arbitrary amount of money
  reg [15:0] balance_database [0:9];
  initial begin
    $display("Welcome to the ATM");
   balance_database[0] = 16'd75128;
    balance_database[1] = 16'd56980;
    balance_database[2] = 16'd500;
    balance_database[3] = 16'd56234;
    balance_database[4] = 16'd25000;
    balance_database[5] = 16'd7890;
    balance_database[6] = 16'd7490;
    balance_database[7] = 16'd6900;
    balance_database[8] = 16'd67453;
    balance_database[9] = 16'd20000;
  end

  reg [3:0] present_state = `WAITING;
  reg otpRequired;

  wire [3:0] accIndex;
  wire [3:0] destinationAccIndex;
  wire isAuthenticated;
  wire wasFound;

  reg deAuth = `false;
  reg otpValidated = `false;
  reg [5:0] otp;

  authentication authAccNumberModule(accNumber, pin, `AUTHENTICATE, deAuth, isAuthenticated, accIndex);
  authentication findAccNumberModule(destinationAcc, 0, `FIND, deAuth, wasFound, destinationAccIndex);

  always @(posedge clk) begin
    // Restart the error
    error = `false;
    if (exit == `true) begin
      // Transition to the waiting state
      present_state = `WAITING;
      // Deauthenticate the current user
      deAuth = `true;
      #20;
    end

    if (present_state == `MENU) begin
      // Set the selected option as the current state
      if ((menuOption >= 0) & (menuOption <= 7)) begin
        present_state = menuOption;
      end else
        present_state = menuOption;
    end

    case (present_state)

      `WAITING: begin
        if (isAuthenticated == `true) begin
          present_state = `MENU;
          $display("Logged In.");
        end else if (isAuthenticated == `false) begin
          $display("Account number or password was incorrect");
          present_state = `WAITING;
        end
      end

      `BALANCE: begin
        balance = balance_database[accIndex];
        $display("Account %d has balance %d", accNumber, balance_database[accIndex]);
        present_state = `MENU;
      end

      `WITHDRAW: begin
        if (amount <= balance_database[accIndex]) begin
          if (amount > 10000) begin
            otpRequired = 1'b1;
            present_state = `OTP_WAITING;
            error = `false;
          end else begin
            balance_database[accIndex] = balance_database[accIndex] - amount;
            balance = balance_database[accIndex];
            present_state = `MENU;
            error = `false;
          end
        end else begin
          present_state = `MENU;
          error = `true;
        end
      end

      `OTP_WAITING: begin
        if (otpValidated) begin
          balance_database[accIndex] = balance_database[accIndex] - amount;
          balance = balance_database[accIndex];
          present_state = `MENU;
          error = `false;
        end
      end

      `WITHDRAW_SHOW_BALANCE: begin
        if (amount <= balance_database[accIndex]) begin
          balance_database[accIndex] = balance_database[accIndex] - amount;
          balance = balance_database[accIndex];
          present_state = `MENU;
          error = `false;
          $display("Account %d has balance %d after withdrawing %d", accNumber, balance_database[accIndex], amount);
        end else begin
          present_state = `MENU;
          error = `true;
        end
      end

      `TRANSACTION: begin
        if ((amount <= balance_database[accIndex]) & (wasFound == `true) & (balance_database[accIndex] + amount < 2048)) begin
          balance_database[destinationAccIndex] = balance_database[destinationAccIndex] + amount;
          balance_database[accIndex] = balance_database[accIndex] - amount;
          balance = balance_database[accIndex];
          present_state = `MENU;
          error = `false;
          $display("Destination account %d after transaction has a total balance of %d", destinationAcc, balance_database[destinationAccIndex]);
        end else begin
          present_state = `MENU;
          error = `true;
        end
      end

    endcase
  end

  always @(posedge clk) begin
    if (present_state == `OTP_WAITING) begin
      // OTP validation process
      if (otpRequired) begin
        // Simulated OTP validation, assuming OTP is correct if amount > 10000
        if (amount > 10000) begin
          otpValidated = 1'b1;
          $display("OTP validated.");
        end else begin
          otpValidated = 1'b0;
          $display("OTP invalid.");
        end
      end
    end
  end

endmodule
