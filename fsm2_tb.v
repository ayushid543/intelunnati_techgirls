//Team Name: Tech Girls
//College Name: Parul Institute of Technology
//Problem Statement: Design and Implementation of Automated Teller Machine (FSM) Controller
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

module fsm2_tb();
  
  reg clk, exit;
  reg [11:0] accNumber;
  reg [3:0] pin;
  reg [11:0] destinationAccNumber;
  reg [2:0] menuOption;
  reg [10:0] amount;
  wire error;
  wire [10:0] balance;
  
  ATM atmModule(clk, exit, accNumber, pin, destinationAccNumber, menuOption, amount, error, balance);
  
  
  initial begin
    clk = 1'b0;
  end
  
   always @(error) begin
      if(error == `true)
        $display("Error!, action causes an invalid operation.");
   end
  
  initial begin
	

    //incorrect PIN
    accNumber = 12'd6754;
    pin = 4'b0100;
    
    #30

    //valid credentials
    accNumber = 12'd7896;
    pin = 4'b0110;
    
    #30
    
    //withdraw some money and then show the balance
    amount <= 10000;
	menuOption = `WITHDRAW_SHOW_BALANCE;
    clk = ~clk;
	 #5clk = ~clk;
    #30
	 
	 //withdraw some money and then show the balance
    amount = 10000;
	menuOption = `OTP_WAITING;
    clk = ~clk;
	 #5clk = ~clk;
    #30

    //show the balance
	menuOption = `BALANCE;
    clk = ~clk;
	 #5clk = ~clk;
    #30
    
    //withdraw too much money, resulting in an error
    amount <= 25000;
	menuOption = `EXIT;
    clk = ~clk;
	 #5clk = ~clk;
    #30

    //the balance wont change because an error happened during withdrawal
	menuOption = `BALANCE;
    clk = ~clk;
	 #5clk = ~clk;
    #30


    //transfer some money to the destination account with number 1234
    amount = 10000;
    destinationAccNumber = 1234;
	menuOption = `TRANSACTION;
    clk = ~clk;
	 #5clk = ~clk;
    #30

    //transfer too much money to the destination account with number 1234 which exceeds 10000 and cuases an error
    amount <= 10000;
    destinationAccNumber = 1234;
	menuOption = `TRANSACTION;
    clk = ~clk;
	 #5clk = ~clk;
    #30
    

    //exit the system
    exit = 1;
    #30
    exit = 0;
    #30
    
    //log in using the account with number 1234
    accNumber = 12'd1234;
    pin = 4'b0110;
    #30

    //you'll see that the balance is more than the default value because we had trasnsferred some money to this account a while ago
    menuOption = `BALANCE;
    clk = ~clk;
	 #5clk = ~clk;
    #30;
    
  end
  
endmodule
