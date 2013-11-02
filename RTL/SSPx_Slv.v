// ------------------------- CONFIDENTIAL ------------------------------------
//
//  Copyright 2008-2011 by Michael A. Morris, dba M. A. Morris & Associates
//
//  All rights reserved.  No part of this source code may be reproduced or
//  transmitted in any form or by any means, electronic or mechanical,
//  including photocopying, recording, or any information storage and
//  retrieval system, without permission in writing from Michael A. Morris, 
//  dba M. A. Morris & Associates.
//
//  Further, no use of this source code is permitted in any form or means
//  without a valid, written license agreement with Michael A. Morris, dba
//  M. A. Morris & Associates.
//
//  Michael A. Morris
//  dba M. A. Morris & Associates
//  164 Raleigh Way
//  Huntsville, AL 35811, USA
//  Ph.  +1 256 508 5869
//
// Licensed To:     DopplerTech, Inc. (DTI)
//                  9345 E. South Frontage Rd.
//                  Yuma, AZ 85365
//
// ----------------------------------------------------------------------------

`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates
// Engineer:        Michael A. Morris
//
// Create Date:     07:33 05/10/2008 
// Design Name:     LTAS 
// Module Name:     C:/XProjects/ISE10.1i/LTAS/LTAS_Top.v
// Project Name:    LTAS 
// Target Devices:  XC3S700AN-5FFG484I 
// Tool versions:   ISE 10.1i SP3 
//
// Description:
//
//  This module implements a full-duplex (Slave) SSP interface for 16-bit 
//  frames. In accordance to standard SPI practice, the module expects that
//  data is shifted into it MSB first. The first three bits are address bits,
//  the fourth bit is a command (WnR) bit which determines the operations to
//  be performed on the register, and the final twelve (12) bits are data bits.
//
// Dependencies:    None
//
// Revision History:
//
//  0.01    08E10   MAM     File Created
//
//  1.00    08E10   MAM     Initial Release
//
//  1.10    08G24   MAM     Modified the interface to operate with registered
//                          shift register data to eliminate transitions on
//                          MISO after risisng edge of SCK when input register
//                          written. Register RA[3:0] during fourth clock, and
//                          register DO[11:0] on falling edge of SCK after RA
//                          registered. This holds output data constant for the
//                          entire shift cycle.
//
//  1.11    11B01   MAM     Corrected #1 delay statement placement in register
//
//  2.00    11B06   MAM     Modified the interface to separate RA[3:1] and 
//                          RA[0] into RA[2:0] address port and a WnR command
//                          port. This makes the operation of the SSP/SPI I/F
//                          more clear.
//                          
//
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////

module SSPx_Slv(
    input   Rst,            // System Reset
//
    input   SSEL,           // Slave Select
    input   SCK,            // Shift Clock
    input   MOSI,           // Master Out, Slave In: Serial Data In
    output  reg MISO,       // Master In, Slave Out: Serial Data Out
//
    output  reg [2:0] RA,   // SSP Register Address output
    output  reg WnR,        // SSP Command: 1 - Write, 0 - Read
    output  En,             // SSP Enable - asserted during field
    output  reg EOC,        // SSP End of Cycle - asserted on last bit of frame
    output  reg [11:0] DI,  // Input shift register output
    input   [11:0] DO,      // Output shift register input
//
    output  reg [3:0] BC    // Bit Count, 0 - MSB; 15 - LSB
);

///////////////////////////////////////////////////////////////////////////////    
//
//  Local Declarations
//

    reg     [15:1] RDI; // Serial Input Shift Register
    reg     [11:0] rDO; // output data register
    
///////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

//  Module Reset - asynchronous because SCK not continuous

assign Rst_SSP = (Rst | ~SSEL);

//  Bit Counter, count from 0 to 15
//      Clock on negedge SCK to align MISO in bit cell

always @(negedge SCK or posedge Rst_SSP)
begin
    if(Rst_SSP)
        BC <= #1 4'd0;
    else
        BC <= #1 (BC + 1);
end

//  End-Of-Cycle, asserted during last bit of transfer (bit 15)
//      Clock on negedge SCK to center rising edge in bit cell

always @(negedge SCK or posedge Rst_SSP)
begin
    if(Rst_SSP)
        EOC <= #1 1'b0;
    else
        EOC <= #1 (BC == 14);
end

//  Generate SSP Enable, require four bits for internal addressing

assign En = BC[3] | BC[2];

//  Load MOSI into RDI using BC to select the active register
//      Use posedge SCK to sample in middle of bit cell

always @(posedge SCK or posedge Rst_SSP)
begin
    if(Rst_SSP)
        RDI <= #1 15'b0;
    else
        case(BC)
            4'b0000 :   RDI[15] <= #1 MOSI;
            4'b0001 :   RDI[14] <= #1 MOSI;
            4'b0010 :   RDI[13] <= #1 MOSI;
            4'b0011 :   RDI[12] <= #1 MOSI;
            4'b0100 :   RDI[11] <= #1 MOSI;
            4'b0101 :   RDI[10] <= #1 MOSI;
            4'b0110 :   RDI[ 9] <= #1 MOSI;
            4'b0111 :   RDI[ 8] <= #1 MOSI;
            4'b1000 :   RDI[ 7] <= #1 MOSI;
            4'b1001 :   RDI[ 6] <= #1 MOSI;
            4'b1010 :   RDI[ 5] <= #1 MOSI;
            4'b1011 :   RDI[ 4] <= #1 MOSI;
            4'b1100 :   RDI[ 3] <= #1 MOSI;
            4'b1101 :   RDI[ 2] <= #1 MOSI;
            4'b1110 :   RDI[ 1] <= #1 MOSI;
        endcase
end

//  Assign RA, WnR, and DI bus from RDI and MOSI

//always @(posedge SCK or posedge Rst)
//begin
//    if(Rst)
//        RA <= #1 0;
//    else if(BC == 2)
//        RA <= #1 {RDI[15:14], MOSI};
//end
//
//always @(posedge SCK or posedge Rst)
//begin
//    if(Rst)
//        WnR <= #1 0;
//    else if(BC == 3)
//        WnR <= #1 MOSI;
//end

always @(negedge SCK or posedge Rst)
begin
    if(Rst)
        RA <= #1 0;
    else if(BC == 2)
        RA <= #1 RDI[15:13];
end

always @(negedge SCK or posedge Rst)
begin
    if(Rst)
        WnR <= #1 0;
    else if(EOC)
        WnR <= #1 0;
    else if(BC == 3)
        WnR <= #1 RDI[12];
end

always @(posedge SCK or posedge Rst)
begin
    if(Rst)
        DI <= #1 0;
    else if(EOC)
        DI <= #1 {RDI[11:1], MOSI};
end

always @(negedge SCK or posedge Rst)
begin
    if(Rst)
        rDO <= #1 0;
    else if(BC == 3)
        rDO <= #1 DO;
end        

// Generate MISO: multiplex MOSI and DO using En and BC

always @(BC or rDO or MOSI)
begin
    case(BC)
        4'b0000 :   MISO <= MOSI;
        4'b0001 :   MISO <= MOSI;
        4'b0010 :   MISO <= MOSI;
        4'b0011 :   MISO <= MOSI;
        4'b0100 :   MISO <= rDO[11];
        4'b0101 :   MISO <= rDO[10];
        4'b0110 :   MISO <= rDO[ 9];
        4'b0111 :   MISO <= rDO[ 8];
        4'b1000 :   MISO <= rDO[ 7];
        4'b1001 :   MISO <= rDO[ 6];
        4'b1010 :   MISO <= rDO[ 5];
        4'b1011 :   MISO <= rDO[ 4];
        4'b1100 :   MISO <= rDO[ 3];
        4'b1101 :   MISO <= rDO[ 2];
        4'b1110 :   MISO <= rDO[ 1];
        4'b1111 :   MISO <= rDO[ 0];
    endcase
end

endmodule
